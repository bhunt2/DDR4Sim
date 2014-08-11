onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top/burst_act/act_cmd
add wave -noupdate /top/burst_act/act_state
add wave -noupdate /top/burst_act/act_next_state
add wave -noupdate /top/burst_cas/cas_state
add wave -noupdate /top/burst_cas/cas_next_state
add wave -noupdate /top/burst_cas/clear_cas_counter
add wave -noupdate /top/burst_rw/rw_state
add wave -noupdate /top/burst_rw/rw_next_state
add wave -noupdate /top/ctrl_intf/rw_proc
add wave -noupdate /top/burst_cas/next_cas
add wave -noupdate /top/burst_cas/request
add wave -noupdate /top/burst_cas/prev_rq
add wave -noupdate /top/ctrl_intf/act_rdy
add wave -noupdate /top/ctrl_intf/cas_rdy
add wave -noupdate /top/ctrl_intf/rw_rdy
add wave -noupdate /top/ctrl_intf/act_rw
add wave -noupdate /top/intf/cs_n
add wave -noupdate /top/intf/act_n
add wave -noupdate /top/stim/act_cmd
add wave -noupdate /top/intf/ras_n_a16
add wave -noupdate /top/intf/cas_n_a15
add wave -noupdate /top/intf/we_n_a14
add wave -noupdate /top/intf/bc_n_a12
add wave -noupdate /top/intf/ap_a10
add wave -noupdate /top/intf/addr17
add wave -noupdate /top/intf/addr13
add wave -noupdate /top/intf/addr11
add wave -noupdate /top/intf/addr9_0
add wave -noupdate /top/intf/dqs_t
add wave -noupdate /top/intf/dqs_c
add wave -noupdate /top/ctrl_intf/dimm_rd
add wave -noupdate /top/dimm/rd_start_dd
add wave -noupdate /top/intf/dq
add wave -noupdate -expand -group dimm_model /top/dimm/data_t
add wave -noupdate -expand -group dimm_model /top/dimm/data_c
add wave -noupdate -expand -group dimm_model -expand /top/dimm/data_out
add wave -noupdate -expand -group dimm_model /top/dimm/rd_start
add wave -noupdate -expand -group dimm_model /top/dimm/rd_start_d
add wave -noupdate -expand -group dimm_model /top/dimm/cycle_8
add wave -noupdate -expand -group dimm_model /top/dimm/cycle_4
add wave -noupdate -expand -group dimm_model /top/dimm/wr_end
add wave -noupdate -expand -group dimm_model /top/dimm/wr_end_d
add wave -noupdate -expand -group dimm_model /top/dimm/act_addr
add wave -noupdate -expand -group dimm_model /top/dimm/row_addr
add wave -noupdate -expand -group dimm_model /top/dimm/cas_addr
add wave -noupdate -expand -group dimm_model /top/dimm/col_addr
add wave -noupdate -expand -group dimm_model /top/dimm/act
add wave -noupdate -expand -group dimm_model /top/dimm/wr
add wave -noupdate -expand -group dimm_model /top/dimm/rd
add wave -noupdate /top/intf/clock_t
add wave -noupdate /top/intf/clock_n
add wave -noupdate /top/ctrl_intf/WR_DELAY
add wave -noupdate /top/ctrl_intf/RD_DELAY
add wave -noupdate /top/dimm/rd_start
add wave -noupdate /top/ctrl_intf/rw_rdy
add wave -noupdate /top/ddr_ctrl/ctrl_state
add wave -noupdate /top/ddr_ctrl/ctrl_next_state
add wave -noupdate /top/ddr_ctrl/dev_busy
add wave -noupdate /top/ctrl_intf/rw_idle
add wave -noupdate /top/ddr_ctrl/refresh_almost
add wave -noupdate /top/ctrl_intf/act_idle
add wave -noupdate /top/ctrl_intf/data_idle
add wave -noupdate /top/ctrl_intf/cas_idle
add wave -noupdate /top/stim/act_cmd
add wave -noupdate -expand /top/stim/data
add wave -noupdate /top/ctrl_intf/rw_proc
add wave -noupdate /top/dimm/read_count
add wave -noupdate /top/dimm/write_count
add wave -noupdate /top/stim/data_count
add wave -noupdate -expand /top/mem_chk/data_c
add wave -noupdate -expand /top/mem_chk/data_t
add wave -noupdate /top/intf/dqs_t
add wave -noupdate /top/intf/dqs_c
add wave -noupdate /top/intf/dq
add wave -noupdate /top/ctrl_intf/dimm_rd
add wave -noupdate /top/mem_chk/data_wr
add wave -noupdate /top/mem_chk/data_rd
add wave -noupdate /top/mem_chk/rd_end
add wave -noupdate /top/mem_chk/raddr
add wave -noupdate -expand /top/mem_chk/data
add wave -noupdate /top/mem_chk/act_cmd
add wave -noupdate /top/burst_data/ctrl_intf/act_rdy
add wave -noupdate -expand /top/burst_data/mem_addr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {202074 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 188
configure wave -valuecolwidth 150
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
WaveRestoreZoom {69750 ps} {332250 ps}
