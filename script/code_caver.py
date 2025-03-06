#!/usr/bin/python3

""" pycave.py: Dirty code to find code caves in Portable Executable files"""

__author__ = 'axcheron'
__license__ = 'Apache 2'
__version__ = '0.4- By Ratus'

import argparse
import pefile
import sys
import os


def is_suitable_for_shellcode(permissions, size, min_size=100):
    """Détermine si un code cave est approprié pour un shellcode"""
    has_exec = 'X' in permissions
    has_write = 'W' in permissions
    is_big_enough = size >= min_size
    
    if has_exec and has_write and is_big_enough:
        return "EXCELLENT (RWX)"
    elif has_exec and is_big_enough:
        return "GOOD (RX)"
    elif has_write and is_big_enough:
        return "POSSIBLE (RW)"
    else:
        return "UNSUITABLE"


def pycave(file_name, cave_size, base, shellcode_file=None):
    image_base = int(base, 16)
    min_cave = cave_size
    fname = file_name
    pe = None
    
    # Shellcode handling
    shellcode_size = 0
    if shellcode_file:
        try:
            shellcode_size = os.path.getsize(shellcode_file)
            print(f"[+] Shellcode file size: {shellcode_size} bytes")
        except Exception as e:
            print(f"[-] Error reading shellcode file: {e}")
            shellcode_file = None

    try:
        pe = pefile.PE(fname)
    except IOError as e:
        print(e)
        sys.exit(0)
    except pefile.PEFormatError as e:
        print("[-] %s" % e.args[0])
        sys.exit(0)

    print("[+] Minimum code cave size: %d" % min_cave)
    print("[+] Image Base:  0x%08X" % image_base)
    print("[+] Loading \"%s\"..." % fname)

    # IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE = 0x0040
    is_aslr = pe.OPTIONAL_HEADER.DllCharacteristics & 0x0040

    if is_aslr:
        print("\n[!] ASLR is enabled. Virtual Address (VA) could be different once loaded in memory.")

    fd = open(fname, "rb")

    suitable_caves_found = 0
    shellcode_compatible_caves = 0
    
    print("\n[+] Looking for code caves...")
    for section in pe.sections:
        if section.SizeOfRawData != 0:
            pos = 0
            count = 0
            fd.seek(section.PointerToRawData, 0)
            data = fd.read(section.SizeOfRawData)

            # Get section permissions
            is_readable = section.Characteristics & 0x40000000 # IMAGE_SCN_MEM_READ
            is_writable = section.Characteristics & 0x80000000 # IMAGE_SCN_MEM_WRITE
            is_executable = section.Characteristics & 0x20000000 # IMAGE_SCN_MEM_EXECUTE
            
            for byte in data:
                pos += 1
                if byte == 0x00:
                    count += 1
                else:
                    if count > min_cave:
                        # Calculate start addresses
                        raw_addr_start = section.PointerToRawData + pos - count - 1
                        vir_addr_start = image_base + section.VirtualAddress + pos - count - 1
                        
                        # Calculate end addresses
                        raw_addr_end = raw_addr_start + count - 1
                        vir_addr_end = vir_addr_start + count - 1

                        # Generate permissions string
                        permissions = ""
                        permissions += "R" if is_readable else "-"
                        permissions += "W" if is_writable else "-"
                        permissions += "X" if is_executable else "-"
                        
                        # Évaluer si la cave est appropriée pour un shellcode
                        suitability = is_suitable_for_shellcode(permissions, count)
                        
                        # Check if this cave can fit the shellcode
                        shellcode_compatible = ""
                        if shellcode_file and count >= shellcode_size:
                            shellcode_compatible = "✓ SHELLCODE FITS!"
                            shellcode_compatible_caves += 1
                        elif shellcode_file:
                            shellcode_compatible = "✗ TOO SMALL FOR SHELLCODE"
                        
                        if "EXCELLENT" in suitability or "GOOD" in suitability:
                            suitable_caves_found += 1
                        
                        output = f"[+] Code cave found in {section.Name.decode()} \tSize: {count} bytes\n"
                        output += f"    Start RA: 0x{raw_addr_start:08X}  Start VA: 0x{vir_addr_start:08X}\n"
                        output += f"    End RA:   0x{raw_addr_end:08X}  End VA:   0x{vir_addr_end:08X}\n"
                        output += f"    Perm: {permissions}  Suitability: {suitability}\n\n"
                        
                        if shellcode_file:
                            output += f"  {shellcode_compatible}"
                        
                        print(output)
                    count = 0

    print(f"\n[+] Found {suitable_caves_found} suitable caves for code execution")
    
    if shellcode_file:
        print(f"[+] Found {shellcode_compatible_caves} caves that can fit the provided shellcode ({shellcode_size} bytes)")

    pe.close()
    fd.close()


if __name__ == "__main__":
    '''This function parses and return arguments passed in'''
    # Assign description to the help doc
    parser = argparse.ArgumentParser(
        description="Find code caves in PE files")

    # Add arguments
    parser.add_argument("-f", "--file", dest="file_name", action="store", required=True,
                        help="PE file", type=str)

    parser.add_argument("-s", "--size", dest="size", action="store", default=300,
                        help="Min. cave size", type=int)

    parser.add_argument("-b", "--base", dest="base", action="store", default="0x00400000",
                        help="Image base", type=str)
                        
    parser.add_argument("-c", "--shellcode", dest="shellcode_file", action="store", 
                        help="Shellcode file to check for compatibility", type=str)

    args = parser.parse_args()

    if args.file_name:
        pycave(args.file_name, args.size, args.base, args.shellcode_file)
    else:
        parser.print_help()
        exit(-1)