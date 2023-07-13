#ifndef _STRING_H
#define _STRING_H

#include <stdint.h>
#include <stddef.h>

size_t strlen(const char* str);
void* memcpy(void* dest,const void* src, size_t count);
void* memmove(void* dest, const void* src, size_t count);

#endif