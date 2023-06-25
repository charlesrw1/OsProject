nasm -f elf32 -o linuxRun.o -g -F dwarf linuxRun.S
gcc -m32 -o linuxRun linuxRun.o
./linuxRun 
