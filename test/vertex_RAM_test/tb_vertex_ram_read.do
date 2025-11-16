# tb_vertex_ram_read.do
# ModelSim/Quartus simulation script for testing preloaded RAM

# 1. Set up libraries
vlib work
vmap work work

# 2. Compile your RAM and testbench
vlog vertex_ram.v
vlog tb_vertex_ram_read.sv

# 3. Load the simulation
vsim -t 1ns tb_vertex_ram_read

# 4. Run the simulation for enough time to read all addresses
run 1300ns

# 5. Optional: log output to a file
log -r /*

# 6. Stop simulation
quit -f
