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


  //testing variables
  DDR_INTERFACE intf();
  CHECKER c1(.intf(intf));
  TB_INTERFACE tb_intf();             
  DDR_CLOCK ddr_clock (.intf(intf));   

  Rand_Stimulus  stim(.intf(intf),
                      .tb_intf(tb_intf)); 
                 
  MEMORY_CHECK mem_chk(.intf(intf),
                       .tb_intf(tb_intf)); 


  DIMM_MODEL dimm(.intf(intf),
                  .tb_intf(tb_intf));


  DDR_TOP #(.tCCD (4), 
            .WR_DLY(10),
            .RD_DLY(13),
            .W_PRE(1'b1),
            .R_PRE(1'b1),
            .BURST_LENGTH(2'b00),
            .AL_DLY(2'b00))ddr_top(.intf(intf),
                               .tb_intf(tb_intf));
initial 
begin
intf.reset_n <= 'x;
#100ns;
intf.reset_n <= 1'b0;
#200ns;
intf.reset_n <= 1'b1;
#100us
$stop;
end                               
 
endmodule
