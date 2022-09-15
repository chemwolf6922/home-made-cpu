#include "fifo.h"
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

typedef struct
{
    uint8_t* data;
    int size;
    int head;
    int tail;
    int length;
} fifo_t;

fifo_handle_t fifo_new(int size)
{
    fifo_t* fifo = NULL;

    fifo = malloc(sizeof(fifo_t));
    if(!fifo)
        goto error;
    memset(fifo,0,sizeof(fifo_t));

    fifo->data = malloc(size);
    if(!fifo->data)
        goto error;
    memset(fifo->data,0,size);

    fifo->size = size;
    fifo->head = 0;
    fifo->tail = 0;

    return (fifo_handle_t)fifo;
error:
    fifo_free((fifo_handle_t)fifo);
    return NULL;
}

void fifo_free(fifo_handle_t handle)
{
    fifo_t* fifo = (fifo_t*)handle;
    if(fifo)
    {
        if(fifo->data)
            free(fifo->data);
        free(fifo);
    }
}

int fifo_get_length(fifo_handle_t handle)
{
    fifo_t* fifo = (fifo_t*)handle;
    return fifo->length;
}

int fifo_read(fifo_handle_t handle, uint8_t* dst, int dst_len)
{
    fifo_t* fifo = (fifo_t*)handle;
    int read_len = 0;
    for(read_len=0;read_len<dst_len;read_len++)
    {
        if(fifo->length == 0)
            break;
        *dst = fifo->data[fifo->head];
        dst++;
        fifo->head++;
        if(fifo->head == fifo->size)
            fifo->head = 0;
        fifo->length--;
    }
    return read_len;
}

int fifo_write(fifo_handle_t handle, uint8_t* src, int src_len)
{
    fifo_t* fifo = (fifo_t*)handle;
    int write_len = 0;
    for(write_len=0;write_len<src_len;write_len++)
    {
        if(fifo->length == fifo->size)
            break;
        fifo->data[fifo->tail] = *src;
        src++;
        fifo->tail++;
        if(fifo->tail == fifo->size)
            fifo->tail = 0;
        fifo->length++;
    }
    return write_len;
}

/* test */

// #include <stdio.h>

// int main(int argc, char const *argv[])
// {
//     char data[] = "1234567890";
//     char buffer[10] = {0};
//     fifo_handle_t fifo = fifo_new(10);

//     fifo_write(fifo,data,8);
//     printf("len: %d\n",fifo_get_length(fifo));
//     fifo_write(fifo,data,5);
//     printf("len: %d\n",fifo_get_length(fifo));
//     fifo_read(fifo,buffer,6);
//     printf("%.*s\n",6,buffer);
//     printf("len: %d\n",fifo_get_length(fifo));
//     fifo_write(fifo,data,10);
//     printf("len: %d\n",fifo_get_length(fifo));
//     fifo_read(fifo,buffer,10);
//     printf("%.*s\n",10,buffer);
//     printf("len: %d\n",fifo_get_length(fifo));

//     fifo_free(fifo);
//     return 0;
// }


