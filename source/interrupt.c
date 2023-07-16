#include <stdint.h>
#include <stddef.h>
#include "interrupt.h"
#include "string.h"
#include "out.h"
// Interrupt descriptor table
#define NUM_IDT_ENTRIES 256
static uint64_t idt[NUM_IDT_ENTRIES];

static intr_handler_func* intr_handlers[NUM_IDT_ENTRIES];

// Defined in intr-stubs.S
#define NUM_ISR 48
typedef void intr_stub_func (void);
extern intr_stub_func* intr_stubs[NUM_ISR];
extern void intr_exit();

#define NUM_ISA_IRQ 16
#define IRQ_OFFSET 0x20
static irq_handler* irq_handlers[NUM_ISA_IRQ];

#define KERN_CODE_SEG 0x8

static inline void intr_disable() {
    asm("cli");
}

static inline void intr_enable() {
    asm("sti");
}

uint64_t make_gate(intr_stub_func* function, int dpl, int gate_type)
{
    uint32_t high = ((uint32_t)function&0xffff0000) 
    | (0x8000) | ((dpl&0x3)<<13) | ((gate_type&0xf)<<8);
    uint32_t low = ((uint32_t)function&0xffff) | ((KERN_CODE_SEG)<<16);
    return low | (uint64_t)high << 32;
}

uint64_t make_trap_gate(intr_stub_func* function, int dpl)
{
    return make_gate(function,dpl,0xf);
}

uint64_t make_interrupt_gate(intr_stub_func* function, int dpl)
{
    return make_gate(function,dpl,0xe);
}

void register_interrupt(int vec_num, intr_handler_func* func, int dpl, enum gate_type gate)
{
    if(gate==TRAP_GATE)
        idt[vec_num]=make_trap_gate(intr_stubs[vec_num],dpl);
    else
        idt[vec_num]=make_interrupt_gate(intr_stubs[vec_num],dpl);
    intr_handlers[vec_num]=func;
}

// start ------------ PIC IRQs ------------

#define PIC0_CTRL	0x20
#define PIC0_DATA	0x21
#define PIC1_CTRL	0xa0
#define PIC1_DATA	0xa1
#define PIC_EOI 0x20

static void pic_init()
{
  // Mask all interrupts on both PICs
  outb (PIC0_DATA, 0xff);
  outb (PIC1_DATA, 0xff);

  // Init master
  outb (PIC0_CTRL, 0x11); /* ICW1: single mode, edge triggered, expect ICW4. */
  outb (PIC0_DATA, 0x20); /* ICW2: line IR0...7 -> irq 0x20...0x27. */
  outb (PIC0_DATA, 0x04); /* ICW3: slave PIC on line IR2. */
  outb (PIC0_DATA, 0x01); /* ICW4: 8086 mode, normal EOI, non-buffered. */

  // Init slave
  outb (PIC1_CTRL, 0x11); /* ICW1: single mode, edge triggered, expect ICW4. */
  outb (PIC1_DATA, 0x28); /* ICW2: line IR0...7 -> irq 0x28...0x2f. */
  outb (PIC1_DATA, 0x02); /* ICW3: slave ID is 2. */
  outb (PIC1_DATA, 0x01); /* ICW4: 8086 mode, normal EOI, non-buffered. */

  // Unmask
  outb (PIC0_DATA, 0x00);
  outb (PIC1_DATA, 0x00);
}

void register_irq(int num, intr_handler_func* func, const char* name)
{
    intr_disable();
    irq_handlers[num]=func;
    intr_enable();
}

static void irq_handler_stub(struct intr_registers* reg)
{
    int irq_num = reg->vec_no-IRQ_OFFSET;
    ASSERT(irq_num>=0&&irq_num<NUM_ISA_IRQ);
    if(irq_handlers[irq_num]) {
        irq_handlers[irq_num](reg);
    }

    if(irq_num>=8)
        outb(PIC1_CTRL,PIC_EOI);
    outb(PIC0_CTRL,PIC_EOI);
}

static void irq_init()
{
    pic_init();
    memset(irq_handlers,0,sizeof(irq_handlers));
    for(int i=0;i<NUM_ISA_IRQ;i++) {
        register_interrupt(IRQ_OFFSET+i,irq_handler_stub,0, INTERRUPT_GATE);
    }
}

// end ------------ PIC IRQs ------------

static const char* exception_names[]=
{
    "#DE Divide Error",
    "#DB Debug Exception",
    "NMI Interrupt",
    "#BP Breakpoint Exception",
    "#OF Overflow Exception",
    "#BR BOUND Range Exceeded Exception",
    "#UD Invalid Opcode Exception",
    "#NM Device Not Available Exception",
    "#DF Double Fault Exception",
    "Coprocessor Segment Overrun",
    "#TS Invalid TSS Exception",
    "#NP Segment Not Present",
    "#SS Stack Fault Exception",
    "#GP General Protection Exception",
    "#PF Page-Fault Exception",
    "RESERVED",
    "#MF x87 FPU Floating-Point Error",
    "#AC Alignment Check Exception",
    "#MC Machine-Check Exception",
    "#XF SIMD Floating-Point Exception",
    "#VE Virtualization Exception",
    "#CP Control Protection Exception",
    "RESERVED",
    "RESERVED",
    "RESERVED",
    "RESERVED",
    "RESERVED",
    "RESERVED",
    "#HV Hypervisor Injection Exception",
    "#VC VMM Communication Exception",
    "#SX Security Exception",
    "RESERVED"
};

void simple_exception_handler(struct intr_registers* reg)
{
    ASSERT(reg->vec_no>=0&&reg->vec_no<32);
    error(exception_names[reg->vec_no]);
}

void exceptions_init()
{
    for(int i=0;i<32;i++) {
        register_interrupt(i,simple_exception_handler,0,TRAP_GATE);
    }
}

void interrupt_init()
{
    memset(idt,0,sizeof(idt));
    memset(intr_handlers,0,sizeof(intr_handlers));

    for(int i=0;i<NUM_ISR;i++) {
        idt[i]=make_interrupt_gate(intr_stubs[i],0);
    }
    uint64_t idt_descriptor=0;
    idt_descriptor |= (sizeof(idt) - 1);
    idt_descriptor |= (uint64_t)(idt) << 16;
    asm volatile ("lidt %0" : : "m" (idt_descriptor));

    irq_init();
    exceptions_init();

    asm volatile ("sti");

}
void interrupt_handler_common(struct intr_registers* reg)
{
    if(intr_handlers[reg->vec_no])
        intr_handlers[reg->vec_no](reg);
    else
        print_string("Unexpected interrupt\n");

    print_string("exception handled\n");
    print_hex32(reg->vec_no);
}