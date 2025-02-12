def ip_to_hex(ip):
    # Split IP into octets and convert to integers
    octets = [int(x) for x in ip.split('.')]
    
    # Reverse octets for network byte order
    octets.reverse()
    
    # Convert to hex
    hex_value = '0x' + ''.join([format(x, '02X') for x in octets])
    
    return hex_value

# Example usage
ip = input("Enter IP address (e.g. 192.168.1.1): ")
result = ip_to_hex(ip)
print(f"Hex value: {result}")
