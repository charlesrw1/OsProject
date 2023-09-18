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

int memcmp(const void* p1, const void* p2, size_t num)
{
	const uint8_t* ptr1 = p1;
	const uint8_t* ptr2 = p2;
	while(num>0) {
		if(*ptr1 != *ptr2)
			return (*ptr1 > *ptr2) ? 1 : -1;
		ptr1++;
		ptr2++;
		num--;
	}
	return 0;
}

const char* strsplit(const char* input, char delim, char* buffer)
{
	while(*input && *input != delim)
	{
		*buffer = *input;
		++buffer;
		++input;
	}
	*buffer = 0;
	if(*input == 0)
		return NULL;
	if(*input == '/')
		return input+1;
	return NULL;
}