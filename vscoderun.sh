make

rm ./bin/iso/myos.iso
cp ./bin/kernel.bin ./bin/iso
cd ./bin/iso && mkisofs -b kernel.bin -no-emul-boot -o myos.iso .
cd ./../../
./tool/printBootIso.py ./bin/iso/myos.iso > bootTemp.S
cat ./bootloader/boot1.S >> bootTemp.S
nasm -f bin -o ./bin/boot1.bin bootTemp.S
rm bootTemp.S
dd if=./bin/boot1.bin of=./bin/iso/myos.iso conv=notrunc

#to bypass issue with WSL and qemu
cp ./bin/iso/myos.iso /mnt/e/Users/charl/Downloads/
cd /mnt/e/Users/charl/Downloads/
qemu-system-i386.exe -s -S -drive format=raw,file=myos.iso