///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_CAS.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 07/30/2014
//
// DESCRIPTION:  The module implements fsm  for CAS command.
// The FSM is to control the tRRD, delay between ACT and CAS. The delay between     
// CAS to CAS is ignored because delay ACT -> ACT is greater than CAS -CAS delay 
// In case of read to write, or write to read, 
// the burst_cas will wait for previous cmd completed and add tWTR 
// OR CWL wait cycles. The function extra_wait() will calculate the cycles 
// accordingly.
///////////////////////////////////////////////////////////////////////////////                       
                  
`include "ddr_package.pkg"

//note: use clock_t as main clock
module BURST_CAS (DDR_INTERFACE intf,
                  CTRL_INTERFACE ctrl_intf
                  );
                 //input logic rw_done,                    // complete data transaction
                 //input logic act_rdy, [1:0] act_request, // R/W request from act
                 //input int CAS_DELAY,CL,CWL,BL,          //from data module
                 //output logic cas_rdy, cas_idle,
                 //output logic [1:0] rw);

  
cas_fsm_type cas_state, cas_next_state;
logic next_cas = 1'b0;
logic clear_cas_counter = 1'b0;
int  cas_delay, cas_counter, extra_count =0;
logic rtw =1'b0;
int act_cmd_trk[$];        //tracking number of cycles each act command waited
logic [1:0] act_rw_trk[$]; //track read or write command
logic[1:0] request, prev_rq ;
logic ignore = 1'b0;
   
//fsm control timing between CAS and act
always_ff @(posedge intf.clock_t, negedge intf.reset_n)
begin
   if (!intf.reset_n) 
      cas_state <= CAS_IDLE;
   else 
      cas_state <= cas_next_state;
end
   
   
//next state generate logic
//
always_comb
begin
  if (!intf.reset_n) begin 
     cas_next_state    <= CAS_IDLE;
     clear_cas_counter <= 1'b1;
     prev_rq           <= READ;  //default to read
     ctrl_intf.cas_rdy <= 1'b0;
     ctrl_intf.cas_idle<= 1'b1;
     ignore            <= 1'b0;
  end
      
  else
     begin
        case (cas_state)     
        RW_IDLE: begin
           ctrl_intf.cas_rdy   <= 1'b0;
           ctrl_intf.cas_idle  <= 1'b1;
           clear_cas_counter   <= 1'b1;   
           if (ctrl_intf.act_rdy ) begin
              cas_next_state <= CAS_WAIT_STATE;
              //execute one time after reset
              if (!ignore) begin
                prev_rq <= ctrl_intf.act_rw;
                ignore  <= 1'b1;
              end  
           end
        end
               
        CAS_WAIT_STATE: begin
          clear_cas_counter  <= 1'b0;
          ctrl_intf.cas_idle <= 1'b0;

          //satisfy the tRDD 
          if (cas_counter == cas_delay) begin
             clear_cas_counter <= 1'b1;
             //determine back to back read or write)
             if (prev_rq == request) begin
                cas_next_state    <= CAS_CMD; 
                ctrl_intf.cas_rdy <= 1'b1;
                ctrl_intf.cas_rw  <= request;
             end                                      
             else begin             // read to write OR write to read
                
                extra_wait(.prev_rq(prev_rq),
                           .request(request),
                           .rtw(rtw),
                           .extra_count(extra_count));
                           
                if (rtw == 1'b1) 
                   cas_next_state <= CAS_WAIT_EXTRA;           
                else            
                   cas_next_state <= CAS_WAIT_DATA;
                end
            end
        end
              
        CAS_CMD: begin
           prev_rq           <= request;
           ctrl_intf.cas_rdy <= 1'b0;
           clear_cas_counter <= 1'b0;
           //determine the handshake signal clear_cas_counter above should be 
           //here or move to next previous state to speed up 1 clock cycle
           if (next_cas) begin
               cas_next_state <= CAS_WAIT_STATE;                 
           end
           else 
              cas_next_state  <= CAS_IDLE;
        end

        CAS_WAIT_DATA: begin 
           clear_cas_counter <= 1'b1;
                  
           if (ctrl_intf.rw_done) begin
               cas_next_state    <= CAS_WAIT_EXTRA;
               clear_cas_counter <= 1'b1;                     
           end                                  
        end
               
        CAS_WAIT_EXTRA: begin
           clear_cas_counter <= 1'b0;
                   
           if (cas_counter == extra_count) begin
               cas_next_state    <= CAS_CMD;
               ctrl_intf.cas_rdy <= 1'b1;
               ctrl_intf.cas_rw  <= request;
           end
        end
              
      endcase
   end
end  
         
//tracking on ACT command to calulate cas_delay and r/w request
always @ (intf.reset_n, ctrl_intf.act_rdy, ctrl_intf.act_rw, cas_state)
begin
   if (!intf.reset_n) begin
      act_rdy_trk.delete();
      act_rw_trk.delete();
      cas_delay = 0;
      request   = '0;
   end
   
   if ((cas_state == CAS_IDLE) && (ctrl_intf.act_rdy)) begin
      cas_delay = CAS_DELAY - 1;
      request   = ctrl_intf.act_rw;
   end 
   else if ((cas_state == CAS_CMD) && (next_cas)) begin
      cas_delay = CAS_DELAY - act_cmd_trk.pop_front -1;
      request   = act_rw_trk.pop_front;
      
      //update the queue for update # cycles each cmd waited.               
      foreach (act_cmd_trk[i]) 
         act_cmd_trk [i] = {(act_cmd_trk[i] + cas_delay +1 )};
   end
         
   if ((ctrl_intf.act_rdy) && (cas_state != CAS_IDLE)) begin
      act_cmd_trk = {act_cmd_trk, (cas_delay - cas_counter )}; 
      
   //if ((^ctrl_intf.act_rw) && (cas_state != CAS_IDLE))       
      act_rw_trk  = {act_rw_trk, ctrl_intf.act_rw};    
   end                 
end         

      
// simple counter 
always_ff @(posedge intf.clock_t, posedge intf.reset_n)
begin
   if (clear_cas_counter == 1'b1)
       cas_counter <= 0;
   else 
       cas_counter <= cas_counter + 1;
end
                    
//determine act cmd avail in queue.
always_ff @ (posedge intf.clock_t)
begin
   if ((cas_next_state == RW_DATA) &&
       (act_rdy_trk.size != 0) ) 
      next_cas <= 1'b1;
   else
      next_cas <= 1'b0;
end     

 //extra count for read to write CL - CWL + BL/2 + 2nclk
 //extra count for write to read 4nclk + tWTR           
function void extra_wait(input logic[1:0] prev_rq, request, 
                         output logic rtw,
                         output int extra_count);
begin
   rtw           = 1'b0;
   if ((prev_rq == READ) && 
       (request == WRITE)) begin
      rtw         = 1'b1;
      extra_count = ctrl_intf.CL - ctrl_intf.CWL + ctrl_intf.BL/2 + 2;    
   end 
   else if ((prev_rq == WRITE) && 
            (request == READ))  
      extra_count = tWTR + 4;  
   end                        
endfunction

endmodule      
