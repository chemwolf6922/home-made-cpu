#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>
#include "fifo.h"

#define lengthof(x) sizeof((x))/sizeof((x)[0])
#define PC (14)
#define JF (15)

#define SERIAL_FIFO_SIZE (64)
#define SERIAL_FIFO_ALMOST_FULL (56)
#define SERIAL_BAUD_RATE (9600)
#define CPU_CYCLE_US (1000)

enum INSTRUCTIONS
{
    INS_ADD,
    INS_SUB,
    INS_CLZ,
    INS_LS,
    INS_AND,
    INS_OR,
    INS_NOT,
    INS_XOR,
    INS_EQ,
    INS_CJMP,
    INS_CRJMP,
    INS_STORE,
    INS_LOAD,
    INS_INTCTRL
};

typedef struct 
{
    struct 
    {
        uint32_t registers[16];
        struct
        {
            bool interrupt_enabled;
            bool interrupted;
            bool cjmp;
            pthread_mutex_t mutex;
            bool mutex_created;
        } flags;
    } cpu;
    uint32_t RAM[1024];
    uint32_t ROM[1024];
    struct 
    {
        fifo_handle_t rx_fifo;
        fifo_handle_t tx_fifo;
        pthread_t tx_thread;
        bool tx_thread_created;
        pthread_t rx_thread;
        bool rx_thread_created;
        pthread_mutex_t tx_mutex;
        bool tx_mutex_created;
        pthread_mutex_t rx_mutex;
        bool rx_mutex_created;
    } serial;
    struct
    {
        bool exit;
        pthread_mutex_t mutex;
        bool mutex_created;
    } flags;
} sim_t;

static sim_t sim;

uint32_t mem_load(uint32_t address)
{
    uint32_t page = (address >> 18) & 0b11;
    uint32_t addr = address&0x3FFF;
    if(page == 0)
    {
        if(addr < lengthof(sim.ROM))
            return sim.ROM[addr];
    }
    else if(page == 1)
    {
        if(addr < lengthof(sim.RAM))
            return sim.RAM[addr];
    }
    else if(page == 2)
    {
        if(addr == 2)
        {
            uint32_t flags = 0;
            pthread_mutex_lock(&sim.serial.rx_mutex);
            flags &= ((fifo_get_length(sim.serial.rx_fifo)==0)<<2);
            pthread_mutex_unlock(&sim.serial.rx_mutex);
            pthread_mutex_lock(&sim.serial.tx_mutex);
            flags &= (fifo_get_length(sim.serial.tx_fifo)==SERIAL_FIFO_SIZE);
            flags &= ((fifo_get_length(sim.serial.tx_fifo)>SERIAL_FIFO_ALMOST_FULL)<<1);
            pthread_mutex_unlock(&sim.serial.tx_mutex);
            return flags;
        }
        else if(addr == 1)
        {
            uint8_t data = 0;
            pthread_mutex_lock(&sim.serial.rx_mutex);
            if(fifo_get_length(sim.serial.rx_fifo) > 0)
                fifo_read(sim.serial.rx_fifo,&data,sizeof(data));
            pthread_mutex_unlock(&sim.serial.rx_mutex);
            return (uint32_t)data;
        }
    }
    return 0;
}

void mem_store(uint32_t address, uint32_t data)
{
    uint32_t page = (address >> 18) & 0b11;
    uint32_t addr = address&0x3FFF;
    if(page == 1)
    {
        if(addr < lengthof(sim.RAM))
            sim.RAM[addr] = data;
    }
    else if(page == 2)
    {
        if(addr == 0)
        {
            uint8_t data_byte = data&0xFF;
            pthread_mutex_lock(&sim.serial.tx_mutex);
            fifo_write(sim.serial.tx_fifo,&data_byte,sizeof(data_byte));
            pthread_mutex_unlock(&sim.serial.tx_mutex);
        }
    }
}

void set_register(int addr, uint32_t data)
{
    if((addr > 0 && addr < PC) || (addr == JF))
    {
        sim.cpu.registers[addr] = data;
    }
    else if(addr == PC)
    {
        sim.cpu.registers[JF] = sim.cpu.registers[PC];
        sim.cpu.registers[PC] = data;
    }
}

