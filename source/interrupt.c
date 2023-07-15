#include "interrupt.h"
#include <stdint.h>
#include <stddef.h>
#include "string.h"
#include "out.h"
// Interrupt descriptor table
#define NUM_IDT_ENTRIES 256
static uint64_t idt[NUM_IDT_ENTRIES];

// Defined in intr-stubs.S
#define NUM_ISR 48
typedef void intr_stub_func (void);
extern intr_stub_func* intr_stubs[NUM_ISR];
extern void intr_exit();

void init_interrupt()
{
    memset(idt,0,sizeof(idt));

    print_string("intr stubs:\n");
    print_hex32(intr_stubs[0]);
    print_hex32(intr_stubs[1]);
    print_hex32(intr_stubs[2]);
    print_hex32(intr_exit);
    print_hex32(init_interrupt);
    print_hex32(intr_handler);
    print_hex32(idt);
}

void intr_handler()
{

}