///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_DATA.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/01/2014
//
// DESCRIPTION:  The module is simple of data pipiline for each stage request
// using queues and get method to translate to pin levels
// 
///////////////////////////////////////////////////////////////////////////////

`include "ddr_package.pkg"

//note: use clock_t as main clock

//ASSUM SIMULATE DATA READY 
module BURST_DATA (DDR_INTERFACE intf,
                   input_data_type data_in,
                   input logic act_rdy,cas_rdy,rw_rdy   
                  );

      //use the mapping table in hw 2 - and assume bit 28th as channel addr
   int map_array [] = '{3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,
                        23,24,25,26,17,28,29,30};


   //act_data_type act_data;
   //act_data_type act_queue[$];
   
   cas_data_type cas_in, cas_out;
   cas_data_type cas_queue[$];
   
   rw_data_type  rw_in,rw_out;
   rw_data_type  rw_queue[$];
   
   mem_addr_type mem_addr;
   command_type  cmd_out,cmd_nop;

   //each act command, the data is placed into 3 separate queues for act, cas,
   // rw data.
   always @(intf.reset_n, act_rdy)
   
   begin
      if (!intf.reset_n) begin
         mem_addr <= '1;
         rw_queue.delete();
         cas_queue.delete();
         act_queue.delete();
         end
      else begin    
      //set cmd nop
      cmd_nop.cmd     = NOP;
      cmd_nop.rw      = 2'b00;
      cmd_nop.bg_addr = 1'b1;
      cmd_nop.ba_addr = 1'b1;
      cmd_nop.row_addr= 1'b1;
      cmd_nop.col_addr= 1'b1;

      
      if (act_rdy) begin
        map_addr (.addr(data_in.physical_addr), 
                  .idx_array(map_array),
                  .mem_addr(mem_addr));

        cmd_out.cmd     = ACT;   
        cmd_out.rw      = 2'b00; 
        cmd_out.bg_addr = mem_addr.bg_addr;
        cmd_out.ba_addr = mem_addr.ba_addr;
        cmd_out.row_addr= mem_addr.row_addr;
        cmd_out.col_addr= mem_addr.col_addr;
        
        cas_in.cas_addr = mem_addr;
        cas_in.rw       = data_in.rw;
        rw_in.data_wr   = data_in.data_wr; 
        rw_in.rw        = data_in.rw;
        
        //act_queue        = {act_queue, mem_addr};
        //stored the sequence command in queues 
        cas_queue        = {cas_queue, cas_in};
        rw_queue         = {rw_queue, rw_in};
        end;
        
      if (cas_rdy) begin 
         cas_out = cas_queue.pop_front();
         cmd_out.cmd     = ACT;   
         cmd_out.rw      = cas_out.rw; 
         cmd_out.bg_addr = cas_out.cas_addr.bg_addr;
         cmd_out.ba_addr = cas_out.cas_addr.ba_addr;
         cmd_out.row_addr= cas_out.cas_addr.row_addr;
         cmd_out.col_addr= cas_out.cas_addr.col_addr;
         end
         
      if (rw_rdy) begin
         rw_out = rw_queue.pop_front();
         end    
                  
      end    

   end
   
   //get method to send activate command
   always_ff @(intf.clock_t)
   begin
      if (act_rdy)
        intf.set_cmd_pins(cmd_out);
      else if(cas_rdy)
        intf.set_cmd_pins(cmd_out);
      else 
        intf.set_cmd_pins(cmd_out);  
   end
   
   //get method for write data
   always_ff@(intf.clock_t)
   begin
      if (rw_rdy)
         intf.set_data_pins();
   end 
   
   
  function automatic void map_addr (input [ADDR_WIDTH -1:0] addr, int idx_array[],
                            output logic [TA_WIDTH -1 :0] mem_addr );              
   foreach (idx_array[i]) 
        mem_addr[i] = addr[idx_array[i]];
   endfunction;             
                  
endmodule
