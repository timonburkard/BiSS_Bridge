# Quit any running simulation
quit -sim

# Clean up old work library
vdel -all -lib work

# Create work library
vlib work

# Compile Source Files
vcom -2008 ../2_hdl/src/data_checker.vhd

# Compile Testbench
vcom -2008 ../2_hdl/tb/tb_data_checker.vhd

# Load Simulation
vsim -voptargs=+acc work.tb_data_checker

# Add Waves
add wave -position insertpoint sim:/tb_data_checker/DUT/*

# Run Simulation
run 1 ms

# Zoom full
wave zoom full
