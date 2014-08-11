///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: TB_INTERFACE.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/07/2014
//
// DESCRIPTION:  The module defines all signals connect between DIMM model,
//               memory checker, and ddr controller
//
/////////////////////////////////////////////////////////////////////////////// 

`include "ddr_package.pkg"                           
                  
interface TB_INTERFACE;   

input_data_type data_in;
logic act_cmd;
int BL, RD_PRE;
logic dev_busy, next_cmd, dev_rd;
logic [1:0] dev_rw;

endinterface                  