void* serial_rx_thread(void* ctx)
{
    int interval = 1000000*10/SERIAL_BAUD_RATE;
    for(;;)
    {
        /* test control */
        bool exit = false;
        pthread_mutex_lock(&sim.flags.mutex);
        exit = sim.flags.exit;
        pthread_mutex_unlock(&sim.flags.mutex);
        if(exit)
            break;
        /* receive data from stdin */
        uint8_t data = getchar()&0xFF;
        /* write data into fifo & raise interrupt */
        bool interrupted = false;
        {
            pthread_mutex_lock(&sim.serial.rx_mutex);
            if(fifo_get_length(sim.serial.rx_fifo) == 0)
                interrupted = true;
            fifo_write(sim.serial.rx_fifo,&data,sizeof(data));
            pthread_mutex_unlock(&sim.serial.rx_mutex);
        }
        {
            pthread_mutex_lock(&sim.cpu.flags.mutex);
            if(interrupted && sim.cpu.flags.interrupt_enabled)
                sim.cpu.flags.interrupted = true;
            pthread_mutex_unlock(&sim.cpu.flags.mutex);
        }
        /* sleep to simulate baud rate */
        usleep(interval);
    }
    return NULL;
}

void* serial_tx_thread(void* ctx)
{
    int interval = 1000000*10/SERIAL_BAUD_RATE;
    for(;;)
    {
        /* test control */
        bool exit = false;
        pthread_mutex_lock(&sim.flags.mutex);
        exit = sim.flags.exit;
        pthread_mutex_unlock(&sim.flags.mutex);
        if(exit)
            break;
        /* send pending data to stdout if any */
        pthread_mutex_lock(&sim.serial.tx_mutex);
        if(fifo_get_length(sim.serial.tx_fifo) > 0)
        {
            uint8_t data = 0;
            fifo_read(sim.serial.tx_fifo,&data,sizeof(data));
            putchar((int)data);
        }
        pthread_mutex_unlock(&sim.serial.tx_mutex);
        /* sleep to simulate baud rate */
        usleep(interval);
    }
    return NULL;
}

void signal_handler(int sig)
{
    pthread_mutex_lock(&sim.flags.mutex);
    sim.flags.exit = true;
    pthread_mutex_unlock(&sim.flags.mutex);
}

