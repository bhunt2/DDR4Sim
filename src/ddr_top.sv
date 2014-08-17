
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
               TB_INTERFACE tb_intf);
parameter tCCD        = 4;
parameter tCAS_W       = 10;
parameter tCAS_R       = 13;
parameter W_PRE       = 1'b1;
parameter R_PRE       = 1'b1;
parameter BURST_LENGTH= 2'b10;
parameter AL_DLY      = 2'b00;

//the following assignments are for test bench
assign tb_intf.rw_proc  = ctrl_intf.rw_proc;
assign tb_intf.dev_rd   = ctrl_intf.rw_rdy;
assign tb_intf.next_cmd = ctrl_intf.act_idle;
assign tb_intf.dev_rw   = ctrl_intf.dimm_rd;
assign tb_intf.BL       = ctrl_intf.BL;
assign tb_intf.RD_PRE   = ctrl_intf.RD_PRE;
assign tb_intf.no_act_rdy= ctrl_intf.no_act_rdy;
assign tb_intf.act_addr = ctrl_intf.mem_addr;

CTRL_INTERFACE ctrl_intf();

BURST_ACT burst_act (.intf(intf),
                     .ctrl_intf(ctrl_intf),
                     .tb_intf(tb_intf));
                  
BURST_DATA burst_data(.intf(intf),
                      .ctrl_intf(ctrl_intf), 
                      .tb_intf(tb_intf));
                             
BURST_CAS burst_cas(.intf(intf),
                    .ctrl_intf(ctrl_intf));

BURST_RW burst_rw(.intf(intf),
                  .ctrl_intf(ctrl_intf));                 

DDR_CONTROLLER ddr_controller (.intf(intf),
                               .ctrl_intf(ctrl_intf),
                               .tb_intf(tb_intf));
                       
BURST_CONF #(.tCCD(4), 
             .tCAS_W(10),
             .tCAS_R(13),
             .W_PRE(1'b1),
             .R_PRE(1'b1),
             .BURST_LENGTH(2'b00),
             .AL_DLY(2'b00)) burst_conf(.intf(intf),
                                    .ctrl_intf(ctrl_intf));
                                    
ASSERTION_CHECK assertion_check #(.tCCD(4), 
                                  .tCAS_W(10),
                                  .tCAS_R(13),
                                  .W_PRE(1'b1),
                                  .R_PRE(1'b1),
                                  .BURST_LENGTH(2'b00),
                                  .AL_DLY(2'b00))(.intf(intf));                                   

endmodule
