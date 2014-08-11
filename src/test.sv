
`include "ddr_package.pkg"

module top;
timeunit 10ps;
timeprecision 1ps;


input_data_type data_in;
logic act_cmd;
logic mrs_update, w_pre, r_pre;
logic [1:0] burst_length,al_dly;
int cas_dly, wr_dly, rd_dly;
logic dev_busy;


   //testing variables
   DDR_INTERFACE intf();
   CTRL_INTERFACE ctrl_intf();
   CHECKER C1(.intf(intf),.ctrl_intf(ctrl_intf));
   DIMM_MODEL dimm(.intf(intf),
                   .ctrl_intf(ctrl_intf));
   DDR_CLOCK ddr_clock (.intf(intf));                
                   
   DDR_CONTROLLER ddr_ctrl (.intf(intf),
                            .ctrl_intf(ctrl_intf),
                            .mrs_update(mrs_update),
                            .mrs_bl(burst_length),
                            .dev_busy(dev_busy));
    BURST_ACT burst_act(.intf( intf),
                  .ctrl_intf( ctrl_intf),
                  .act_cmd (act_cmd));
                  
    BURST_DATA burst_data (.intf( intf),
                           .ctrl_intf(ctrl_intf),
                           .data_in(data_in),//connect to sim model
                           .act_cmd (act_cmd));     
  
   BURST_RW burst_rw(.intf(intf),
                    .ctrl_intf(ctrl_intf));

  BURST_CAS burst_cas(.intf(intf),
                    .ctrl_intf(ctrl_intf));                    
   BURST_CONF burst_conf (.intf(intf),
                          .ctrl_intf(ctrl_intf),                   
                    .w_pre(w_pre),
                    .r_pre(r_pre),
                    .burst_length (burst_length),
                    .al_dly(al_dly),
                    .cas_dly(cas_dly),
                    .wr_dly(wr_dly),
                    .rd_dly(rd_dly));
    
  Rand_Stimulus  stim(.intf(intf),
                  .ctrl_intf(ctrl_intf),
                  .dev_busy(dev_busy),
                  .data(data_in),
                  .act_cmd(act_cmd));
                 
  MEMORY_CHECK mem_chk(.intf(intf),
                       .ctrl_intf(ctrl_intf),
                       .data(data_in),
                       .act_cmd(act_cmd));

                
   //DDR_TOP ddr_top (.intf(intf),
   //                 .data_in(data_in),
   //                 .act_cmd(act_cmd),
   //                 .mrs_update(mrs_update),
   //                 .w_pre(w_pre),
   //                 .r_pre(r_pre),
   //                 .burst_length (burst_length),
   //                 .al_dly(al_dly),
   //                 .cas_dly(cas_dly),
   //                 .wr_dly(wr_dly),
   //                 .rd_dly(rd_dly),
   //                 .dev_busy(dev_busy));
   
   
 
initial
begin
#0
  intf.reset_n <= 'X;
  w_pre   <= 1'b1;
  r_pre   <= 1'b1;
  burst_length <= 2'b10;
  al_dly   <= 0;
  cas_dly  <= 4;
  wr_dly   <= 10;
  rd_dly   <= 13;
  //intf.reset_n <= 1'b1;
  //act_cmd <= 1'b0;
  mrs_update <= 1'b0;
  #200ns
  intf.reset_n <= 1'b0;
  #200ns
  intf.reset_n <= 1'b1;
  #300ns
  //force burst_act.rw_proc  1'b0;
//  @ (posedge intf.clock_n) act_cmd <= 1'b1;
//  data_in.physical_addr            <= 32'h2000a011;
//  data_in.data_wr                  <= 64'h0000a0110000a011;
//  data_in.rw                       <= WRITE;
  
 // @ (posedge intf.clock_n) act_cmd <= 1'b0;
 // repeat (8) @ (posedge intf.clock_n); act_cmd <= 1'b1;
 // data_in.physical_addr          <= 32'h2000a051;
 // data_in.data_wr                  <= 64'h0000a0110000a012;
 // data_in.rw                       <= WRITE;
 // @ (posedge intf.clock_n) act_cmd <= 1'b0;
 // repeat (8) @ (posedge intf.clock_n); act_cmd <= 1'b1;
 // data_in.physical_addr          <= 32'h2000a011;
 // data_in.data_wr                  <= 64'h0000a0110000a013;
 // data_in.rw                       <= READ;
 //  @ (posedge intf.clock_n) act_cmd <= 1'b0;
 // repeat (8) @ (posedge intf.clock_n); act_cmd <= 1'b1;
 // data_in.physical_addr          <= 32'h3000c021;
 // data_in.data_wr                  <= 64'h0000a0110000a014;
//  data_in.rw                       <= WRITE;
//   @ (posedge intf.clock_n) act_cmd <= 1'b0;
//     repeat (50) @ (posedge intf.clock_n); act_cmd <= 1'b1;
//  data_in.physical_addr          <= 32'h3000c021;
//  data_in.data_wr                  <= 64'h0000a0110000a015;
//  data_in.rw                       <= READ;
//   @ (posedge intf.clock_n) act_cmd <= 1'b0;
  #1000ns
  
  $stop;
end
endmodule
