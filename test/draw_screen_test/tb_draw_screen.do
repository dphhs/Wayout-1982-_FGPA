# tb_draw_screen_labeled_safe.do

# Create work library if it doesn't exist
if {![file exists work]} {
    vlib work
}

vmap work work

# Compile sources: SystemVerilog modules first, then TB
vlog draw_screen.sv
vlog tb_draw_screen.sv

# Load the simulation
vsim tb_draw_screen

# Waveform setup

# Divider for control / stimulus signals
add wave -noupdate -divider Control
add wave -noupdate -label clk -radix binary /tb_draw_screen/clk
add wave -noupdate -label rstn -radix binary /tb_draw_screen/rstn
add wave -noupdate -label refresh -radix binary /tb_draw_screen/refresh



# Divider for DUT Vertexes (instance name is 'dut' in the TB)
add wave -noupdate -divider DUT_Vertexes
add wave -noupdate -label X0 -radix decimal /tb_draw_screen/dut/X0
add wave -noupdate -label Y0 -radix decimal /tb_draw_screen/dut/Y0
add wave -noupdate -label X1 -radix decimal /tb_draw_screen/dut/X1
add wave -noupdate -label Y1 -radix decimal /tb_draw_screen/dut/Y1
add wave -noupdate -label X2 -radix decimal /tb_draw_screen/dut/X2
add wave -noupdate -label Y2 -radix decimal /tb_draw_screen/dut/Y2
add wave -noupdate -label X3 -radix decimal /tb_draw_screen/dut/X3
add wave -noupdate -label Y3 -radix decimal /tb_draw_screen/dut/Y3

# Divider for DUT Vertexes (instance name is 'dut' in the TB)
add wave -noupdate -divider State
add wave -noupdate -label state -radix binary /tb_draw_screen/dut/state
add wave -noupdate -label quad_start -radix binary /tb_draw_screen/dut/quad_start


# Divider for DUT Internal
add wave -noupdate -divider Internal
add wave -noupdate -label check_block -radix binary /tb_draw_screen/dut/check_block
add wave -noupdate -label index_x -radix decimal /tb_draw_screen/dut/index_x
add wave -noupdate -label index_y -radix decimal /tb_draw_screen/dut/index_y
add wave -noupdate -label dx -radix decimal /tb_draw_screen/dut/dx
add wave -noupdate -label dy -radix decimal /tb_draw_screen/dut/dy
add wave -noupdate -label px -radix decimal /tb_draw_screen/dut/px
add wave -noupdate -label py -radix decimal /tb_draw_screen/dut/py
add wave -noupdate -label end_d -radix decimal /tb_draw_screen/dut/end_d
add wave -noupdate -label map -radix binary /tb_draw_screen/dut/map



WaveRestoreZoom {0 ns} {0.005 us}

# Finalize waveform window
update

# Run simulation until the testbench stops
run 250000ps   
wave zoom range 80000ps 100000ps

# Stop simulation at the end
stop
