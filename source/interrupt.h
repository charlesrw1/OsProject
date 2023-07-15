#ifndef _INTERRUPT_H
#define _INTERRUPT_H

void init_interrupt();

// Called by interrupts in intr-stubs.S
void intr_handler();


#endif