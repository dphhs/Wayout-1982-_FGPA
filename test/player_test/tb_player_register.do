# tb_player_register_labeled.do

# Compile the design and testbench
vlib work
vlog player_register.v
vlog tb_player_register.v

# Load the simulation
vsim tb_player_register

# Waveform setup

# Divider for control signals
add wave -noupdate -divider Control
add wave -noupdate -label forward -radix binary /tb_player_register/forward
add wave -noupdate -label rotate -radix binary /tb_player_register/rotate
add wave -noupdate -label resetn -radix binary /tb_player_register/resetn
add wave -noupdate -label clk -radix binary /tb_player_register/clk

# Divider for position outputs
add wave -noupdate -divider Position
add wave -noupdate -label x_position -radix decimal /tb_player_register/x_position
add wave -noupdate -label y_position -radix decimal /tb_player_register/y_position

# Divider for angle
add wave -noupdate -divider Angle
add wave -noupdate -label angle -radix decimal /tb_player_register/angle

# Finalize waveform window
update

# Run simulation
run 600ns

# Stop simulation at the end
stop
