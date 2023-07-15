#include "interrupt.h"
#include <stdint.h>
#include <stddef.h>
#include "string.h"
// Interrupt descriptor table
#define NUM_IDT_ENTRIES 256
static uint64_t idt[NUM_IDT_ENTRIES];

// Defined in intr-stubs.S
#define NUM_ISR 48
typedef void intr_stub_func (void);
extern intr_stub_func* intr_stubs[NUM_ISR];

void init_interrupt()
{
    memset(idt,0,sizeof(idt));
}