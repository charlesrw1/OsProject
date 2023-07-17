CC=i386-elf-gcc
LD=i386-elf-ld
CFLAGS=-ffreestanding -g -MMD -MP
NASMFLAGS= -g -f elf

SRC_DIR = ./source
BUILD_DIR = ./bin

BOOT_SRC = ./source/boot.S ./source/start.S
BOOT_BIN = ./bin/boot.bin
KERNEL_SRC = $(wildcard $(SRC_DIR)/*.c) $(filter-out $(BOOT_SRC), $(wildcard $(SRC_DIR)/*.S))
KERNEL_OBJS = $(KERNEL_SRC:$(SRC_DIR)/%=$(BUILD_DIR)/%.o) # source/myfile.c -> bin/myfile.c.o

KERNEL_EXE = ./bin/kernel.elf
KERNEL_DBG_SYMBOLS = ./bin/kernel.sym
KERNEL_BIN = ./bin/kernel.bin
OSIMAGE = ./bin/osimage.bin

BOOTLOADER_LINKER = ./bootloader/link.ld

all: prep $(KERNEL_BIN) $(KERNEL_DBG_SYMBOLS)

prep:
	@mkdir -p $(BUILD_DIR)

# C source files
$(BUILD_DIR)/%.c.o : $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -o $@ -c $<

# Asm source files
$(BUILD_DIR)/%.S.o : $(SRC_DIR)/%.S
	nasm $(NASMFLAGS) -o $@ $<

$(KERNEL_EXE): $(KERNEL_OBJS)
	$(LD) -o $@  $(KERNEL_OBJS) -T $(BOOTLOADER_LINKER)

$(KERNEL_BIN): $(KERNEL_EXE)
	objcopy -O binary $< $@

$(BOOT_BIN): $(BOOT_SRC)
	nasm -f bin -o $@ $<

$(OSIMAGE): $(KERNEL_BIN) $(BOOT_BIN)
	dd if=/dev/zero of=osimg.bin bs=512 count=32
	dd if=./bin/boot.bin of=osimg.bin conv=notrunc
	dd if=./bin/kernel.bin of=osimg.bin conv=notrunc bs=512 seek=1
	mv ./osimg.bin ./bin/osimage.bin

$(KERNEL_DBG_SYMBOLS): $(KERNEL_EXE)
	objcopy --only-keep-debug $< $@

clean:
	rm -f $(KERNEL_OBJS)
	rm -f $(KERNEL_DBG_SYMBOLS)
	rm -f $(KERNEL_OBJS:%.o=%.d)
	rm $(KERNEL_EXE)
	rm $(KERNEL_BIN)
	rm $(BOOT_BIN)


-include $(KERNEL_OBJS:%.o=%.d)