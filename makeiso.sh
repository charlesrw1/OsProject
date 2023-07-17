#!/bin/bash     
#echo $(./tool/printBootIso.py ./bin/iso/myos.iso) > tempConcatBootFile.S
./tool/printBootIso.py ./bin/iso/myos.iso > file.txt
cat ./source/boot.S >> file.txt
#cat ./source/boot.S tempConcatBootFile.S

#nasm $flags $nasm_defines ./source/boot.S
#cd ./bin/iso && mkisofs -b kernel.elf -no-emul-boot -o myos.iso .
pwd