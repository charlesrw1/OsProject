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


#endif