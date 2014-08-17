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
                  TB_INTERFACE   tb_intf);
                 

act_fsm_type act_state, act_next_state;
int act_counter;
logic clear_act_counter;
   
logic hit = 1'b0;        //same bank and row
logic miss= 1'b0;        //same bank different row
logic bank_ini = 1'b1;   //signal to start initialized bank_activated after reset
   
int pre_extra_cycles;
logic [1:0] request;
logic [NUMBER_BANK-1:0] [RA_WIDTH -1:0] bank_activated = 'x;
   
command_type pre_command;
logic act_rdy, act_rdy_d,act_tmp;
logic no_act, no_act_d, no_act_tmp;
logic cas_d, rw_d;
   
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
   else begin
      act_state <= act_next_state;
      no_act_d  <= no_act;
      act_rdy_d <= act_rdy;
      rw_d      <= ctrl_intf.rw_rdy;
      cas_d     <= ctrl_intf.cas_rdy;
   end   
end
  
always_ff @(posedge intf.clock_t)
begin
    ctrl_intf.act_rdy    <= act_tmp;
    ctrl_intf.no_act_rdy <= no_act_tmp;
end

   
always_comb
begin
    if (((no_act   == 1'b1) && (ctrl_intf.cas_rdy == 1'b1)) ||
        ((no_act_d == 1'b1) && (cas_d             == 1'b1)))
       no_act_tmp  <= no_act_d;
    else   
       no_act_tmp <= no_act;
end
    
always_comb
begin
    if (((act_rdy   == 1'b1) && (ctrl_intf.cas_rdy == 1'b1)) ||
        ((act_rdy_d == 1'b1) && (cas_d             == 1'b1)))
       act_tmp   <= act_rdy_d;
    else   
       act_tmp   <= act_rdy;
end
      
   
always_comb
begin
   if (!intf.reset_n) begin 
      act_next_state     <= ACT_IDLE;
      clear_act_counter  <= 1'b1;
      ctrl_intf.act_idle <= 1'b0;
      act_rdy            <= 1'b0;
      no_act             <= 1'b0;
      bank_ini           = 1'b1;
      bank_activated_chk();         
   end
   else begin
      case (act_state)         
      ACT_IDLE: begin
         bank_ini           = 1'b0;
         ctrl_intf.act_idle <= 1'b1;
         ctrl_intf.pre_rdy  <= 1'b0;
         act_rdy            <= 1'b0;
         no_act             <= 1'b0;
         if ((tb_intf.act_cmd) && (ctrl_intf.rw_proc)) begin  
            act_next_state <= ACT_WAIT_STATE;
            bank_activated_chk();               
         end   
      end
              
      ACT_WAIT_STATE: begin  
         clear_act_counter    <= 1'b0;  
         ctrl_intf.act_idle   <= 1'b0;
         no_act               <= 1'b0;
         act_rdy              <= 1'b0;
               
         if ((act_counter == ACT_DELAY) && (hit)) begin 
               act_next_state       <= ACT_CAS;  
               no_act               <= 1'b1;
               ctrl_intf.act_rw     <= ctrl_intf.rw;
         end
         else if ((act_counter == ACT_DELAY) && (miss))
              act_next_state <= PRE_WAIT_DATA;
         else if ((act_counter == ACT_DELAY) && (!hit) && (!miss))
         begin
              act_next_state    <= ACT_CMD;
              act_rdy           <= 1'b1;
              ctrl_intf.act_rw  <= ctrl_intf.rw;                  
         end   
      end
         
      ACT_CMD: begin
           clear_act_counter    <= 1'b1;  
           act_rdy              <= 1'b0; 
           act_next_state       <= ACT_IDLE;
      end
             
         //skip the activate command.
      ACT_CAS: begin
         clear_act_counter    <= 1'b1;  
         no_act               <= 1'b0;
         act_next_state       <= ACT_IDLE;         
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
            act_rdy           <= 1'b1;
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
//previous CAS was write then WTP = WL+4+WR
     
function void pre_extra_wait();
begin
   if (request == READ) 
      pre_extra_cycles = tRTP;    
   else if (request == WRITE)  
      pre_extra_cycles = ctrl_intf.WR_DELAY + tWR + 4;  
   end                        
endfunction 
     
endmodule
