#ifndef _PORTS_H
#define _PORTS_H

#include <stdint.h>

static inline void outb(uint16_t port, uint8_t val) {
	asm("outb %0, %1" : : "a"(val), "Nd"(port) :"memory");
}

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm( "inb %1, %0": "=a"(ret): "Nd"(port): "memory");
    return ret;
}

#endif