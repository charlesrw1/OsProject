CC=i386-elf-gcc
LD=i386-elf-ld
CFLAGS=

KERNELSRC = $(wildcard ./source/*.c)
KERNELOBJ = $(KERNELSRC:.c=.o)

BOOTSRC = source/boot.S

%.o: %.c
	 $(CC) -o $@ -c $< $(CFLAGS)

kernel: $(KERNELOBJ)
	$(LD) -o ./bin/kernel.bin $^ -T source/link.ld

bootloader:
	nasm -f bin -o ./bin/boot.bin $(BOOTSRC)

osimg: bootloader kernel
	cat ./bin/boot.bin ./bin/kernel.bin > ./bin/osimage.bin
clean:
	rm ./*.o
