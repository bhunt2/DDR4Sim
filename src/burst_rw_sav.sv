///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_RW.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 07/29/2014
//
// DESCRIPTION:  The module implements fsm to control sequence for burst read 
// and write.  A queue is used to keep track clock cycles delay for each RW
// command while waiting for the previous transaction complete. Note in 
// this module, only tracking latency between CAS to Data.
// From the previous completed to the next data in/out, only waits for 
// CW or CWL - # cycle stored in queue instead of CW or CWL
//
///////////////////////////////////////////////////////////////////////////////                       
                  
`include "ddr_package.pkg"

//note: use clock_t as main clock
module BURST_RW (DDR_INTERFACE intf,
                 input int RD_DELAY, WR_DELAY,
                 input logic rw_cmd,   //connect to cas_rdy in cas module
                 input logic [1:0] rw, //connect to cas module
                 output logic rw_rdy, rw_done, rw_idle);

   int   DELAY;  
   
   rw_fsm_type rw_state, rw_next_state;
   //logic rw_cmd, 
   logic new_data;  
   logic clear_rw_counter = 1'b0; 
   int rw_counter,rw_delay;
   int rw_cmd_trk[$];  //tracking number of cycles each rw command waiting
   
   
   //set DELAY to RD_DELAY(CL) or WR_DELAY (CWL)
   assign DELAY = (rw == 2'b01)? RD_DELAY: WR_DELAY;
   
   //fsm control timing between CAS and data 
   always_ff @(posedge intf.clock_t, negedge intf.reset_n)
   begin
      if (!intf.reset_n) 
         rw_state <= RW_IDLE;
      else 
         rw_state <= rw_next_state;
   end
   
   
   //next state generate logic
   //
   always_comb
   begin
      if (!intf.reset_n) begin 
         rw_next_state    <= RW_IDLE;
         clear_rw_counter <= 1'b1;
         rw_done          <= 1'b0;
         rw_rdy           <= 1'b0;
         rw_cmd_trk.delete();
         end
      else
      begin
         case (rw_state)
            RW_IDLE: begin
               rw_done        <= 1'b1;
               rw_idle        <= 1'b1;
               if (rw_cmd == 1'b1) begin
                  rw_next_state <= RW_WAIT_STATE;
                  clear_rw_counter <= 1'b1;   
                  //set the clock cycle delay
                  rw_delay = DELAY - 1;            
               end
               end
               
            RW_WAIT_STATE: begin
               rw_done          <= 1'b0;
               rw_idle          <= 1'b0;
               clear_rw_counter <= 1'b0;
               if (rw_counter == rw_delay) begin
                   rw_next_state <= RW_DATA;
                   clear_rw_counter <= 1'b1;
                   rw_rdy           <= 1'b1;
                   end
               //track when RW cmd occurs
               if (rw_cmd == 1'b1)    
                   rw_cmd_trk = {rw_cmd_trk, (rw_delay - rw_counter )};
               end
               
            RW_DATA: begin
                rw_done          <= 1'b1;   //set data done
                rw_rdy           <= 1'b0;
                clear_rw_counter <= 1'b0;
                if (new_data == 1'b1) begin  //cas cmd still avail in queue
                   rw_next_state <= RW_WAIT_STATE;
                   
                   //set new delay and update next delays
                   rw_delay = DELAY - rw_cmd_trk.pop_front -1;
                   foreach (rw_cmd_trk[i]) 
                     rw_cmd_trk [i] = {(rw_cmd_trk[i] + rw_delay +1 )};
                
                   
                   //put the following code in the IF loop to make sure rw_cmd_
                   //trk occurs in order.
                   if (rw_cmd == 1'b1)
                      rw_cmd_trk = {rw_cmd_trk, (rw_delay - rw_counter )};
                    end  
                else
                begin 
                   rw_next_state <= RW_IDLE;
  
                   //track when RW cmd occurs
                   if (rw_cmd == 1'b1)    
                       rw_cmd_trk = {rw_cmd_trk, (rw_delay - rw_counter )};
                   end
                end
                  
            default : rw_next_state <= RW_IDLE;
          endcase
       end 
    end  
   
    // simple rw_counter 
    always_ff @(posedge intf.clock_t, posedge intf.reset_n)
    begin
       if (!intf.reset_n) 
          rw_counter <= 0;
       else
          if(clear_rw_counter == 1'b1)
             rw_counter <= 0;
          else 
             rw_counter <= rw_counter + 1;
     end
                    
    //determine the next RW command.
    always_ff @ (posedge intf.clock_t)
    begin
       if ((rw_next_state == RW_DATA) && (rw_cmd_trk.size != 0) ) 
          new_data <= 1'b1;
       else
          new_data <= 1'b0;
       end        
   
endmodule      
