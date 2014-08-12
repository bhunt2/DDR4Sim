///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: DDR_CLOCK.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/09/2014
//
// DESCRIPTION:  The module generates the differential clocks for DDR Memory 
// and internal clk with double freq to align the data to strobe pins
//
///////////////////////////////////////////////////////////////////////////////  
//simple clock resource
 
`include "ddr_package.pkg"

module DDR_CLOCK(DDR_INTERFACE intf); 
timeunit 10ps;
timeprecision 1ps;


initial
begin 
   intf.clock_n = FALSE;
   forever #HALF_PERIOD intf.clock_n = ~intf.clock_n;
end   

//differential clock 
initial
begin 
   intf.clock_t = TRUE;
   forever #HALF_PERIOD intf.clock_t = ~intf.clock_t;
end 
   
//write clock with 90 phase shift, double freq to clock_n
initial
begin
   intf.clock_r = FALSE;
   #QUARTER_PERIOD;
   forever #QUARTER_PERIOD intf.clock_r = ~intf.clock_r;
end    
endmodule   
