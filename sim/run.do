
vlog -work work -sv ../src/burst_data.sv
vlog -work work -sv ../src/burst_cas.sv
vlog -work work -sv ../src/burst_rw.sv
vlog -work work -sv ../src/burst_data.sv
vlog -work work -sv ../src/burst_conf.sv
vlog -work work -sv ../src/burst_act.sv
vlog -work work -sv ../src/ddr_controller.sv
vlog -work work -sv ../src/ctrl_interface.sv
vlog -work work -sv ../src/dimm_model.sv
vlog -work work -sv ../src/ddr_top.sv
vlog -work work -sv ../src/ddr_interface.sv
vlog -work work -sv ../src/memory_check.sv
vlog -work work -sv ../src/ddr_clock.sv
vlog -work work -sv ../src/test.sv
vlog -work work -sv ../src/Assersions.sv
vlog -work work -sv ../src/Stimulus_save.sv
vsim -voptargs=+acc work.top
do wave.do

