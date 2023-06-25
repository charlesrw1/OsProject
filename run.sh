#to bypass issue with WSL and qemu
cp boot.bin /mnt/e/Users/charl/Downloads/
cd /mnt/e/Users/charl/Downloads/
#qemu-system-i386.exe -s -S boot.bin
qemu-system-i386.exe -drive format=raw,file=boot.bin
