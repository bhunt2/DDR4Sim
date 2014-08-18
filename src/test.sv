///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: TB_TOP.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/07/2014
//
// DESCRIPTION:  This is test bench top module
//
/////////////////////////////////////////////////////////////////////////////// 

`include "ddr_package.pkg"

module top;
timeunit 10ps;
timeprecision 1ps;


  //DDR4 Interface
  DDR_INTERFACE intf();
  TB_INTERFACE tb_intf();             
  DDR_CLOCK ddr_clock (.intf(intf));   

  //module generates the random stimulus
  Rand_Stimulus  stim(.intf(intf),
                      .tb_intf(tb_intf)); 
  
  //monitors Read and Write transactions for DDR4
  MEMORY_CHECK mem_chk(.intf(intf),
                       .tb_intf(tb_intf)); 

  //DDR4 Dimm Behavior Model
  DIMM_MODEL dimm(.intf(intf),
                  .tb_intf(tb_intf));

  //DDR4 Controller Behavior Model
  DDR_TOP #(.tCCD (4),                    
            .tCAS_W(10),
            .tCAS_R(13),
            .W_PRE(1'b1),
            .R_PRE(1'b1),
            .BURST_LENGTH(2'b01),     //'10 for burst length 4, else 8
            .AL_DLY(2'b00))ddr_top(.intf(intf),
                                   .tb_intf(tb_intf));
//set the reset 
initial 
begin
intf.reset_n <= 'x;
#100ns;
intf.reset_n <= 1'b0;
#200ns;
intf.reset_n <= 1'b1;
#1000ns
$stop;
end                               
 
endmodule
