#include <stdio.h>
#include "instructions.h"


int mul(const int a, const int b)
{
    uint32_t reg0_write;
    uint32_t reg[13];
    reg[0] = 0;

    reg[1] = a;
    reg[2] = b;

    ADD(reg[0],reg[0],reg[4],reg[7]);
label0:
    AND(1,reg[2],reg[3]);
    CJMP(reg[3],label1);
    ADD(reg[1],reg[4],reg[4],reg[5]);
    ADD(reg[5],reg[6],reg[6],reg0_write);
    ADD(reg[6],reg[7],reg[6],reg0_write);   
label1:
    LSHIFT(1,reg[1],reg[1],reg[7]);
    LSHIFT(31,reg[2],reg0_write,reg[2]);
    CJMP(reg[2],end);
    CJMP(reg[0],label0);
end:
    return (int)reg[4];
}

int div(const int a, const int b)
{
    uint32_t reg0_write;
    uint32_t reg[13];
    reg[0] = 0;

    reg[1] = a;
    reg[2] = b;

    AND(reg[0],reg[0],reg[3]);
    CJMP(reg[2],end);
    LSHIFT(1,reg[1],reg0_write,reg[4]);
    CJMP(reg[4],label0);
    SUB(reg[0],reg[1],reg[1]);
label0:
    LSHIFT(1,reg[2],reg0_write,reg[5]);
    CJMP(reg[5],label1);
    SUB(reg[0],reg[2],reg[2]);
label1:
    XOR(reg[4],reg[5],reg[4]);

    CLZ(reg[1],reg[5]);
    CLZ(reg[2],reg[6]);
    SUB(reg[6],reg[5],reg[7]);
    LSHIFT(1,reg[7],reg0_write,reg[5]);
    CJMP(reg[5],label2);
    CJMP(reg[0],end);
label2:
    LSHIFT(reg[7],reg[2],reg[2],reg0_write);
    ADD(1,reg[7],reg[7],reg0_write);
label3:
    CJMP(reg[7],label4);
    SUB(reg[7],1,reg[7]);
    SUB(reg[1],reg[2],reg[5]);
    LSHIFT(1,reg[5],reg0_write,reg[6]);
    LSHIFT(31,reg[2],reg0_write,reg[2]);
    SUB(reg[6],1,reg[6]);
    CJMP(reg[6],label3);
    OR(1,reg[0],reg[6]);
    LSHIFT(reg[7],reg[6],reg[6],reg0_write);
    OR(reg[3],reg[6],reg[3]);
    ADD(reg[0],reg[5],reg[1],reg0_write);
    CJMP(reg[0],label3);
label4:
    CJMP(reg[4],end);
    SUB(reg[0],reg[3],reg[3]);
end:
    return (int)reg[3];
}

int main(int argc, char const *argv[])
{
    int result = div(-10000,20000);
    printf("%d\n",result);
    return 0;
}

