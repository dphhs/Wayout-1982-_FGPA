# tb_vertex_loader_labeled.do

# Create and map work library
vlib work
vlog vertex_ram.v
vlog vertex_loader.v
vlog tb_vertex_loader.sv

# Load simulation
vsim vertex_loader_tb





# ================================
# Waveform setup
# ================================

###############
# Control Signals
###############
add wave -noupdate -divider Control
add wave -noupdate -label clk        -radix binary  /vertex_loader_tb/clk
add wave -noupdate -label rst_n      -radix binary  /vertex_loader_tb/rst_n
add wave -noupdate -label start_load -radix binary  /vertex_loader_tb/start_loading
add wave -noupdate -label line_done  -radix binary  /vertex_loader_tb/line_done
add wave -noupdate -label shape_sel  -radix unsigned /vertex_loader_tb/shape_sel

###############
# Output Vertices
###############
add wave -noupdate -divider Vertices
add wave -noupdate -label x0 -radix decimal /vertex_loader_tb/dut/x0
add wave -noupdate -label y0 -radix decimal /vertex_loader_tb/dut/y0
add wave -noupdate -label x1 -radix decimal /vertex_loader_tb/dut/x1
add wave -noupdate -label y1 -radix decimal /vertex_loader_tb/dut/y1
add wave -noupdate -label x2 -radix decimal /vertex_loader_tb/dut/x2
add wave -noupdate -label y2 -radix decimal /vertex_loader_tb/dut/y2
add wave -noupdate -label x3 -radix decimal /vertex_loader_tb/dut/x3
add wave -noupdate -label y3 -radix decimal /vertex_loader_tb/dut/y3

###############
# Status Flags
###############
add wave -noupdate -divider Flags
add wave -noupdate -label draw_lines -radix binary /vertex_loader_tb/dut/draw_lines
add wave -noupdate -label busy       -radix binary /vertex_loader_tb/dut/busy
add wave -noupdate -label ready      -radix binary /vertex_loader_tb/dut/ready

###############
# RAM Interface
###############
add wave -noupdate -divider RAM
add wave -noupdate -label read_addr    -radix unsigned /vertex_loader_tb/dut/read_addr
add wave -noupdate -label write_addr   -radix unsigned /vertex_loader_tb/dut/write_addr
add wave -noupdate -label read_data    -radix decimal  /vertex_loader_tb/dut/read_data
add wave -noupdate -label write_data   -radix decimal  /vertex_loader_tb/dut/write_data
add wave -noupdate -label write_enable -radix binary   /vertex_loader_tb/dut/write_enable

###############
# FSM
###############
add wave -noupdate -divider FSM
add wave -noupdate -label state -radix unsigned /vertex_loader_tb/dut/state

# Finalize waveform window
update

# Run the simulation
run 600ns

# Stop simulation
stop
