# Quit any running simulation
quit -sim

# Clean up old work library
vdel -all -lib work

# Create work library
vlib work

# Compile Package
vcom -2008 ../2_hdl/src/biss_bridge_pkg.vhd

# Compile Source Files
vcom -2008 ../2_hdl/src/control.vhd

# Compile Testbench
vcom -2008 ../2_hdl/tb/tb_control.vhd

# Load Simulation
vsim -voptargs=+acc work.tb_control

# Add Waves
add wave -position insertpoint sim:/tb_control/*
add wave -position insertpoint sim:/tb_control/DUT/counter

# Run Simulation
run 1 ms

# Zoom full
wave zoom full
