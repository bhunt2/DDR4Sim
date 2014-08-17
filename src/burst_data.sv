///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_DATA.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/01/2014
//
// DESCRIPTION:  The module is data central to setup the addr/data/command for
// set_cmd_pins() method, which is to translate these commands to pin-level 
// signals, and set_strobe_pins() and set_wdata_pin(), which are a pair of 
// methods to setup the DQS and DQ pin for write data.
//
// The module captures the stimulus input and queues in two separate queues, one
// for Cas command and Write data as well as data initialized in MRS registers
// PreCharge, Refresh. When the commands ready, the data/addr/command are 
// assigned to user typedef command_type or rw_data_type for executing the methods
// 
// The memory_map() is to translate physical addr to topological address.
// Capture the data in MRS register for some of timing parameters.
//
// Note: use clock_t as main clock
//
///////////////////////////////////////////////////////////////////////////////

`include "ddr_package.pkg"

//note: use clock_t as main clock

 
module BURST_DATA (DDR_INTERFACE intf,
                   CTRL_INTERFACE ctrl_intf,
                   TB_INTERFACE tb_intf);

   //use the mapping table in hw 2 - and assume bit 28th as channel addr
   int map_array [] = '{3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,
                        23,24,25,26,17,28,29,30,31};
   
   cas_data_type cas_in, cas_out;
   cas_data_type cas_queue[$];
   
   rw_data_type  rw_in,rw_out,rw_out_temp;
   rw_data_type  rw_queue[$];
   
   mem_addr_type mem_addr;
   command_type  cmd_out,cmd_nop,act_cmd_out;
   
   //timing paramters
   int AL, RPRE, WPRE;
   
   //delay signal
   bit act_cmd_d;

//Per Act command, the data/addr are queued is separate queue while waiting
//for execute.

always @  (intf.reset_n, ctrl_intf.act_rdy, ctrl_intf.no_act_rdy)
   
begin
  if (!intf.reset_n) begin
     rw_queue.delete();
     cas_queue.delete();      
  end
  else begin    

     //set cmd nop
     cmd_nop.cmd            = NOP;
     cmd_nop.cmd_data.rw    = 2'b00;
     cmd_nop.cmd_data.addr  = '1;
             
     if ((ctrl_intf.act_rdy) ||
         (ctrl_intf.no_act_rdy)) begin
         
         cas_in.addr                = mem_addr;
         cas_in.rw                  = tb_intf.data_in.rw;
         rw_in.data_wr              = tb_intf.data_in.data_wr; 
         rw_in.rw                   = tb_intf.data_in.rw;
         rw_in.preamble             = WPRE;
         rw_in.burst_length         = ctrl_intf.BL;
        
         //place addr/data in queues 
         cas_queue                  = {cas_queue, cas_in};
         rw_queue                   = {rw_queue, rw_in};
      end
   end   
end       

//pop out the Col address when CAS Ready

always @(posedge ctrl_intf.cas_rdy)
begin
    act_cmd_out = cas_queue.pop_front;
end 

//pop out the write data when RW Ready

always @(posedge ctrl_intf.rw_rdy)
begin
    rw_out_temp = rw_queue.pop_front;
end 
       
//the procedure block is to setup the data/addr/commands into a
//type define variables for set_cmd_pins() method when individual command 
//ready.

always @  (ctrl_intf.act_rdy, ctrl_intf.no_act_rdy,
           ctrl_intf.cas_rdy,ctrl_intf.rw_rdy,
           ctrl_intf.mrs_rdy, ctrl_intf.rw_rdy, ctrl_intf.pre_rdy, 
           ctrl_intf.zqcl_rdy, ctrl_intf.des_rdy, ctrl_intf.refresh_rdy ) 
begin         

      if ((ctrl_intf.act_rdy) ||
         (ctrl_intf.no_act_rdy)) begin
         
         cmd_out.cmd                = ACT;   
         cmd_out.cmd_data.rw        = 2'b00; 
         cmd_out.cmd_data.addr      = mem_addr;              
      end
      if (ctrl_intf.cas_rdy) begin 
         cmd_out.cmd_data = act_cmd_out;
         if (cmd_out.cmd_data.rw == READ)  
            cmd_out.cmd   = CAS_R;  
         else if (cmd_out.cmd_data.rw == WRITE)
            cmd_out.cmd   = CAS_W;        
         else
            cmd_out.cmd   = NOP;            
      end
          
      if (ctrl_intf.rw_rdy) begin
         rw_out            = rw_out_temp;
         ctrl_intf.dimm_rd = rw_out.rw;
      end   
          
       if (ctrl_intf.mrs_rdy) begin
          cmd_out.cmd           = MRS;
          cmd_out.cmd_data.addr = {ctrl_intf.mode_reg, 10'b1};
       end
         
      if (ctrl_intf.des_rdy) begin  
         cmd_out.cmd           = DES;
         cmd_out.cmd_data.addr ={ctrl_intf.mode_reg, 10'b1};
      end
         
      if (ctrl_intf.pre_rdy) begin  
         cmd_out.cmd           = PRE;
         cmd_out.cmd_data.addr = {ctrl_intf.pre_reg, 10'b1};
      end
         
      if (ctrl_intf.refresh_rdy) begin
         cmd_out.cmd           = REF;
         cmd_out.cmd_data.addr = '1;
      end   
         
      if (ctrl_intf.mrs_update_rdy) begin
         cmd_out.cmd           = MRS;
         cmd_out.cmd_data.addr = {ctrl_intf.mrs_update_rdy, 10'b1};
      end
         
      if (ctrl_intf.zqcl_rdy) begin
         cmd_out.cmd           = ZQCL;
         cmd_out.cmd_data.addr = {ctrl_intf.mode_reg, 10'b1};
      end   
end
   
//captures the timing data set in the MRS registers

always @(ctrl_intf.mrs_rdy)
begin
   case (ctrl_intf.mode_reg [17:15])
   //MR0: capture CL and BL
   3'b000: begin
       if (int'(ctrl_intf.mode_reg[6:3]) < 12) 
          ctrl_intf.CL= 9 + int'(ctrl_intf.mode_reg [6:3]); //9-24 clock cycles                    
       if (ctrl_intf.mode_reg[1:0] === 2'b10)
          ctrl_intf.BL = 4;
       else
          ctrl_intf.BL = 8;  
       end
           
   //MR1: capture AL   
   3'b001: begin  
       if ((int'(ctrl_intf.mode_reg[4:3]) == 1)||
           (int'(ctrl_intf.mode_reg[4:3]) == 2))
           AL = ctrl_intf.CL - int'(ctrl_intf.mode_reg[4:3]);
       else  
           AL = 0;
       end
               
   //MR2: capture CWL
   3'b010: begin
        if (int' (ctrl_intf.mode_reg[5:3]) < 7) 
           ctrl_intf.CWL = 9 + int'(ctrl_intf.mode_reg[5:3]);
        end
       
   //MR4: capture preamble
   3'b100: begin
        RPRE = int'(ctrl_intf.mode_reg[11])+ 1;
        WPRE = int'(ctrl_intf.mode_reg[12])+ 1;
        ctrl_intf.RD_PRE = RPRE;
        ctrl_intf.WR_PRE = WPRE;
   end
               
   //MR6: CAS-CAS delay
   3'b110: begin 
        ctrl_intf.tCCD = 4 + int'(ctrl_intf.mode_reg[12:10]);
   end                         
   endcase                        
end
   
//timing calculate
assign ctrl_intf.RD_DELAY = ctrl_intf.CL  + AL - RPRE;
assign ctrl_intf.WR_DELAY = ctrl_intf.CWL + AL - WPRE;

//call methods to send strobe pins and write data data out
//join pork for these tasks

always_ff @(intf.clock_t)
begin
   if ((ctrl_intf.rw_rdy) && (rw_out.rw == WRITE))begin
   fork
      intf.set_strobe_pins (.data(rw_out));
      intf.set_wdata_pins (.data(rw_out));
   join   
   end
end
     
     
            
// method to send out all the command when it ready.

always_ff @(intf.clock_t)
begin
   if ((ctrl_intf.act_rdy) ||(ctrl_intf.cas_rdy)      ||
       (ctrl_intf.mrs_rdy) ||(ctrl_intf.refresh_rdy)  || 
       (ctrl_intf.mrs_update_rdy)||(ctrl_intf.des_rdy)||
       (ctrl_intf.zqcl_rdy) ||(ctrl_intf.pre_rdy))          
      intf.set_cmd_pins(.command(cmd_out));
   else
      intf.set_cmd_pins(.command(cmd_nop));  
end
   

always_ff @(intf.clock_t)
begin
   act_cmd_d <= tb_intf.act_cmd;
   
end

//call function map address and decode the stimulus (input) to DDR controller
always @ (act_cmd_d)
begin
   if (act_cmd_d) begin
      map_addr (.addr(tb_intf.data_in.physical_addr), 
                .idx_array(map_array),
                .mem_addr(mem_addr));
      ctrl_intf.mem_addr     = mem_addr;  
      ctrl_intf.rw           = tb_intf.data_in.rw;  
   end       
end                
   
//function to covert the physical addr to topological addr
//used homework #3

function automatic void map_addr (input [ADDR_WIDTH -1:0] addr, int idx_array[],
                                  output logic [TA_WIDTH -1 :0] mem_addr );              
   foreach (idx_array[i]) 
        mem_addr[i] = addr[idx_array[i]];
endfunction;             
                  
endmodule
