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
// From the previous completed to the next data, only waits for 
// CW or CWL minus # cycle stored in queue.
//
///////////////////////////////////////////////////////////////////////////////                       
                  
`include "ddr_package.pkg"

//note: use clock_t as main clock
module BURST_RW (DDR_INTERFACE intf,
                 CTRL_INTERFACE ctrl_intf);
                 //input int RD_DELAY, WR_DELAY, //from BURST DATA module
                 //input logic cas_rdy,          //cas_rdy from cas module
                 //input logic [1:0] rw,         //from cas module
                 //output logic rw_rdy, rw_done, data_idle);

int   DELAY;  
   
rw_fsm_type rw_state, rw_next_state;
//logic rw_cmd, 
logic next_rw;  
logic clear_rw_counter = 1'b0; 
int rw_counter,rw_delay;
int rw_cmd_trk[$];  //tracking number of cycles each rw command waiting
logic [1:0] rw_trk[$];
   
   
   
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
always @(intf.reset_n, ctrl_intf.cas_rdy, next_rw)//, rw_state)
begin
   int temp;
   if (!intf.reset_n) begin
      rw_cmd_trk.delete();    //delete the queues
      rw_delay  = 0;
   end
      
   //calculate # cycles each RW command waited in queue
   if(((rw_state == RW_IDLE) || (rw_state == RW_DATA)) && 
       (ctrl_intf.cas_rdy))begin
       
      if (ctrl_intf.act_rw == READ)
         DELAY = ctrl_intf.RD_DELAY;
      else 
         DELAY = ctrl_intf.WR_DELAY;   
      rw_delay = DELAY - 1;
   end   
   else if ((rw_state == RW_DATA) && (next_rw)) begin
           temp = rw_cmd_trk.pop_front;
           
           if (rw_trk.pop_front === READ)
              DELAY = ctrl_intf.RD_DELAY;
           else
              DELAY = ctrl_intf.WR_DELAY;         
           if (DELAY > (temp + 1))    
                rw_delay = DELAY - rw_cmd_trk.pop_front -1;
            else
                rw_delay = 2;         // enough for the preamble 
      
           //update # cycles each RW cmd waited
           foreach (rw_cmd_trk[i]) 
              rw_cmd_trk [i] = {(rw_cmd_trk[i] + rw_delay +1 )};
   end
   
   if ((ctrl_intf.cas_rdy) &&
       (rw_state != RW_IDLE) && (rw_state != RW_DATA)) begin
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
