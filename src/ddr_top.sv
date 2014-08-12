
///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: DDR_TOP.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/052014
//
// DESCRIPTION:  The module is DDR Controller Top Level Module
// 
///////////////////////////////////////////////////////////////////////////////
`include "ddr_package.pkg"

module DDR_TOP(DDR_INTERFACE intf,
               TB_INTERFACE tb_intf,
               output logic test,
//        input input_data_type data_in, 
//        input logic act_cmd,
        input logic mrs_update, w_pre, r_pre, 
        input logic [1:0] burst_length,al_dly,
        input int cas_dly, wr_dly, rd_dly);
//        output int BL, RD_PRE,
//        output logic dev_busy, next_cmd, dev_rd, 
//        output logic [1:0] dev_rw);

assign test = ctrl_intf.rw_proc;
//assign tb_intf.dev_busy = !ctrl_intf.rw_proc;
assign tb_intf.dev_rd   = ctrl_intf.rw_rdy;
assign tb_intf.next_cmd = ctrl_intf.act_idle;
assign tb_intf.dev_rw   = ctrl_intf.dimm_rd;
assign tb_intf.BL       = ctrl_intf.BL;
assign tb_intf.RD_PRE   = ctrl_intf.RD_PRE;

CTRL_INTERFACE ctrl_intf();

BURST_ACT burst_act (.intf(intf),
                     .ctrl_intf(ctrl_intf),
                     .tb_intf(tb_intf)
                    );
                  
BURST_DATA burst_data(.intf(intf),
                      .ctrl_intf(ctrl_intf), 
                      .tb_intf(tb_intf));
//                      .data_in (data_in),
//                      .act_cmd (act_cmd));
                             
BURST_CAS burst_cas(.intf(intf),
                    .ctrl_intf(ctrl_intf));

BURST_RW burst_rw(.intf(intf),
                  .ctrl_intf(ctrl_intf));                 

DDR_CONTROLLER ddr_controller (.intf(intf),
                               .ctrl_intf(ctrl_intf),
                               .tb_intf(tb_intf),
                               .mrs_update(mrs_update),
                               .mrs_bl(burst_length));

                       
BURST_CONF burst_conf(.intf(intf),
                      .ctrl_intf(ctrl_intf),
                      .cas_dly(cas_dly),
                      .wr_dly(wr_dly),
                      .rd_dly(rd_dly),
                      .w_pre(w_pre), 
                      .r_pre(r_pre), 
                      .al_dly(al_dly),
                      .burst_length(burst_length));                         
endmodule
