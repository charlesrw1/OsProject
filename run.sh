#to bypass issue with WSL and qemu
make osimg
cp ./bin/osimage.bin /mnt/e/Users/charl/Downloads/
cd /mnt/e/Users/charl/Downloads/
if [[ $1 == debug ]]; then
    qemu-system-i386.exe -s -S -drive format=raw,file=osimage.bin
else
    qemu-system-i386.exe -drive format=raw,file=osimage.bin
fi
