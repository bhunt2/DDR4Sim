
`include "ddr_package.pkg"

module top;
timeunit 10ps;
timeprecision 1ps;


//input_data_type data_in;
//logic act_cmd;
//int BL, RD_PRE;
logic mrs_update, w_pre, r_pre;
logic [1:0] burst_length,al_dly;
int cas_dly, wr_dly, rd_dly;
//logic [1:0] dev_rw;
//logic dev_busy, next_cmd, dev_rd;
logic test;


   //testing variables
  DDR_INTERFACE intf();
  CHECKER c1(.intf(intf));
  DDR_CLOCK ddr_clock (.intf(intf));   
  TB_INTERFACE tb_intf();             
    
  Rand_Stimulus  stim(.intf(intf),
                      .tb_intf(tb_intf),
                      .test(test)); 
 //                 .next_cmd(next_cmd),
 //                 .dev_busy(dev_busy),
 //                 .data(data_in),
 //                 .act_cmd(act_cmd));
                 
  MEMORY_CHECK mem_chk(.intf(intf),
                       .tb_intf(tb_intf)); 

//                       .BL(BL),
//                       .dev_rw(dev_rw),
//                       .data(data_in),
//                       .act_cmd(act_cmd));

  DIMM_MODEL dimm(.intf(intf),
                  .tb_intf(tb_intf));

//                   .BL(BL),
//                   .RD_PRE(RD_PRE),
//                   .dev_rd(dev_rd),
//                   .dev_rw(dev_rw));

  DDR_TOP ddr_top (.intf(intf),
                   .tb_intf(tb_intf),
                   .test(test),
//                    .data_in(data_in),
//                    .act_cmd(act_cmd),
                    .mrs_update(mrs_update),
                    .w_pre(w_pre),
                    .r_pre(r_pre),
                    .burst_length (burst_length),
                    .al_dly(al_dly),
                    .cas_dly(cas_dly),
                    .wr_dly(wr_dly),
                    .rd_dly(rd_dly)
//                    .BL(BL),
//                    .RD_PRE(RD_PRE),
//                    .dev_rd(dev_rd),
//                    .dev_busy(dev_busy),
//                    .dev_rw(dev_rw),
//                    .next_cmd(next_cmd)
                    );
   
   
 
initial
begin
#0
  intf.reset_n <= 'X;
  w_pre   <= 1'b1;
  r_pre   <= 1'b1;
  burst_length <= 2'b00;
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
