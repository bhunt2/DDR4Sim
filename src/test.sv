
`include "ddr_package.pkg"

module top;
timeunit 10ps;
timeprecision 1ps;

   //testing variables
   DDR_INTERFACE intf();
   command_type  test_command;
   logic rw_command;
   logic cas_command, data_done, cas_ready;
   logic [1:0] rw_request; 
   

    input_data_type data_in;
    mode_register_type mode_reg;
    logic [1:0] rw;
    logic mrs_rdy, act_rdy, cas_rdy, rw_rdy;
    int RD_DELAY, WR_DELAY;
    rw_data_type data;
    
    BURST_DATA burst_data(.intf(intf),
                          .data_in(data_in),
                          .rw(rw),
                          .mrs_rdy(mrs_rdy),
                          .act_rdy(act_rdy),
                          .cas_rdy(cas_rdy),
                          .rw_rdy(rw_rdy),
                          .RD_DELAY(RD_DELAY),
                          .WR_DELAY(WR_DELAY));        
  
   //BURST_RW burst_rw(.intf(intf),
   //         .rw_cmd(rw_command));
   
   //BURST_CAS burst_cas (.intf(intf),
   //                     .cas_cmd(cas_command),
   //                     .rw_request (rw_request),
   //                     .rw_done (data_done),
   //                     .cas_ready(cas_ready));
            
int cas = 5;
bit [31:0] cas_dly; 
 
initial
begin
#1ns
   $cast(cas_dly,cas);
   #1ns
   $display ("CAS : %d", cas);
   $display ("cas delay: %b", cas_dly[31:0]);
   
   
#1ns
   repeat (4) @ (posedge intf.clock_t); data.burst_length <= 8; data.preamble <= 2;
   data.data_wr <= 64'hFFEEDDCCBBAA7766;
   @ (posedge intf.clock_n) begin
   intf.set_strobe_pins(data);
   intf.set_wdata_pins(data);end
   repeat (5) @ (posedge intf.clock_t); 
end  
initial
begin
#1ns
   repeat (4) @ (posedge intf.clock_t); data.burst_length <= 8; data.preamble <= 2;
   data.data_wr <= 64'hFFEEDDCCBBAA7766;
   @ (posedge intf.clock_n) begin
   
   intf.set_wdata_pins(data);end
   repeat (5) @ (posedge intf.clock_t); 
end   
 
//test rw module
initial
begin
#1ns
   repeat (4) @ (posedge intf.clock_t); cas_command <= 1'b1; rw_request <= READ;
   @ (posedge intf.clock_t); cas_command <= 1'b0; rw_request <= 2'b0;
   repeat (5) @ (posedge intf.clock_t); cas_command <= 1'b1; rw_request <= READ;
   @ (posedge intf.clock_t); cas_command <= 1'b0;rw_request <= 2'b0;
   repeat (6) @ (posedge intf.clock_t); cas_command <= 1'b1;rw_request <= READ;
   @ (posedge intf.clock_t); cas_command <= 1'b0;rw_request <= 2'b0;
   repeat (7) @ (posedge intf.clock_t); cas_command <= 1'b1;rw_request <=READ;
   @ (posedge intf.clock_t); cas_command <= 1'b0;rw_request <= 2'b0;
   repeat (5)@ (posedge intf.clock_t); cas_command <= 1'b1;rw_request <= WRITE;
   
   @ (posedge intf.clock_t); cas_command <= 1'b0;rw_request <= 2'b0;
   repeat (20) @ (posedge intf.clock_t); data_done <= 1'b1;
    @ (posedge intf.clock_t);data_done <= 1'b0;
end; 
   

//test rw module
initial
begin
#3ns
   repeat (4) @ (posedge intf.clock_t); rw_command <= 1'b1;
   @ (posedge intf.clock_t); rw_command <= 1'b0;
   repeat (4) @ (posedge intf.clock_t); rw_command <= 1'b1;
   @ (posedge intf.clock_t); rw_command <= 1'b0;
   repeat (4) @ (posedge intf.clock_t); rw_command <= 1'b1;
   @ (posedge intf.clock_t); rw_command <= 1'b0;
   repeat (4) @ (posedge intf.clock_t); rw_command <= 1'b1;
   @ (posedge intf.clock_t); rw_command <= 1'b0;
   repeat (6)@ (posedge intf.clock_t); rw_command <= 1'b1;
   @ (posedge intf.clock_t); rw_command <= 1'b0;
end; 
   
initial 
begin
#5ns
  //test_command = '{NOP,
  //            2'b01,
  //            2'b11,
  //            14'h54ef,
  //            '1};
  $display ("execute here");  
  repeat (2) @ (posedge intf.clock_t); 
  intf.set_cmd_pins (test_command);
  repeat (1) @ (posedge intf.clock_t); 
              
  //test_command = '{ACT,
  //            2'b01,
  //            2'b11,
  //            14'h57ef,
  //            '1};
  intf.set_cmd_pins (test_command);
  repeat (2) @ (posedge intf.clock_t); 
  $stop;
end
endmodule
