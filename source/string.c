#include "string.h"

size_t strlen(const char* str)
{
	unsigned i=0;
	while(str[i])
		i++;
	return i;
}
void* memcpy(void* dest,const void* src, size_t count)
{
	uint8_t* ptrd=dest;
	const uint8_t* ptrs=src; 
	while(count--) {
		*ptrd = *ptrs;
		++ptrd;
		++ptrs;
	}
	return dest;
}

void* memmove(void* dstptr, const void* srcptr, size_t size)
{
	unsigned char* dst = (unsigned char*) dstptr;
	const unsigned char* src = (const unsigned char*) srcptr;
	if (dst < src) {
		for (size_t i = 0; i < size; i++)
			dst[i] = src[i];
	} else {
		for (size_t i = size; i != 0; i--)
			dst[i-1] = src[i-1];
	}
	return dstptr;
}
void* memset(void* ptr, int value, size_t num)
{
    uint8_t* ptrc = ptr;
    while(num--) {
        *ptrc=value;
        ptrc++;
    }
    return ptr;
}
