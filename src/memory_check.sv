///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: DIMM_CHECKER.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/07/2014
//
// DESCRIPTION:  The module implements memory check.  Storing the write data into
// associate array used memory addr as index. Capture read data and check against
// the array. 
// 
///////////////////////////////////////////////////////////////////////////////

`include "ddr_package.pkg"

module MEMORY_CHECK (DDR_INTERFACE intf,
                     CTRL_INTERFACE ctrl_intf,
                     input input_data_type data,
                     input logic act_cmd);


data_type       write_mem [dimm_addr_type];
logic [4:0][7:0] data_c,data_t;
dimm_addr_type  rd_addr_stored[$];
dimm_addr_type  raddr;
bit             rd_end, rd_end_d;
bit [4:0]cycle_8 = 5'b10000;
bit [2:0]cycle_4 = 5'b100;
bit cycle_8_d    = 1'b1;
bit cycle_4_d    = 1'b1;
bit act_cmd_d    = 1'b0;

data_type data_wr, data_rd;
int file;

//detect end of write cycle for both BL
assign rd_end = (((cycle_8[4]) && (!cycle_8_d)) ||
                ((cycle_4[2]) && (!cycle_4_d)))? 1'b1:1'b0;

initial 
begin

  file = $fopen("../sim/output.txt","w");
  $fwrite (file, "       Time         Address          Write Data           Read Data\n");
  if(file===0)
   	$display("Error: Can not open the file."); 
end

always @ (act_cmd_d, rd_end, intf.reset_n)
begin
    bit [28:0] index;
    if (!intf.reset_n)
       rd_addr_stored.delete;
    
    if  (act_cmd_d) begin
       if (data.rw == WRITE) begin
           index   = data.physical_addr[31:3];
           write_mem[index] = data.data_wr;
       end else  //store the read address
           rd_addr_stored = {rd_addr_stored,data.physical_addr [31:3]};
    end
    
    if (rd_end)
       raddr   = rd_addr_stored.pop_front;            
end  
          

always @(rd_end_d)
begin
   if (rd_end_d) begin
     if (ctrl_intf.BL == 8)
        data_rd = {data_t[4], data_c[3], data_t[3], data_c[2], 
                   data_t[2], data_c[1], data_t[1], data_c[0]};       
     else
        data_rd  = {'0,data_t[4], data_c[4], data_t [3], data_c[3]};
     data_wr = write_mem[raddr];               
     data_check: assert (write_mem[raddr] == data_rd);
     $fwrite(file, "%t  0x%h  0x%h   0x%h\n", $stime, raddr,  data_wr, data_rd);
   end 
end
    
always_ff @ (intf.clock_t)
begin
   act_cmd_d       <= act_cmd;
   rd_end_d       <= rd_end;
   cycle_8_d      <= cycle_8[4];
   cycle_4_d      <= cycle_4[2];
end


//capture data on the negedge 
always_ff @(negedge intf.dqs_t)
begin
   if (ctrl_intf.dimm_rd == READ)  begin
      data_t <= {intf.dq, data_t[4:1]};
      if (ctrl_intf.BL == 8) 
         cycle_8 <= {cycle_8[3:0], cycle_8[4]};
      else
         cycle_4 <= {cycle_4[1:0], cycle_4[2]};     
   end      
end

//capture data on the negedge 
always_ff @(negedge intf.dqs_c)
begin
   if (ctrl_intf.dimm_rd == READ) 
      data_c <= {intf.dq, data_c[4:1]};
end



endmodule
