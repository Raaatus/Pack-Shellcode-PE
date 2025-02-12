# ImageBase
image_base = 0x14000000

# Adresses en RVA
source_rva = 0x19e2e1

dest_rva = 0xb9744

# Conversion des adresses RVA en VA
source_va = source_rva + image_base
dest_va = dest_rva + image_base

# Calcul des décalages
jmp_size = 5  # Taille de l'instruction JMP rel32
offset = dest_va - (source_va + jmp_size)

# Affichage du décalage en little-endian
offset_bytes = offset.to_bytes(4, byteorder='little', signed=True)
offset_hex = ' '.join(f'{b:02X}' for b in offset_bytes)

print(offset, offset_hex)