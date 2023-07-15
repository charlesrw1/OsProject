CC=i386-elf-gcc
LD=i386-elf-ld
CFLAGS=-ffreestanding

BOOTSRC = ./source/boot.S
KERNEL_CSRC = $(wildcard ./source/*.c)
KERNEL_SSRC = $(filter-out $(BOOTSRC) ./source/intr-stubs.S, $(wildcard ./source/*.S))
KERNEL_COBJ = $(KERNEL_CSRC:.c=.o)
KERNEL_SOBJ = $(KERNEL_SSRC:.S=.o)
KERNEL_OBJ = $(KERNEL_COBJ) $(KERNEL_SOBJ)

all: osimg

$(KERNEL_COBJ): %.o : %.c
	 $(CC) -o $@ -c $< $(CFLAGS)

$(KERNEL_SOBJ): %.o : %.S
	nasm -f elf -o $@ $<

kernel: $(KERNEL_OBJ)
	$(LD) -o ./bin/kernel.bin  $(KERNEL_OBJ) -T source/link.ld

bootloader:
	nasm -f bin -o ./bin/boot.bin $(BOOTSRC)

osimg: bootloader kernel
	dd if=/dev/zero of=osimg.bin bs=512 count=32
	dd if=./bin/boot.bin of=osimg.bin conv=notrunc
	dd if=./bin/kernel.bin of=osimg.bin conv=notrunc bs=512 seek=1
	mv ./osimg.bin ./bin/osimage.bin
	trash $(KERNEL_OBJ)

