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
                   input input_data_type data_in,//connect to sim model
                   input logic new_cmd,          //connect to sim model
                   input mode_register_type mode_reg, pre_reg,                   
                   input logic [1:0] rw,
                   input logic mrs_rdy, act_rdy,cas_rdy,rw_rdy, 
                   input logic pre_rdy, des_rdy,zqcl_rdy,refresh_rdy,
                   output mem_addr_type mem_addr_out, //connect to ACT module
                   output int RD_DELAY, WR_DELAY 
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
   
   //timing paramters
   int BL,CL, CWL, AL, RPRE, WPRE, tCCD;
   
   //each act command, the data is placed into 3 separate queues for act, cas,
   // rw data.
   always @(intf.reset_n, act_rdy,cas_rdy,rw_rdy,mrs_rdy,rw_rdy,
            pre_rdy, zqcl_rdy,des_rdy,refresh_rdy )
   
   begin
      if (!intf.reset_n) begin
         mem_addr <= '1;
         rw_queue.delete();
         cas_queue.delete();
         
         end
      else begin    
        //set cmd nop
        cmd_nop.cmd            = NOP;
        cmd_nop.cmd_data.rw    = 2'b00;
        cmd_nop.cmd_data.addr  = '1;
             
        if (act_rdy) begin
           cmd_out.cmd                = ACT;   
           cmd_out.cmd_data.rw        = 2'b00; 
           cmd_out.cmd_data.addr      = mem_addr;
        
           cas_in.addr     = mem_addr;
           cas_in.rw       = data_in.rw;
           rw_in.data_wr   = data_in.data_wr; 
           rw_in.rw        = data_in.rw;
           rw_in.preamble  = WPRE;
           rw_in.burst_length = BL;
        
           //act_queue        = {act_queue, mem_addr};
           //stored the sequence command in queues 
           cas_queue        = {cas_queue, cas_in};
           rw_queue         = {rw_queue, rw_in};
           end;
        
        if (cas_rdy) begin 
           cas_out = cas_queue.pop_front();
           cmd_out.cmd_data    = cas_out; 
           if (rw == 2'b01)  
               cmd_out.cmd     = CAS_R;  
           else if (rw == 2'b01)
               cmd_out.cmd     = CAS_W;        
           else
               cmd_out.cmd     = NOP;            
           end
          
        if (rw_rdy) begin
           rw_out = rw_queue.pop_front();
           end   
         
        if (mrs_rdy) begin
           cmd_out.cmd           = MRS;
           cmd_out.cmd_data.addr = {mode_reg, 10'b1};
           end
         
         if (des_rdy) begin  
           cmd_out.cmd           = DES;
           cmd_out.cmd_data.addr ={mode_reg, 10'b1};
           end
         
         if (pre_rdy) begin  
           cmd_out.cmd           = PRE;
           cmd_out.cmd_data.addr = {mode_reg, 10'b1};
           end
         
         if (refresh_rdy) begin
           cmd_out.cmd           = REF;
           cmd_out.cmd_data.addr = '1;
           end   
         
         if (zqcl_rdy) begin
           cmd_out.cmd           = ZQCL;
           cmd_out.cmd_data.addr = {mode_reg, 10'b1};
           end   
         end    

   end
   
   //decode the timing data set in the MRS
   always @(mrs_rdy)
   begin
       case (mode_reg [17:15])
           //MR0: capture CL and BL
           3'b000: begin
              if (int'(mode_reg[6:3]) < 12) 
                  BL= 9 + int'(mode_reg [6:3]); //9-24 clock cycles
                             
              if (int'(mode_reg[1:0]) == 2)
                  BL = 4;
              else
                  BL = 8;  
              end
           
           //MR1: capture AL   
           3'b001: begin  
              if ((int'(mode_reg[4:3]) == 1)||
                  (int'(mode_reg[4:3]) == 2))
                 AL = CL - int'(mode_reg[4:3]);
              else  
                 AL = 0;
              end
               
           //MR2: capture CWL
           3'b010: begin
              if (int' (mode_reg[5:3]) < 9) 
                 CWL = 9 + int'(mode_reg[5:3]);
              end
       
           //MR4: capture preamble
           3'b100: begin
               RPRE = int'(mode_reg[11]);
               WPRE = int'(mode_reg[12]);
               end
               
           //MR6: CAS-CAS delay
           3'b110: begin 
               tCCD = 4 + int'(mode_reg[12:10]);
               end  
                       
       endcase
                        
   end
   
   //timing calculate
    assign RD_DELAY = CL + AL - RPRE;
    assign WR_DELAY = CWL + AL - WPRE;

      //get method to send activate command
   always_ff @(intf.clock_t)
   begin
      if ((rw_rdy) && (rw_out.rw == 2'b10))
         intf.set_strobe_pins (.data(rw_out));
   end;
         
   //get method to send activate command
   always_ff @(intf.clock_t)
   begin
      if ((act_rdy)||(cas_rdy) ||(mrs_rdy) ||(refresh_rdy) ||
          (des_rdy)||(zqcl_rdy) ||(pre_rdy))          
        intf.set_cmd_pins(.command(cmd_out));
      else
        intf.set_cmd_pins(.command(cmd_nop));  
   end
   
  always @ (new_cmd)
  begin
    if (new_cmd == 1'b1)
      map_addr (.addr(data_in.physical_addr), 
                .idx_array(map_array),
                .mem_addr(mem_addr));
      mem_addr_out = mem_addr;          
  end                
   
  function automatic void map_addr (input [ADDR_WIDTH -1:0] addr, int idx_array[],
                            output logic [TA_WIDTH -1 :0] mem_addr );              
   foreach (idx_array[i]) 
        mem_addr[i] = addr[idx_array[i]];
   endfunction;             
                  
endmodule
