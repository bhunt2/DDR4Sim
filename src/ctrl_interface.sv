///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: CTRL_INTERFACE.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/05/2014
//
// DESCRIPTION:  The module defines all signals connect between the sub-blocks
//               of ddr controller.
//
/////////////////////////////////////////////////////////////////////////////// 

`include "ddr_package.pkg"                           
                  
interface CTRL_INTERFACE;   

mode_register_type mode_reg, pre_reg, mrs_update_cmd, mr0;
mem_addr_type mem_addr;
logic mrs_rdy, act_rdy, cas_rdy, rw_rdy, mrs_update_rdy;
logic zqcl_rdy, refresh_rdy, des_rdy, pre_rdy;
logic [1:0] rw, act_rw, cas_rw, dimm_rd; 
logic config_done,act_idle, rw_idle, rw_proc, data_idle, cas_idle, rw_done;
int WR_DELAY, RD_DELAY, CL,CWL,BL,RD_PRE,WR_PRE,tCCD;

endinterface                  
