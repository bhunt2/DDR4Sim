onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top/intf/clock_n
add wave -noupdate /top/intf/clock_t
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
add wave -noupdate /top/ddr_top/ctrl_intf/rw_proc
add wave -noupdate /top/ddr_top/burst_act/act_state
add wave -noupdate /top/ddr_top/burst_act/act_next_state
add wave -noupdate /top/ddr_top/burst_cas/cas_state
add wave -noupdate /top/ddr_top/burst_cas/cas_next_state
add wave -noupdate /top/ddr_top/burst_rw/rw_state
add wave -noupdate /top/ddr_top/burst_rw/rw_next_state
add wave -noupdate /top/tb_intf/data_in
add wave -noupdate /top/tb_intf/act_cmd
add wave -noupdate /top/tb_intf/dev_busy
add wave -noupdate /top/tb_intf/next_cmd
add wave -noupdate /top/tb_intf/dev_rd
add wave -noupdate /top/tb_intf/dev_rw
add wave -noupdate -radix hexadecimal /top/ddr_top/burst_act/act_counter
add wave -noupdate -radix decimal /top/ddr_top/burst_cas/cas_delay
add wave -noupdate -radix decimal /top/ddr_top/burst_cas/cas_counter
add wave -noupdate /top/ddr_top/ctrl_intf/act_rdy
add wave -noupdate /top/ddr_top/ctrl_intf/no_act_rdy
add wave -noupdate /top/ddr_top/ctrl_intf/cas_rdy
add wave -noupdate /top/ddr_top/burst_cas/size_queue
add wave -noupdate /top/ddr_top/ctrl_intf/rw_rdy
add wave -noupdate /top/intf/dq
add wave -noupdate /top/intf/dqs_t
add wave -noupdate /top/intf/dqs_c
add wave -noupdate /top/dimm/wr_end
add wave -noupdate /top/dimm/rd_start
add wave -noupdate /top/mem_chk/rd_end_d
add wave -noupdate -expand -subitemconfig {/top/ddr_top/burst_data/cas_in.addr -expand} /top/ddr_top/burst_data/cas_in
add wave -noupdate -expand -subitemconfig {/top/ddr_top/burst_data/cmd_out.cmd_data -expand /top/ddr_top/burst_data/cmd_out.cmd_data.addr -expand} /top/ddr_top/burst_data/cmd_out
add wave -noupdate /top/ddr_top/burst_data/rw_in
add wave -noupdate /top/ddr_top/ctrl_intf/mem_addr
add wave -noupdate /top/ddr_top/ctrl_intf/pre_reg
add wave -noupdate /top/ddr_top/burst_data/rw_out
add wave -noupdate /top/dimm/data_out
add wave -noupdate /top/dimm/data_t
add wave -noupdate /top/dimm/data_c
add wave -noupdate /top/dimm/row_addr
add wave -noupdate /top/dimm/col_addr
add wave -noupdate /top/ddr_top/burst_rw/next_rw
add wave -noupdate /top/ddr_top/burst_rw/temp
add wave -noupdate /top/ddr_top/burst_rw/DELAY
add wave -noupdate /top/ddr_top/burst_rw/rw_delay
add wave -noupdate /top/dimm/data_t
add wave -noupdate /top/dimm/data_c
add wave -noupdate /top/dimm/wr_end_d
add wave -noupdate /top/mem_chk/data_c
add wave -noupdate /top/mem_chk/data_t
add wave -noupdate /top/ddr_top/ctrl_intf/rw_rdy
add wave -noupdate -label rw /top/ddr_top/burst_data/rw_out.rw
add wave -noupdate /top/mem_chk/cycle_8
add wave -noupdate /top/mem_chk/cycle_8_d
add wave -noupdate /top/intf/clock_n
add wave -noupdate /top/intf/clock_t
add wave -noupdate /top/mem_chk/act_cmd_d
add wave -noupdate -expand /top/tb_intf/data_in
add wave -noupdate /top/mem_chk/raddr
add wave -noupdate /top/mem_chk/index
add wave -noupdate /top/ddr_top/ctrl_intf/CWL
add wave -noupdate /top/ddr_top/ctrl_intf/CL
add wave -noupdate /top/ddr_top/ctrl_intf/mrs_rdy
add wave -noupdate /top/ddr_top/ctrl_intf/mode_reg
add wave -noupdate /top/ddr_top/burst_cas/request
add wave -noupdate /top/ddr_top/burst_cas/prev_rq
add wave -noupdate /top/ddr_top/burst_cas/size_queue
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {465418 ps} 0} {{Cursor 2} {367868 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 240
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
WaveRestoreZoom {367678 ps} {368470 ps}