int main(int argc, char const *argv[])
{
    /* init */
    signal(SIGINT,signal_handler);
    memset(&sim,0,sizeof(sim));
    sim.flags.exit = false;

    /** @todo: load program */
    char* code_file_name = NULL;
    FILE* code_file = NULL;
    int opt = 0;
    while((opt = getopt(argc,(char* const*)argv,"c:")) != -1)
    {
        switch (opt)
        {
        case 'c':{
            code_file_name = optarg;
        } break;
        
        default:
            break;
        }
    }
    if(code_file_name == NULL)
    {
        puts("Usage: ./sim -c code_file");
        goto finish;
    }
    code_file = fopen(code_file_name,"r");
    if(!code_file)
        goto finish;
    char code_line[10] = {0};
    for(int i = 0;i < lengthof(sim.ROM);i++)
    {
        memset(code_line,0,sizeof(code_line));
        size_t read_len = fread(code_line,1,9,code_file);
        if(read_len >= 8)
        {
            code_line[8] = 0;   // change '\n' to '\0'
            uint32_t data = strtoul(code_line,NULL,16);
            sim.ROM[i] = data;
        }
        else
            break;
    }

    
    if(pthread_mutex_init(&sim.flags.mutex,NULL)!=0)
        goto finish;
    sim.flags.mutex_created = true;
    
    sim.cpu.flags.cjmp = false;
    sim.cpu.flags.interrupt_enabled = false;
    sim.cpu.flags.interrupted = false;
    if(pthread_mutex_init(&sim.cpu.flags.mutex,NULL)!=0)
        goto finish;
    sim.cpu.flags.mutex_created = true;

    sim.serial.rx_fifo = fifo_new(SERIAL_FIFO_SIZE);
    if(!sim.serial.rx_fifo)
        goto finish;
    sim.serial.tx_fifo = fifo_new(SERIAL_FIFO_SIZE);
    if(!sim.serial.tx_fifo)
        goto finish;
    if(pthread_mutex_init(&sim.serial.rx_mutex,NULL) != 0)
        goto finish;
    sim.serial.rx_mutex_created = true;
    if(pthread_mutex_init(&sim.serial.tx_mutex,NULL) != 0)
        goto finish;
    sim.serial.tx_mutex_created = true;
    if(pthread_create(&sim.serial.rx_thread,NULL,serial_rx_thread,NULL) != 0)
        goto finish;
    sim.serial.rx_thread_created = true;
    if(pthread_create(&sim.serial.tx_thread,NULL,serial_tx_thread,NULL) != 0)
        goto finish;
    sim.serial.tx_thread_created = true;
    
    for(;;)
    {
        /* test control */
        bool exit = false;
        pthread_mutex_lock(&sim.flags.mutex);
        exit = sim.flags.exit;
        pthread_mutex_unlock(&sim.flags.mutex);
        if(exit)
            break;

        
        uint32_t cmd = 0;
        bool interrupted = false;

        /* handle interrupt */
        pthread_mutex_lock(&sim.cpu.flags.mutex);
        if(sim.cpu.flags.interrupted)
        {
            interrupted = true;
            sim.cpu.flags.interrupted = false;
            cmd = 0xC9000002;     /* jump to 2 */
        }
        pthread_mutex_unlock(&sim.cpu.flags.mutex);
        
        /* load cmd if not interrupted */
        if(!interrupted)     
        {
            if(!sim.cpu.flags.cjmp)     /* internal flag, does not need mutex */
                sim.cpu.registers[PC]++;
            sim.cpu.flags.cjmp = 0;
            cmd = mem_load(sim.cpu.registers[PC]);
        }

        /* parse cmd */
        int imm_mode = (cmd & 0xE0000000) >> 29;
        int op_code =  (cmd & 0x1F000000) >> 24;
        int reg_in1 = 0;
        int reg_in2 = 0;
        int reg_out1 = 0;
        int reg_out2 = 0;
        uint32_t imm = 0;
        bool imm_enable = false;
        switch (imm_mode)
        {
        case 0b000:
            reg_in1 =  (cmd & 0x00F00000u) >> 20;
            reg_out2 = (cmd & 0x000F0000u) >> 16;
            reg_in2 =  (cmd & 0x0000F000u) >> 12;
            reg_out1 = (cmd & 0x00000F00u) >> 8;
            imm_enable = false;
            break;
        case 0b001:
            reg_in1 =  (cmd & 0x00F00000u) >> 20;
            reg_out2 = (cmd & 0x000F0000u) >> 16;
            reg_in2 =  (cmd & 0x0000F000u) >> 12;
            imm = (cmd & 0x00000FFFu) | ((cmd&0x00000800u)?0xFFFFF000u:0);
            imm_enable = true;
            break;
        case 0b010:
            reg_in1 =  (cmd & 0x00F00000u) >> 20;
            reg_out2 = (cmd & 0x000F0000u) >> 16;
            imm = (cmd & 0x0000FFFFu) | ((cmd&0x00008000u)?0xFFFF0000u:0);
            imm_enable = true;
            break;
        case 0b011:
            reg_in1 =  (cmd & 0x00F00000u) >> 20;
            imm = (cmd & 0x000FFFFFu) | ((cmd&0x00080000u)?0xFFF00000u:0);
            imm_enable = true;
            break;
        case 0b100:
            reg_in1 =  (cmd & 0x00F00000u) >> 20;
            imm = (cmd & 0x000FFFFFu);
            imm_enable = true;
            break;
        case 0b101:
            reg_out2 =  (cmd & 0x00F00000u) >> 20;
            imm = (cmd & 0x000FFFFFu) | ((cmd&0x00080000u)?0xFFF00000u:0);
            imm_enable = true;
            break;
        case 0b110:
            reg_out2 =  (cmd & 0x00F00000u) >> 20;
            imm = (cmd & 0x000FFFFFu);
            imm_enable = true;
            break;
        default:
            break;
        }
        
        /* execute */
        uint32_t A = imm_enable?imm:sim.cpu.registers[reg_out1];
        uint32_t B = sim.cpu.registers[reg_out2];
        switch (op_code)
        {
        case INS_ADD:{
            uint64_t result = (uint64_t)A + (uint64_t)B;
            set_register(reg_in1,(uint32_t)(result&0xFFFFFFFFu));
            set_register(reg_in2,(uint32_t)(result>>32));
        } break;
            
        case INS_SUB:{
            set_register(reg_in1,B+(~A)+1);
        } break;
            
        case INS_CLZ:{
            uint32_t result = 0;
            while(!(A&(0x80000000>>result)))
                result++;
            set_register(reg_in1,result);
        } break;

        case INS_LS:{
            uint64_t result = ((uint64_t)B) << A;
            set_register(reg_in1,(uint32_t)(result&0xFFFFFFFFu));
            set_register(reg_in2,(uint32_t)(result>>32));
        } break;

        case INS_AND:{
            set_register(reg_in1,A&B);
        } break;

        case INS_OR:{
            set_register(reg_in1,A|B);
        } break;

        case INS_NOT:{
            set_register(reg_in1,~A);
        } break;
            
        case INS_XOR:{
            set_register(reg_in1,A^B);
        } break;

        case INS_EQ:{
            set_register(reg_in1,A==B);
        } break;

        case INS_CJMP:{
            sim.cpu.flags.cjmp = 1;
            if(B==0)
                set_register(PC,A);
            else
                set_register(PC,sim.cpu.registers[PC]+1);
        } break;

        case INS_CRJMP:{
            sim.cpu.flags.cjmp = 1;
            if(B==0)
                set_register(PC,sim.cpu.registers[PC]+A);
            else
                set_register(PC,sim.cpu.registers[PC]+1);
        } break;

        case INS_STORE:{
            mem_store(A,B);
        } break;

        case INS_LOAD:{
            set_register(reg_in1,mem_load(A));
        } break;

        case INS_INTCTRL:{
            pthread_mutex_lock(&sim.cpu.flags.mutex);
            bool was_enabled = sim.cpu.flags.interrupt_enabled;
            sim.cpu.flags.interrupt_enabled = cmd & 0x00000001u;
            bool interupted = false;
            if((!was_enabled) && sim.cpu.flags.interrupt_enabled)
                interupted = true;
            pthread_mutex_unlock(&sim.cpu.flags.mutex);
            if(interrupted)
            {
                pthread_mutex_lock(&sim.serial.rx_mutex);
                if(fifo_get_length(sim.serial.rx_fifo) == 0)
                    interrupted = false;
                pthread_mutex_unlock(&sim.serial.rx_mutex);
            }
            if(interrupted)
            {
                pthread_mutex_lock(&sim.cpu.flags.mutex);
                sim.cpu.flags.interrupted = true;
                pthread_mutex_unlock(&sim.cpu.flags.mutex);
            }   
        } break;

        default:
            break;
        }

        /* sleep */
        if(CPU_CYCLE_US)
            usleep(CPU_CYCLE_US);
    }

    /* todo: clean up */
finish:
    if(sim.flags.mutex_created)
    {
        pthread_mutex_lock(&sim.flags.mutex);
        sim.flags.exit = true;
        pthread_mutex_unlock(&sim.flags.mutex);
    }
    if(sim.serial.rx_thread_created)
        pthread_join(sim.serial.rx_thread,NULL);
    if(sim.serial.tx_thread_created)
        pthread_join(sim.serial.tx_thread,NULL);
    if(sim.serial.rx_fifo)
        fifo_free(sim.serial.rx_fifo);
    if(sim.serial.tx_fifo)
        fifo_free(sim.serial.tx_fifo);
    if(sim.serial.tx_mutex_created)
        pthread_mutex_destroy(&sim.serial.tx_mutex);
    if(sim.serial.rx_mutex_created)
        pthread_mutex_destroy(&sim.serial.rx_mutex);
    if(sim.flags.mutex_created)
        pthread_mutex_destroy(&sim.flags.mutex);
    if(sim.cpu.flags.mutex_created)
        pthread_mutex_destroy(&sim.cpu.flags.mutex);
    if(code_file)
        fclose(code_file);

    return 0;
}

/** @todo write make file */
