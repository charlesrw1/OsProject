#!/usr/bin/python3
import sys
import struct


if len(sys.argv) <= 1:
    print("need iso path")
    exit(-1)

iso_name : str = sys.argv[1]


with open(iso_name, "rb") as file:
    boot_record_ofs = 0x800*0x11
    file.seek(boot_record_ofs)
    num: int = struct.unpack_from("<B",file.read(1))[0]
    magic: str = file.read(5).decode()
    if magic!="CD001" or num !=0:
        print("missing el torito iso")
        exit(-1)
    
    boot_record_catalog_ofs = boot_record_ofs+71
    file.seek(boot_record_catalog_ofs)
    boot_catalog_ofs : int = struct.unpack_from("<i",file.read(4))[0]
    boot_catalog_ofs*=0x800

    boot_catalog_boot_entry = boot_catalog_ofs+0x20
    file.seek(boot_catalog_boot_entry)
    if struct.unpack_from("<B",file.read(1))[0] != 0x88:
        print("not bootable entry")
        exit(-1)

    file.seek(boot_catalog_boot_entry+0x6)
    num_sectors = struct.unpack("<H", file.read(2))[0]
    file.seek(boot_catalog_boot_entry+0x8)
    load_rba = struct.unpack("<I",file.read(4))[0]

    # Sectors on a CD-ROM should be 2kb
    # Both values are in total bytes, need to be converted to sectors in bootloader
    print("%define BOOT_LOAD_SIZE 0x" + format(num_sectors*0x200,"x") + "\n"
          + "%define BOOT_LOAD_ADDR 0x" + format(load_rba*0x800,"x") +"\n")

    

    