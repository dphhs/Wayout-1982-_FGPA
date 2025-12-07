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

# Divider for REFRESH  (instance name is 'dut' in the TB)
add wave -noupdate -divider REFRESH
add wave -noupdate -label X0 -radix decimal /tb_draw_screen/dut/X0
add wave -noupdate -label Y0 -radix decimal /tb_draw_screen/dut/Y0
add wave -noupdate -label map_block -radix binary /tb_draw_screen/dut/map_block
add wave -noupdate -label x_count -radix decimal /tb_draw_screen/dut/x_count
add wave -noupdate -label y_count -radix decimal /tb_draw_screen/dut/y_count
add wave -noupdate -label tri_x0 -radix decimal /tb_draw_screen/dut/tri_x0
add wave -noupdate -label tri_y0 -radix decimal /tb_draw_screen/dut/tri_y0
add wave -noupdate -label tri_x1 -radix decimal /tb_draw_screen/dut/tri_x1
add wave -noupdate -label tri_y1 -radix decimal /tb_draw_screen/dut/tri_y1
add wave -noupdate -label tri_x2 -radix decimal /tb_draw_screen/dut/tri_x2
add wave -noupdate -label tri_y2 -radix decimal /tb_draw_screen/dut/tri_y2

add wave -noupdate -label color -radix binary /tb_draw_screen/dut/color


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
add wave -noupdate -divider States
add wave -noupdate -label state -radix binary /tb_draw_screen/dut/state
# add wave -noupdate -label quad_start -radix binary /tb_draw_screen/dut/quad_start

# Divider for DUT V_Calculation
add wave -noupdate -divider D
add wave -noupdate -label end_x0 -radix decimal /tb_draw_screen/dut/end_x0
add wave -noupdate -label end_x1 -radix decimal /tb_draw_screen/dut/end_x1
add wave -noupdate -label end_x2 -radix decimal /tb_draw_screen/dut/end_x2
add wave -noupdate -label end_x3 -radix decimal /tb_draw_screen/dut/end_x3
add wave -noupdate -label end_y0 -radix decimal /tb_draw_screen/dut/end_y0
add wave -noupdate -label end_y1 -radix decimal /tb_draw_screen/dut/end_y1
add wave -noupdate -label end_y2 -radix decimal /tb_draw_screen/dut/end_y2
add wave -noupdate -label end_y3 -radix decimal /tb_draw_screen/dut/end_y3


add wave -noupdate -label dD -radix decimal /tb_draw_screen/dut/dD
add wave -noupdate -label ddD -radix decimal /tb_draw_screen/dut/ddD
add wave -noupdate -label dV -radix decimal /tb_draw_screen/dut/dV
add wave -noupdate -label ddV -radix decimal /tb_draw_screen/dut/ddV

add wave -noupdate -label isCounting -radix binary /tb_draw_screen/dut/isCounting
add wave -noupdate -label reachEnd -radix binary /tb_draw_screen/dut/reachEnd

# Divider for DUT current_block
add wave -noupdate -divider current_block
add wave -noupdate -label current_block -radix binary /tb_draw_screen/dut/current_block
add wave -noupdate -label index_x -radix decimal /tb_draw_screen/dut/index_x
add wave -noupdate -label index_y -radix decimal /tb_draw_screen/dut/index_y

# Divider for DUT test_block
add wave -noupdate -divider test_block
add wave -noupdate -label test_block -radix binary /tb_draw_screen/dut/test_block
add wave -noupdate -label test_x -radix decimal /tb_draw_screen/dut/test_x
add wave -noupdate -label test_y -radix decimal /tb_draw_screen/dut/test_y

# Divider for DUT Map and Position
add wave -noupdate -divider Position_Map
add wave -noupdate -label dx -radix decimal /tb_draw_screen/dut/dx
add wave -noupdate -label dy -radix decimal /tb_draw_screen/dut/dy
add wave -noupdate -label ddx -radix decimal /tb_draw_screen/dut/ddx
add wave -noupdate -label ddy -radix decimal /tb_draw_screen/dut/ddy
add wave -noupdate -label px -radix decimal /tb_draw_screen/dut/px
add wave -noupdate -label py -radix decimal /tb_draw_screen/dut/py
add wave -noupdate -label end_d -radix decimal /tb_draw_screen/dut/end_d
add wave -noupdate -label map -radix binary /tb_draw_screen/dut/map



WaveRestoreZoom {0 ns} {0.01 us}

# Finalize waveform window
update

# Run simulation until the testbench stops
run 200000000ps   
wave zoom range 80000ps 300000ps

# Stop simulation at the end
stop
