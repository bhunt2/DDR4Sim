///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_RW.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 07/29/2014
//
// DESCRIPTION:  The module implements FSM to control write and read timing.  
// The FSM controls the CL and CWL, which are latency between CAS and read,and
// write data, respectively.
// The queues are provided to keep track when CAS occurs while the FSM executing
// the past CAS command. Each time, a CAS pops out of the queue, each CAS in 
// the queue is updated for # cycles has been waited.
//
// Note: use clock_t as main clock
///////////////////////////////////////////////////////////////////////////////                       
                  
`include "ddr_package.pkg"

module BURST_RW (DDR_INTERFACE intf,
                 CTRL_INTERFACE ctrl_intf);

int   DELAY;  
   
rw_fsm_type rw_state, rw_next_state;

logic next_rw;  
logic clear_rw_counter = 1'b0; 
int rw_counter,rw_delay;

//tracking the CAS command occurs
int rw_cmd_trk[$];  
logic [1:0] rw_trk[$];
   
int temp;   
   
//fsm control timing between CAS and data 
always_ff @(posedge intf.clock_t, negedge intf.reset_n)
begin
   if (!intf.reset_n) 
      rw_state <= RW_IDLE;
   else 
      rw_state <= rw_next_state;
end
   
   
//next state generate logic

always_comb
begin
   if (!intf.reset_n) begin 
      rw_next_state     <= RW_IDLE;
      clear_rw_counter  <= 1'b1;
      ctrl_intf.rw_done <= 1'b0;
      ctrl_intf.rw_rdy  <= 1'b0;
   end
   else begin
      case (rw_state)
         RW_IDLE: begin
            ctrl_intf.rw_done    <= 1'b1;
            ctrl_intf.data_idle  <= 1'b1;
            if (ctrl_intf.cas_rdy) begin
               rw_next_state    <= RW_WAIT_STATE;
               clear_rw_counter <= 1'b1;  
            end else 
            begin
               rw_next_state    <= RW_IDLE;
               clear_rw_counter <= 1'b0;                
            end
         end
               
         RW_WAIT_STATE: begin
            ctrl_intf.rw_done   <= 1'b0;
            ctrl_intf.data_idle <= 1'b0;
            clear_rw_counter <= 1'b0;
            if (rw_counter == rw_delay) begin
               rw_next_state    <= RW_DATA;
               clear_rw_counter <= 1'b1;
               ctrl_intf.rw_rdy <= 1'b1;
            end else
               rw_next_state    <= RW_WAIT_STATE;       
         end
               
         RW_DATA: begin
            ctrl_intf.rw_done  <= 1'b1;   //set data done
            ctrl_intf.rw_rdy   <= 1'b0;
            clear_rw_counter   <= 1'b0;
            if (next_rw)        //next rw avail in queue
               rw_next_state <= RW_WAIT_STATE;
            else                 
               rw_next_state <= RW_IDLE;
         end
                  
         default : rw_next_state <= RW_IDLE;

      endcase
   end 
end  

// keep track when CAS occurs 
always @(intf.reset_n, ctrl_intf.cas_rdy, next_rw)
begin
   int temp;
   if (!intf.reset_n) begin
      rw_cmd_trk.delete();    //delete the queues
      rw_delay  = 0;
   end
      
   //calculate # cycles each CAS command waited in queue
   if((rw_state == RW_IDLE)  && 
      (ctrl_intf.cas_rdy))begin       
      if (ctrl_intf.act_rw == READ)
         DELAY = ctrl_intf.RD_DELAY;
      else 
         DELAY = ctrl_intf.WR_DELAY;   
      rw_delay = DELAY - 1;
   end   
   else if ((rw_state == RW_DATA) && (next_rw)) begin          
      if (rw_trk.pop_front === READ)
          DELAY = ctrl_intf.RD_DELAY;
      else
          DELAY = ctrl_intf.WR_DELAY;   
      
      temp = DELAY - rw_cmd_trk.pop_front -1;
      if (temp > DELAY)
         rw_delay = temp;
      else
         rw_delay = DELAY + ctrl_intf.BL/2;    // enough for the preamble 
      
      //update # cycles each RW cmd waited
      foreach (rw_cmd_trk[i]) 
          rw_cmd_trk [i] = {(rw_cmd_trk[i] + rw_delay +1 )};
   end
   
   if ((ctrl_intf.cas_rdy) &&
       (rw_state != RW_IDLE))
      begin
      rw_cmd_trk = {rw_cmd_trk, (rw_delay - rw_counter)};
      rw_trk     = {rw_trk, ctrl_intf.cas_rw}; 
   end                
end
    
// simple rw_counter 
always_ff @(posedge intf.clock_t)
begin
   if(clear_rw_counter == 1'b1)
      rw_counter <= 0;
   else 
      rw_counter <= rw_counter + 1;
end
                    
//determine the next CAS command avail in queue.
always_ff @ (posedge intf.clock_t)
begin
   if ((rw_next_state == RW_DATA) && 
       (rw_cmd_trk.size != 0)) 
      next_rw <= 1'b1;
   else
      next_rw <= 1'b0;
end        
   
endmodule      
