onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top/intf/clock_n
add wave -noupdate /top/intf/clock_t
add wave -noupdate /top/intf/clock_w
add wave -noupdate /top/intf/clock_r
add wave -noupdate /top/intf/reset_n
add wave -noupdate /top/intf/cke
add wave -noupdate /top/intf/cs_n
add wave -noupdate /top/intf/act_n
add wave -noupdate /top/intf/ras_n_a16
add wave -noupdate /top/intf/cas_n_a15
add wave -noupdate /top/intf/we_n_a14
add wave -noupdate /top/intf/bc_n_a12
add wave -noupdate /top/intf/ap_a10
add wave -noupdate /top/intf/addr17
add wave -noupdate /top/intf/addr13
add wave -noupdate /top/intf/addr11
add wave -noupdate /top/intf/addr9_0
add wave -noupdate /top/intf/bg_addr
add wave -noupdate /top/intf/ba_addr
add wave -noupdate /top/intf/C2_0
add wave -noupdate /top/intf/dq
add wave -noupdate /top/intf/dqs_t
add wave -noupdate /top/intf/dqs_c
add wave -noupdate /top/stim/data
add wave -noupdate -label physical_addr /top/stim/data.physical_addr
add wave -noupdate -label data_wr /top/stim/data.data_wr
add wave -noupdate -label rw /top/stim/data.rw
add wave -noupdate /top/stim/act_cmd
add wave -noupdate /top/stim/dev_busy
add wave -noupdate /top/ddr_top/dev_busy
add wave -noupdate /top/ddr_top/ctrl_intf/rw_proc
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {6 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
configure wave -timelineunits ms
update
WaveRestoreZoom {0 ps} {1056 ps}
