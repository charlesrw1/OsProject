#ifndef _OUT_H
#define _OUT_H
#include <stdint.h>

#define ASSERT(CONDITION)\
    do { if(!(CONDITION))\
    error(#CONDITION); }while(0);                                                 


int printf(const char* restrict format, ...);
void print_hex32(uint32_t num);
void print_string(const char* str);
void error(const char* error_str);

static inline void outb(uint16_t port, uint8_t val)
{
	asm("outb %0, %1" : : "a"(val), "Nd"(port) :"memory");
}

static inline uint8_t inb(uint16_t port)
{
    uint8_t ret;
    asm( "inb %1, %0": "=a"(ret): "Nd"(port): "memory");
    return ret;
}

#endif