# tb_sine_lut_360_labeled.do
# Compile the design and testbench (clean work each run)
vdel -lib work -all
vlib work
vmap work work

# Compile sources: plain Verilog first, then SystemVerilog, then TB
vlog rom_async.v
vlog sine_lut_360.sv
vlog tb_sine_lut_360.v

# Load the simulation (top-level must match module name in TB)
vsim tb_sine_lut_360

# Waveform setup

# Divider for control / stimulus signals
add wave -noupdate -divider Control
add wave -noupdate -label angle_id -radix decimal /tb_sine_lut_360/angle_id

# Divider for DUT outputs
add wave -noupdate -divider Outputs
add wave -noupdate -label sine_out_hex -radix hex /tb_sine_lut_360/sine_out
add wave -noupdate -label sine_out_dec -radix decimal /tb_sine_lut_360/sine_out

# Divider for DUT internals (instance name is 'dut' in the TB)
add wave -noupdate -divider DUT_Internal
add wave -noupdate -label tab_id -radix decimal /tb_sine_lut_360/dut/tab_id
add wave -noupdate -label quad -radix binary  /tb_sine_lut_360/dut/quad
add wave -noupdate -label tab_data -radix hex  /tb_sine_lut_360/dut/tab_data

# Finalize waveform window
update

# Run simulation until the testbench stops (or use a fixed time like 'run 600ns')
run -all

# Stop simulation at the end
stop
