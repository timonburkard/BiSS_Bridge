#!/usr/bin/env python3
"""
Calculate CRC-6 values for test vectors using the same algorithm as data_checker.vhd
CRC-6 polynomial: x^6 + x + 1 (hex 0x43), implemented MSB-first
"""

def calculate_crc6(position_data):
    """
    Calculate CRC-6 for a 24-bit position value
    Matches the VHDL implementation in data_checker.vhd
    """
    crc = 0  # 6-bit value
    
    # Process bits from MSB to LSB (bit 23 down to 0)
    for i in range(23, -1, -1):
        # Extract bit at position i
        bit = (position_data >> i) & 1
        
        # feedback = input_bit xor crc_msb (bit 5)
        feedback = bit ^ ((crc >> 5) & 1)
        
        # Shift left by 1 (remove MSB, add 0 at LSB)
        crc = (crc << 1) & 0x3F  # Keep only 6 bits
        
        # XOR with polynomial (without MSB): x^1 + x^0 => bits 1 and 0
        if feedback:
            crc ^= 0x03  # Toggle bits 1 and 0
    
    return crc & 0x3F


# Test vectors
test_vectors = [
    (0x000000, "All zeros"),
    (0xFFFFFF, "All ones"),
    (0x123456, "Test pattern 1"),
    (0xABCDEF, "Test pattern 2"),
    (0x654321, "Test pattern 3"),
    (0xFEDCBA, "Test pattern 4"),
]

print("CRC-6 Calculation Results:")
print("=" * 70)

vhdl_output = []
for pos, desc in test_vectors:
    crc = calculate_crc6(pos)
    crc_binary = f"{crc:06b}"
    print(f"Position: 0x{pos:06X} ({desc:20s}) => CRC: 0x{crc:02X} = {crc_binary}")
    vhdl_output.append(f'(position => X"{pos:06X}", crc => "{crc_binary}"),  -- {desc}')

print("\n" + "=" * 70)
print("VHDL Test Vector Array:")
print("=" * 70)
print("constant TEST_VECTORS : test_vector_array_t := (")
for i, line in enumerate(vhdl_output):
    if i < len(vhdl_output) - 1:
        print("    " + line)
    else:
        print("    " + line.rstrip(",") + "  -- " + line.split("--")[1].strip())
print(");")
