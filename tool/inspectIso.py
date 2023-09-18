#!/usr/bin/python3
import sys
import struct


iso_name : str = "./bin/iso/myos.iso"


def read_directory(file, lba_loc):
    save = file.tell()
    file.seek(lba_loc*0x800)
    table : bytes = file.read(0x800)
    i : int = 0
    current_num = 0
    print("name".ljust(16) + "lba_loc".ljust(10) + "data_len".ljust(10) + "flags".ljust(3))
    while True:
        record_len = struct.unpack_from("<b",table,i)[0]
        if record_len == 0:
            break
        lba_extent_loc = struct.unpack_from("<I", table, i+2)[0]
        data_len = struct.unpack_from("<I", table, i+10)[0]
        flags = struct.unpack_from("<b",table,i+25)[0]
        file_id_len = struct.unpack_from("<b",table,i+32)[0]
        file_str : str
        if current_num == 0:
            file_str = "."
        elif current_num == 1:
            file_str = ".."
        else:
            file_str = table[i+33:i+33+file_id_len].decode()
        print(file_str.ljust(16) +str(lba_extent_loc).ljust(10) 
              + str(data_len).ljust(10) + str(flags).ljust(3) )
        
        i+=record_len
        current_num+=1

            




with open(iso_name, "rb") as file:
    boot_record_ofs = 0x800*0x10
    file.seek(boot_record_ofs)
    num: int = struct.unpack_from("<B",file.read(1))[0]
    magic: str = file.read(5).decode()
    if magic!="CD001" or num !=1:
        print("missing el torito iso")
        exit(-1)
    
    file.seek(boot_record_ofs)
    pvd : bytes = file.read(0x800)
    num : int = struct.unpack_from("<I",pvd,132)[0]
    num2 : int = struct.unpack_from(">I",pvd,132+4)[0]
    table_loc : int = struct.unpack_from("<I",pvd,140)[0]

    file.seek(boot_record_ofs+156)
    root_dir : bytes = file.read(34)
    i = 0
    record_len = struct.unpack_from("<b",root_dir,i)[0]
    lba_extent_loc = struct.unpack_from("<I", root_dir, i+2)[0]
    data_len = struct.unpack_from("<I", root_dir, i+10)[0]
    flags = struct.unpack_from("<b",root_dir,i+25)[0]
    file_id_len = struct.unpack_from("<b",root_dir,i+32)[0]

    print(num2)
    print(num)
    print(table_loc)

    file.seek(table_loc*0x800)
    pathtable : bytes = file.read(num)

    i = 0
    while i < num:
        id_len = struct.unpack_from("<b",pathtable,i)[0]
        lba_loc = struct.unpack_from("<I",pathtable,i+2)[0]
        parent_idx = struct.unpack_from("<H",pathtable,i+6)[0]
        id_str = pathtable[i+8:i+8+id_len].decode()
        i+=8+id_len
        if id_len % 2 == 1:
            i+=1
        print("path table: " + id_str.ljust(32) + str(lba_loc))
        read_directory(file,lba_loc)
    




    

    