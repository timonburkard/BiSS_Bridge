# Create work library
vlib work

# Compile Source Files
vcom -2008 ../../2_hdl/src/data_reader.vhd

# Compile Testbench
vcom -2008 ../../2_hdl/tb/tb_data_reader.vhd

# Load Simulation
vsim -voptargs=+acc work.tb_Data_Reader

# Add Waves
add wave -position insertpoint sim:/tb_Data_Reader/*
add wave -position insertpoint sim:/tb_Data_Reader/uut/state
add wave -position insertpoint sim:/tb_Data_Reader/uut/bit_cnt
add wave -position insertpoint sim:/tb_Data_Reader/uut/shift_reg

# Format Analog for Position
add wave -position insertpoint -format analog -height 100 -max 16777215 -min 0 -radix unsigned sim:/tb_Data_Reader/position_raw

# Run Simulation
run 2 ms

# Zoom full
wave zoom full
