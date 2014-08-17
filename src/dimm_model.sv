///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: DIMM_MODEL.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/07/2014
//
// DESCRIPTION:  The module implements DIMM that samples the ACT, CAS commands
// to decode the address and perform write/read to associate array. 
// 
/////////////////////////////////////////////////////////////////////////////// 

`include "ddr_package.pkg"

module DIMM_MODEL (DDR_INTERFACE intf,
                   TB_INTERFACE tb_intf);

parameter MRS_C = 5'b01000;
parameter REF_C = 5'b01001;
parameter PRE_C = 5'b01010;
parameter ACT_C = 5'b00;
parameter WR_C  = 5'b01100;
parameter RD_C  = 5'b01101;
parameter NOP_C = 5'b1XXXX;


data_type dimm [dimm_addr_type];
bit [18:0] act_addr_store[$];
bit [9:0]  cas_addr_store[$];
logic [4:0] [7:0] data_t, data_c;
logic [7:0][7:0] data;
bit [4:0]cycle_8 = 5'b10000;
bit [2:0]cycle_4 = 5'b100;
bit cycle_8_d, cycle_4_d;
bit wr_end, wr_end_d;
bit rd_start, rd_start_d, rd_start_dd;


logic [4:0] cmd ='1;
bit mrs,pre,refresh,act,wr,rd,nop,des;
bit [18:0] act_addr, row_addr;
bit [9:0]  cas_addr, col_addr;

bit bg_addr_d, ba_addr_d, we_n_a14_d, addr13_d, bc_n_a12_d, addr11_d, ap_a10_d;
bit act_d, wr_d, rd_d;
bit [9:0] addr9_0_d;
rw_data_type data_out;
int read_count = 0;
int write_count = 0;
int file;
initial 
begin

  file = $fopen("../sim/record.txt","w");
  if(file===0)
   	$display("Error: Can not open the file."); 
end

always_ff @ (posedge intf.clock_t)
begin
   cmd <= {intf.cs_n, intf.act_n, intf.ras_n_a16, intf.cas_n_a15, intf.we_n_a14};
end

//decoding the command 
always_comb
begin
   if (cmd [4:3] === ACT_C) begin
      act <= 1'b1;
      wr  <= 1'b0;
      rd  <= 1'b0;
    end else if (cmd === WR_C) begin
      act <= 1'b0;
      wr  <= 1'b1;
      rd  <= 1'b0;
    end else if (cmd === RD_C) begin
      act <= 1'b0;
      wr  <= 1'b0;
      rd  <= 1'b1;
    end else begin
      act <= 1'b0;
      wr  <= 1'b0;
      rd  <= 1'b0;
    end 
end

//call method for rd data
always_ff @(posedge intf.clock_t)
begin
   if (rd_start_dd)
   fork
      intf.set_strobe_pins(data_out);
      intf.set_rdata_pins (data_out);
   join   
end

//delay signals
always_ff @ (posedge intf.clock_t)
begin
   act_d          <= act;
   wr_d           <= wr;
   rd_d           <= rd;
   cycle_8_d      <= cycle_8[4];
   cycle_4_d      <= cycle_4[2];
   wr_end_d       <= wr_end;
   rd_start_d     <= rd_start;
   rd_start_dd    <= rd_start_d;
end

//detect end of write cycle for both BL
assign wr_end = (((cycle_8[4]) && (!cycle_8_d)) ||
                ((cycle_4[2]) && (!cycle_4_d)))? 1'b1:1'b0;

//create one clock cylce of rd_start               
always_ff @(posedge intf.clock_t)
begin
    rd_start <= ((tb_intf.dev_rd) && (tb_intf.dev_rw == READ));                
end


//capture the row addr
always @(posedge act)
begin
     act_addr ={intf.bg_addr, intf.ba_addr, intf.we_n_a14, intf.addr13,
                intf.bc_n_a12, intf.addr11, intf.ap_a10, intf.addr9_0};
end              

//store and retrieve the row addr
always_ff @(posedge intf.clock_n, negedge intf.reset_n)
begin
   bit [18:0] temp_addr;
    
   if (!intf.reset_n)
       act_addr_store.delete;
   else begin    
   if (act)
      act_addr_store = {act_addr_store, act_addr};   
   else if (tb_intf.no_act_rdy) begin
      temp_addr      = {tb_intf.act_addr.bg_addr,tb_intf.act_addr.ba_addr,tb_intf.act_addr.row_addr};
      act_addr_store = {act_addr_store, temp_addr}; 
   end  
   end      
end

//capture the col addr
always @(posedge wr, posedge rd)
begin
      cas_addr = intf.addr9_0;
end   

//store and retrieve the col addr
always_ff @(posedge intf.clock_n, negedge intf.reset_n)
begin
   if (!intf.reset_n)
       cas_addr_store.delete;
   else begin    
   if ((rd) || (wr))
      cas_addr_store = {cas_addr_store, cas_addr};
//   if ((wr_end || rd_start) &&
//       (act_addr_store.size != 0))      
//      col_addr <= cas_addr_store.pop_front;
   end   
end

always_ff @(posedge intf.clock_n)
begin
   if (((wr_end || rd_start)) &&
       (act_addr_store.size != 0)) begin
      row_addr  = act_addr_store.pop_front;
      col_addr <= cas_addr_store.pop_front;
   end   
end

//capture data on the posedge dqsc_t. Ignore the last on due to twpr
always_ff @(posedge intf.dqs_t)
begin
   if(tb_intf.dev_rw == WRITE) 
      data_t <= {intf.dq, data_t[4:1]};
      
end

//capture data on the dqsc_c. Note ignore the first rising edge for pre_amble 
always_ff @(posedge intf.dqs_c)
begin
   if (tb_intf.dev_rw == WRITE) begin
      data_c <= {intf.dq,data_c[4:1]};
      if (tb_intf.BL == 8) 
         cycle_8 <= {cycle_8[3:0], cycle_8[4]};
      else
         cycle_4 <= {cycle_4[1:0], cycle_4[2]};     
   end      
end

//write data into associate array
always @ (wr_end_d, rd_start_d, intf.reset_n)

begin
   bit [29:0] dimm_index;

   if (!intf.reset_n) begin
      read_count = 0;
      write_count = 0;
      dimm_index  = 0;
   end;   
   
   dimm_index = {row_addr,col_addr};  
   if ((wr_end_d) && (tb_intf.BL == 8))begin
      dimm[{row_addr,col_addr}] = {data_c[4], data_t[3], data_c[3], data_t[2], 
                                   data_c[2], data_t[1], data_c[1], data_t[0]};
      $fwrite(file, "%t  row_Addr: 0x%h col_Addr: 0x%h Wr_Data: 0x%h   \n", 
                  $stime, row_addr, col_addr ,{data_c[4], data_t[3], data_c[3], data_t[2], 
                                      data_c[2], data_t[1], data_c[1], data_t[0]});
       end                               
   else if (wr_end_d) begin
//      $display ("Dimm index write %0x", dimm_index);
        write_count ++;
        dimm[{row_addr,col_addr}] = {data_c[4],data_t[3],data_c[3],data_t[2]} ;   
      $fwrite(file, "%t  row_Addr: 0x%h col_Addr: %0h  Wr_Data: 0x%h   \n", 
                  $stime, row_addr, col_addr ,{data_c[4], data_t[3], data_c[3], data_t[2]});

   end
      
   if ((rd_start_d) && (tb_intf.BL == 8)) begin
//      $display ("Dimm index read %0x", dimm_index);
      data_out.data_wr = dimm[{row_addr,col_addr}];
      data_out.rw      = READ;
      data_out.burst_length = tb_intf.BL;
      data_out.preamble = tb_intf.RD_PRE;
      $fwrite(file, "%t  row_Addr: 0x%h col_Addr: %0h  Rd_Data: 0x%h   \n", 
                  $stime, row_addr, col_addr ,data_out.data_wr);
   end   
   else if (rd_start_d) begin
//      $display ("Dimm index read %0x", dimm_index);
      read_count ++;
      data_out.data_wr[31:0] = dimm[dimm_index];//dimm[{row_addr,col_addr}];  
      data_out.rw            = READ;
      data_out.burst_length  = tb_intf.BL;
      data_out.preamble = tb_intf.RD_PRE;
      $fwrite(file, "%t  row_Addr: 0x%h col_Addr: %0h  Rd_Data: 0x%h   \n", 
                  $stime, row_addr, col_addr ,data_out.data_wr);
   end
end

endmodule
