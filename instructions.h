#ifndef _INSTRUCTIONS_H__
#define _INSTRUCTIONS_H__

#include <stdint.h>

#define ADD(a,b,c,d) {uint64_t temp89sjqi=(uint64_t)a+(uint64_t)b;c=temp89sjqi&0xFFFFFFFF;d=temp89sjqi>>32;}
#define SUB(a,b,c) {c=(uint32_t)a+(uint32_t)(~b)+1;}
#define CLZ(a,b) {b=0;while(!(a&(0x80000000>>b))){b++;}}
#define LSHIFT(a,b,c,d) {uint64_t temp89sjqi=(uint64_t)b<<a;c=temp89sjqi&0xFFFFFFFF;d=temp89sjqi>>32;}
#define AND(a,b,c) {c=a&b;}
#define OR(a,b,c) {c=a|b;}
#define NOT(a,b) {b=~a;}
#define XOR(a,b,c) {c=a^b;}
#define EQ(a,b,c) {c=a==b;}
#define CJMP(a,label) if(a==0){goto label;}
#define LOAD(mem,a,b) {a=mem[b];}
#define STORE(mem,a,b) {mem[b]=a;}


#endif
