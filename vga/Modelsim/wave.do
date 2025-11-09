onerror {resume}
quietly WaveActivateNextPane {} 0

# Top-level TB I/O
add wave -noupdate -label CLOCK_50 -radix binary /testbench/CLOCK_50
add wave -noupdate -label ResetN   -radix binary /testbench/KEY

# -------- VGA DUT --------
add wave -noupdate -divider vga

# HS/VS and RGB from DUT
add wave -noupdate -label VGA_HS -radix binary     /testbench/U1/VGA_HS
add wave -noupdate -label VGA_VS -radix binary     /testbench/U1/VGA_VS
add wave -noupdate -label VGA_R  -radix hexadecimal /testbench/U1/VGA_R
add wave -noupdate -label VGA_G  -radix hexadecimal /testbench/U1/VGA_G
add wave -noupdate -label VGA_B  -radix hexadecimal /testbench/U1/VGA_B

# Pixel clock from VGA_CLOCK
add wave -noupdate -label vga_clock -radix binary /testbench/U1/make_vga_clock/vga_clock

# Horizontal timing internals
add wave -noupdate -divider {h timing}
add wave -noupdate -label h_count            -radix unsigned   /testbench/U1/h_counter/h_count
add wave -noupdate -label enable_vertical_tick -radix binary   /testbench/U1/h_counter/enable_vertical_tick

# Vertical timing internals
add wave -noupdate -divider {v timing}
add wave -noupdate -label v_count -radix unsigned /testbench/U1/v_counter/v_count

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 80
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {120 ns}
