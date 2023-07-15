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

static void copy_bytes_backwards(void* dest, const void* src, size_t count)
{
	uint8_t* ptrd=dest;
	const uint8_t* ptrs=src; 
	for(size_t i = count;i>0;i--)
	{
		ptrd[i-1]=ptrs[i-1];
	}
}

void* memmove(void* dest, const void* src, size_t count)
{
	unsigned int desti = (unsigned int)dest;
	unsigned int srci = (unsigned int)src;
	if(desti-srci>=count)	// unsigned compare
	{
		memcpy(dest,src,count);
	}
	else
	{
		copy_bytes_backwards(dest,src,count);
	}
	return dest;
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
