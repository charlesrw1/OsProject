#ifndef _INTERRUPT_H
#define _INTERRUPT_H
#include <stdint.h>
#include <stdbool.h>

struct intr_registers
{
    uint32_t edi;
    uint32_t esi;
    uint32_t ebp;
    uint32_t esp_dummy;
    uint32_t ebx;
    uint32_t edx;
    uint32_t ecx;
    uint32_t eax;
    uint16_t gs;
    uint16_t fs;
    uint16_t es;
    uint16_t ds;

    uint32_t vec_no;
    void* frame_pointer;
    uint32_t error_code;

    void (*eip)(void);
    uint32_t cs:16;
    uint32_t eflags;
};
enum gate_type
{
    TRAP_GATE,
    INTERRUPT_GATE  // clears interrupt flag
};

typedef void intr_handler_func(struct intr_registers*);
typedef intr_handler_func irq_handler;

// Called by interrupts in intr-stubs.S
void interrupt_handler_common(struct intr_registers* reg);
void register_irq(int num, irq_handler* func, const char* name);
void register_interrupt(int vec_num, intr_handler_func* func, int dpl, enum gate_type gate);
void interrupt_init();



#endif