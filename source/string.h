#ifndef _STRING_H
#define _STRING_H

#include <stdint.h>
#include <stddef.h>

size_t strlen(const char* str);
void* memcpy(void* dest,const void* src, size_t count);
void* memmove(void* dest, const void* src, size_t count);
void* memset(void* ptr, int value, size_t num);
int memcmp(const void* p1, const void* p2, size_t num);
const char* strsplit(const char* input, char delim, char* buffer);

#endif