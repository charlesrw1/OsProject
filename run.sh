make
#to bypass issue with WSL and qemu
cp ./bin/osimage.bin /mnt/e/Users/charl/Downloads/
cd /mnt/e/Users/charl/Downloads/
if [[ $1 == debug ]]; then
    qemu-system-i386.exe -s -S -drive format=raw,file=osimage.bin &    \
    cd ~/source/OsProj/ && \
    gdb  -ex "target remote 192.168.4.166:1234" -ex "br *0x7c00" -ex "c" \
    -ex "symbol-file ./bin/kernel.sym" -ex "br kmain"

else
    qemu-system-i386.exe -drive format=raw,file=osimage.bin
fi
