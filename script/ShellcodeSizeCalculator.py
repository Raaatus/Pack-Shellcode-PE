#!/usr/bin/env python3

import sys
import re
import os
import argparse

def calculate_size_from_hex_string(hex_string):
    # Nettoie la chaîne hex en supprimant espaces, virgules, \x, 0x, etc.
    hex_string = re.sub(r'\\x|0x|,|\s', '', hex_string)
    # Si la longueur n'est pas paire (chaque octet = 2 caractères hex)
    if len(hex_string) % 2 != 0:
        print("[ERREUR] Format hex invalide: longueur impaire de caractères")
        return 0
    
    return len(hex_string) // 2

def calculate_size_from_file(file_path):
    try:
        return os.path.getsize(file_path)
    except Exception as e:
        print(f"[ERREUR] Impossible de lire le fichier: {e}")
        return 0

def calculate_size_from_c_array(c_array):
    # Extrait les valeurs hexadécimales du tableau C
    hex_values = re.findall(r'0x[0-9a-fA-F]{1,2}|\d+', c_array)
    return len(hex_values)

def main():
    parser = argparse.ArgumentParser(description="Calculer la taille d'un shellcode en octets")
    
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument('-s', '--string', help='Chaîne hexadécimale (ex: "\\x41\\x42\\x43" ou "41,42,43" ou "414243")')
    input_group.add_argument('-f', '--file', help='Chemin vers un fichier binaire contenant le shellcode')
    input_group.add_argument('-c', '--carray', help='Tableau C (ex: "{ 0x41, 0x42, 0x43 }")')
    
    args = parser.parse_args()
    
    if args.string:
        size = calculate_size_from_hex_string(args.string)
        print(f"Taille du shellcode: {size} octets")
    
    elif args.file:
        size = calculate_size_from_file(args.file)
        print(f"Taille du shellcode: {size} octets")
    
    elif args.carray:
        size = calculate_size_from_c_array(args.carray)
        print(f"Taille du shellcode: {size} octets")

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("Utilisation:")
        print("1. Pour une chaîne hexadécimale: python shellcode_size.py -s \"\\x41\\x42\\x43\"")
        print("2. Pour un fichier: python shellcode_size.py -f shellcode.bin")
        print("3. Pour un tableau C: python shellcode_size.py -c \"{ 0x41, 0x42, 0x43 }\"")
    else:
        main()