make
pwd
#to bypass issue with WSL and qemu
cp ./bin/osimage.bin /mnt/e/Users/charl/Downloads/
cd /mnt/e/Users/charl/Downloads/
qemu-system-i386.exe -s -S -drive format=raw,file=osimage.bin 