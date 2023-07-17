ENTRY(_start)
SECTIONS
{
    . = 0x7C00;

    .text BLOCK(1) : ALIGN(1)
    {
        *(.text.prologue)
        *(.text)
    }

    .rodata BLOCK(1) : ALIGN(1)
    {
        *(.rodata)
    }

    .data BLOCK(1) : ALIGN(1)
    {
        *(.data)
    }

    .bss BLOCK(1) : ALIGN(1)
    {
        *(.bss)
    }

    end = .;
}
