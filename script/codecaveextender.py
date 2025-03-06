#!/usr/bin/env python3
"""
PE Section Expander - Adds space to the .text section
Usage: python pe_section_expander.py <input_file> <output_file> <additional_bytes>
"""

import sys
import lief
import os

def align(value, alignment):
    """Align value to the next multiple of alignment"""
    return ((value + alignment - 1) // alignment) * alignment

def expand_text_section(input_file, output_file, additional_bytes):
    # Parse the PE file
    binary = lief.parse(input_file)
    
    if not binary:
        print(f"Error: Unable to parse {input_file}")
        return False
    
    # Get file and section alignment values
    file_alignment = binary.optional_header.file_alignment
    section_alignment = binary.optional_header.section_alignment
    
    # Find the .text section
    text_section = None
    text_index = -1
    
    for idx, section in enumerate(binary.sections):
        if section.name == ".text":
            text_section = section
            text_index = idx
            break
    
    if not text_section:
        print("Error: .text section not found")
        return False
    
    print(f"Original .text section:")
    print(f"  Virtual Size: 0x{text_section.virtual_size:08X}")
    print(f"  Virtual Address: 0x{text_section.virtual_address:08X}")
    print(f"  Size of Raw Data: 0x{text_section.size:08X}")
    
    # Calculate new sizes
    original_virtual_size = text_section.virtual_size
    new_virtual_size = original_virtual_size + additional_bytes
    aligned_old_size = align(original_virtual_size, section_alignment)
    aligned_new_size = align(new_virtual_size, section_alignment)
    size_increase = aligned_new_size - aligned_old_size
    
    # Calculate code cave addresses
    code_cave_start = text_section.virtual_address + original_virtual_size
    code_cave_end = text_section.virtual_address + new_virtual_size
    
    # Update .text section
    text_section.virtual_size = new_virtual_size
    if size_increase > 0:
        # If we need to increase physical size as well (crossing alignment boundary)
        new_raw_size = align(text_section.size + additional_bytes, file_alignment)
        # Add padding to the section content
        padding_size = new_raw_size - text_section.size
        text_section.content = list(text_section.content) + [0] * padding_size
        text_section.size = new_raw_size
    
    print(f"New .text section:")
    print(f"  Virtual Size: 0x{text_section.virtual_size:08X}")
    print(f"  Virtual Address: 0x{text_section.virtual_address:08X}")
    print(f"  Size of Raw Data: 0x{text_section.size:08X}")
    
    # Display code cave details
    print(f"\nCode cave details:")
    print(f"  Start RVA: 0x{code_cave_start:08X}")
    print(f"  End RVA: 0x{code_cave_end:08X}")
    print(f"  Size: 0x{additional_bytes:X} bytes")
    
    # If virtual size increase crosses section alignment boundary
    if size_increase > 0:
        print(f"\nNeed to adjust subsequent sections by 0x{size_increase:X} bytes")
        
        # Adjust RVAs of subsequent sections
        for i in range(text_index + 1, len(binary.sections)):
            section = binary.sections[i]
            old_rva = section.virtual_address
            new_rva = align(old_rva + size_increase, section_alignment)
            print(f"  Section {section.name}: 0x{old_rva:08X} -> 0x{new_rva:08X}")
            section.virtual_address = new_rva
        
        # Update SizeOfImage
        binary.optional_header.sizeof_image += size_increase
        print(f"Updated SizeOfImage: 0x{binary.optional_header.sizeof_image:08X}")
    
    # Rebuild and save
    builder = lief.PE.Builder(binary)
    builder.build()
    builder.write(output_file)
    
    print(f"\nModified PE file saved to: {output_file}")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <input_file> <output_file> <additional_bytes>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    try:
        additional_bytes = int(sys.argv[3], 0)  # Support for hex with 0x prefix
    except ValueError:
        print("Error: additional_bytes must be a number")
        sys.exit(1)
    
    if not os.path.exists(input_file):
        print(f"Error: Input file {input_file} not found")
        sys.exit(1)
    
    if expand_text_section(input_file, output_file, additional_bytes):
        print("Operation completed successfully!")
    else:
        print("Operation failed!")
        sys.exit(1)