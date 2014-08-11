///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_ACT.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 07/30/2014
//
// DESCRIPTION:  The module implements fsm to control sequence for ACT command
// The module asserts ACT cmd per ACT period if the bank is not activated, or
// send out CAS command if access a same bank and row, or assert PRECHARGE if
// access to same bank, different row. 
// PRECHARGE wait until all data completed, add delay time before assert PRE 
// command, wait for tRP then assert ACT.
// 
///////////////////////////////////////////////////////////////////////////////                       
                  
`include "ddr_package.pkg"

//note: use clock_t as main clock
module BURST_ACT (DDR_INTERFACE intf,
                  CTRL_INTERFACE ctrl_intf,
                  input logic act_cmd
                  );
                  //input logic act_cmd,            //from simulation model
                  //input mem_addr_type mem_addr,
                  //input int WR_DELAY,
                  //input logic rw_proc,           //from controller
                  //input logic data_idle,                            //from rw
                  //input logic cas_rdy, cas_idle, [1:0] rw_request,  //from cas
                  //output mode_register_type pre_reg, pre_rdy,       //PRE cmd
                  //output logic rw_idle, act_rdy);
                  

act_fsm_type act_state, act_next_state;
int act_counter;
logic clear_act_counter;
   
logic hit = 1'b0;    //same bank and row
logic miss= 1'b0;    //same bank different row
logic bank_ini = 1'b1;  //signal to start initialized bank_activated after reset
   
int pre_extra_cycles;
logic [1:0] request;
logic [NUMBER_BANK-1:0] [RA_WIDTH -1:0] bank_activated = 'x;
   
command_type pre_command;
   
//idle when all ACT, CAS, and RW sequence are all idle
always_comb
begin
   ctrl_intf.rw_idle <= ctrl_intf.act_idle && ctrl_intf.cas_idle && ctrl_intf.data_idle;
end
   
//fsm control timing between ACT and data 
always_ff @(posedge intf.clock_t, negedge intf.reset_n)
begin
   if (!intf.reset_n) 
      act_state <= ACT_IDLE;
   else 
      act_state <= act_next_state;
end
   
always_comb
begin
   if (!intf.reset_n) begin 
      act_next_state     <= ACT_IDLE;
      clear_act_counter  <= 1'b1;
      ctrl_intf.act_idle <= 1'b0;
      ctrl_intf.act_rdy  <= 1'b0;
      bank_ini           = 1'b1;
      bank_activated_chk();         
   end
   else begin
      case (act_state)         
      ACT_IDLE: begin
         bank_ini           = 1'b0;
         ctrl_intf.act_idle <= 1'b1;
         ctrl_intf.pre_rdy  <= 1'b0;
         ctrl_intf.act_rdy  <= 1'b0;
         if ((act_cmd) && (ctrl_intf.rw_proc)) begin  //NOTE PUT THE LINE
         //if (act_cmd) begin                             //BACK AFTER DEBUG
            act_next_state <= ACT_WAIT_STATE;
            bank_activated_chk();               
         end   
      end
              
      ACT_WAIT_STATE: begin  
         clear_act_counter  <= 1'b0;  
         ctrl_intf.act_idle <= 1'b0;
               
         if ((act_counter == ACT_DELAY) && (hit)) begin  
            act_next_state   <= ACT_CAS;  
            ctrl_intf.act_rdy <= 1'b1;
            ctrl_intf.act_rw  <= ctrl_intf.rw;
         end
            else if ((act_counter == ACT_DELAY) && (miss))
               act_next_state <= PRE_WAIT_DATA;
            else if ((act_counter == ACT_DELAY) && (!hit) && (!miss))
            begin
               if (ctrl_intf.cas_rdy == 1'b0) begin
                  act_next_state    <= ACT_CMD;
                  ctrl_intf.act_rdy <= 1'b1;
                  ctrl_intf.act_rw  <= ctrl_intf.rw;
               end else   //delay to avoid assert both CAS and ACT in one cycle         
                  act_next_state <= ACT_ONE_DELAY;  
            end
      end             
         
      ACT_ONE_DELAY: begin
         act_next_state    <= ACT_CMD;
         ctrl_intf.act_rdy <= 1'b1;
         ctrl_intf.act_rw  <= ctrl_intf.rw;
      end
            
      ACT_CMD: begin
         clear_act_counter <= 1'b1; 
         ctrl_intf.act_rdy <= 1'b0; 
         act_next_state <= ACT_IDLE;
      end
             
         //skip the activate command.
      ACT_CAS: begin
         ctrl_intf.act_rdy <= 1'b0;
         clear_act_counter <= 1'b1;  
         act_next_state <= ACT_IDLE;
      end
             
           
      PRE_WAIT_DATA: begin
         clear_act_counter <= 1'b1;
         //wait until the previous CAS command completed or idle  
         if (ctrl_intf.cas_idle) begin
            act_next_state <= PRE_WAIT_STATE;
       
            //sample the previous CAS is read or write  
            request <= ctrl_intf.cas_rw;
         end
      end            
            
      PRE_WAIT_STATE: begin   
         clear_act_counter <= 1'b0;
         pre_extra_wait ();
         if (act_counter == pre_extra_cycles) begin
             act_next_state    <= PRE_CMD;
             ctrl_intf.pre_rdy <= 1'b1;
             ctrl_intf.pre_reg <= {ctrl_intf.mem_addr.bg_addr, 
                                   ctrl_intf.mem_addr.ba_addr, 15'b0};
         end
      end
         
      PRE_CMD: begin
         clear_act_counter <= 1'b1;
         ctrl_intf.pre_rdy <= 1'b0;
         act_next_state    <= PRE_IDLE;
      end             
             
      PRE_IDLE: begin
         clear_act_counter <= 1'b0;
         if (act_counter == tRP) begin
            ctrl_intf.act_rdy <= 1'b1;
            ctrl_intf.act_rw  <= ctrl_intf.rw;
            act_next_state    <= ACT_CMD;
         end        
      end
   endcase                   
   end
end
      
    // simple act_counter 
always_ff @(posedge intf.clock_t)
begin
  
  if(clear_act_counter == 1'b1)
     act_counter <= 0;
  else 
     act_counter <= act_counter + 1;
end 
     
function void bank_activated_chk();
begin
   int index;
   static logic [14:0] mem = 'z;
   miss = 1'b0;
   hit  = 1'b0;
  
   index = int'({ctrl_intf.mem_addr.bg_addr,ctrl_intf.mem_addr.ba_addr});
      
   if (bank_ini)
      bank_activated = 'z;
   else begin    
      if (bank_activated[index] == ctrl_intf.mem_addr.row_addr) begin
      //if (mem == ctrl_intf.mem_addr.row_addr) begin
         hit   = 1'b1;
         miss  = 1'b0; 
      end
 
      else begin //if (bank_activated[index] != ctrl_intf.mem_addr.row_addr) begin
           hit = 1'b0;
           if (bank_activated[index] === mem)          //bank not activated           
               miss = 1'b0;
           else 
               miss = 1'b1;       
           bank_activated[index] = ctrl_intf.mem_addr.row_addr;
           end     
      end
   end
endfunction
     
//function to calculate the time delay from previous CAS to precharge.
//previous CAS was read, then RTP =  tRTP
//previous CAS is write then WTP = WL+4+WR
     
function void pre_extra_wait();
begin
   if (request == READ) 
      pre_extra_cycles = tRTP;    
   else if (request == WRITE)  
      pre_extra_cycles = ctrl_intf.WR_DELAY + tWR + 4;  
   end                        
endfunction 
     
endmodule
