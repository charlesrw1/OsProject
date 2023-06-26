CC=i386-elf-gcc
LD=i386-elf-ld
CFLAGS=

KERNELSRC = $(wildcard ./source/*.c)
KERNELOBJ = $(KERNELSRC:.c=.o)
KERNELSTART = kernel_start.o

BOOTSRC = source/boot.S

all: osimg

%.o: %.c
	 $(CC) -o $@ -c $< $(CFLAGS)

kernel_start.o: source/kernel_start.S
	nasm -f elf -o kernel_start.o source/kernel_start.S 

# kernal_start.o included in linker script
kernel: $(KERNELOBJ) $(KERNELSTART)
	$(LD) -o ./bin/kernel.bin $(KERNELOBJ) -T source/link.ld


bootloader:
	nasm -f bin -o ./bin/boot.bin $(BOOTSRC)

osimg: bootloader kernel
	cat ./bin/boot.bin ./bin/kernel.bin > ./bin/osimage.bin

clean:
	rm -f $(KERNELOBJ)
