#!/usr/bin/env python3
"""
Calculate CRC-6 values for test vectors using the same algorithm as data_checker.vhd
CRC-6 polynomial: x^6 + x + 1 (hex 0x43), implemented MSB-first
Coverage: position bits + status bits (Error, Warning) as transmitted on SLO.
Many BiSS encoders transmit inverted status and CRC bits on the line.
"""

def calculate_crc6(position_data, data_width=22, error_bit=0, warning_bit=0):
    """
    Calculate CRC-6 over position bits plus status bits (error, warning).
    Mirrors the VHDL implementation in 2_hdl/src/data_checker.vhd.

    Args:
        position_data: Position value as integer
        data_width: Number of bits in position data (default: 22)
        error_bit: Decoded error bit (active-high). On the line it is inverted.
        warning_bit: Decoded warning bit (active-high). On the line it is inverted.

    Returns:
        CRC remainder (6-bit, non-inverted). To get transmitted bits, invert.
    """
    crc = 0  # 6-bit value

    # Process position bits from MSB to LSB
    for i in range(data_width-1, -1, -1):
        bit = (position_data >> i) & 1
        feedback = bit ^ ((crc >> 5) & 1)
        crc = (crc << 1) & 0x3F
        if feedback:
            crc ^= 0x03  # polynomial without MSB: x^1 + x^0

    # Include status bits in the same order as transmitted: error then warning
    raw_error = 1 ^ (error_bit & 1)   # raw transmitted bit on SLO = not(decoded)
    raw_warning = 1 ^ (warning_bit & 1)

    # Error bit
    feedback = raw_error ^ ((crc >> 5) & 1)
    crc = (crc << 1) & 0x3F
    if feedback:
        crc ^= 0x03

    # Warning bit
    feedback = raw_warning ^ ((crc >> 5) & 1)
    crc = (crc << 1) & 0x3F
    if feedback:
        crc ^= 0x03

    return crc & 0x3F


# Configuration
DATA_WIDTH = 22  # Position data width in bits

# Test vectors: (position, error, warning, description)
test_vectors = [
    (0x000000, 0, 0, "All zeros"),
    (0x3FFFFF, 0, 0, "All ones (22-bit)"),
    (0x123456 & 0x3FFFFF, 0, 0, "Test pattern 1"),
    (0x2BCDEF, 0, 0, "Test pattern 2"),
    (0x154321, 0, 0, "Test pattern 3"),
    (0x3EDCBA, 0, 0, "Test pattern 4"),
    (0x02EFCA, 0, 0, "Test pattern real"),
    # Status-bit coverage examples
    (0x012345, 1, 0, "Error=1, Warning=0"),
    (0x012345, 0, 1, "Error=0, Warning=1"),
]

print(f"CRC-6 Calculation Results (DATA_WIDTH={DATA_WIDTH}):")
print("=" * 70)

vhdl_output = []
for pos, err, warn, desc in test_vectors:
    crc = calculate_crc6(pos, DATA_WIDTH, err, warn)
    transmitted_crc = (~crc) & 0x3F  # encoder transmits inverted CRC bits
    crc_binary = f"{transmitted_crc:06b}"
    print(
        f"Position: 0x{pos:06X} ({desc:20s}) | E={err} W={warn} "
        f"=> CRC: 0x{crc:02X} (tx: 0x{transmitted_crc:02X} = {crc_binary})"
    )

    # Format position as binary string for VHDL
    pos_binary = f"{pos:0{DATA_WIDTH}b}"
    # Note: Data_Checker now expects error/warning as decoded active-high ports.
    # For vector generation we keep E/W at '0' unless specified.
    vhdl_output.append(
        f'(position => "{pos_binary}", crc => "{crc_binary}"),  -- {desc}, E={err}, W={warn}'
    )

print("\n" + "=" * 70)
print("VHDL Test Vector Array:")
print("=" * 70)
print("constant TEST_VECTORS : test_vector_array_t := (")
for i, line in enumerate(vhdl_output):
    if i < len(vhdl_output) - 1:
        print("    " + line)
    else:
        # Remove trailing comma from last entry
        print("    " + line[:-1])
print(");")
