///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_CAS.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 07/30/2014
//
// DESCRIPTION:  The module implements fsm for CAS command
// The FSM is to control the tRRD, delay between ACT and CAS. The delay between     
// CAS to CAS is ignored because delay ACT -> ACT is greater than CAS delay and 
// burst_act will make sure of it. In case of read to write, or write to read, 
// the burst_cas will wait for previous command completed and add tWTR 
// OR CWL wait cycles. The function extra_wait() will calculate the cycles 
// accordingly.
///////////////////////////////////////////////////////////////////////////////                       
                  
`include "ddr_package.pkg"

//note: use clock_t as main clock
module BURST_CAS (DDR_INTERFACE intf,
                 input logic rw_done,    //from burst_data   
                 input logic [1:0]  rw_request, // determine r or w request from act
                 input logic act_rdy,           //act_rdy from act seq
                 input int CAS_DELAY,           //from data module
                 output logic cas_rdy,cas_idle,
                 output logic [1:0] rw);

  
cas_fsm_type cas_state, cas_next_state;
   logic new_cas = 1'b0;
   logic clear_cas_counter = 1'b0;
   int  cas_delay,cas_counter, extra_count =0;
   logic rtw =1'b0;
   int act_rdy_trk[$];  //tracking number of cycles each rw command waiting
   logic [1:0] cas_rw_trk[$]; //track read or write command
   logic[1:0] request, prev_rw ;
   logic ignore = 1'b0;
   
//fsm control timing between CAS and ACT
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
         prev_rw           <= READ;  //default to read
         cas_rdy           <= 1'b0;
         cas_idle          <= 1'b1;
         cas_delay         = 0;
         ignore            <= 1'b0;
         cas_rw_trk.delete();
         act_rdy_trk.delete();
         end
      else
      begin
         case (cas_state)
            RW_IDLE: begin
               cas_rdy   <= 1'b0;
               cas_idle  <= 1'b1;
               clear_cas_counter <= 1'b1;   
               if (act_rdy == 1'b1) begin
                  cas_next_state <= CAS_WAIT_STATE;
                  
                  //cas delay from act
                  cas_delay = CAS_DELAY - 1;
                  request   = rw_request;
                  
                  //execute one time after reset
                  if (!ignore) begin
                    prev_rw = rw_request;
                    ignore  <= 1'b1;
                  end  
               end
            end
               
            CAS_WAIT_STATE: begin
               clear_cas_counter <= 1'b0;
               cas_idle          <= 1'b0;

               //satisfy the tRDD 
               if (cas_counter == cas_delay) begin
                    clear_cas_counter <= 1'b1;
                  //determine back to back read or write)
                  if (prev_rw == request) begin
                     cas_next_state <= CAS_CMD; 
                     cas_rdy        <= 1'b1;
                     rw             <= request;
                     end                                      
                  else  begin             // read to write OR write to read
                     extra_wait(.prev_rw(prev_rw),.request(request),
                                .rtw(rtw),
                                .extra_count(extra_count));
                     if (rtw == 1'b1) 
                        cas_next_state <= CAS_WAIT_EXTRA;           
                     else            
                        cas_next_state <= CAS_WAIT_DATA;
                        end
                  end
                  
               //track when RW cmd occurs
                if (act_rdy == 1'b1)    
                   act_rdy_trk = {act_rdy_trk, (cas_delay - cas_counter )}; 
  
                if ((rw_request[0] || rw_request [1]) == 1'b1)       
                   cas_rw_trk  = {cas_rw_trk, rw_request[1:0]};                  
                end
              
              CAS_CMD: begin
                  prev_rw = request;
                  cas_rdy <= 1'b0;
                  clear_cas_counter <= 1'b0;
                  //determine the handshake signal above should be here or move 
                  //to next previous state to speed up 1 clock cycle
                  if (new_cas == 1'b1) begin
                     cas_next_state <= CAS_WAIT_STATE;

                     //set new delay and update next delays
                     cas_delay = CAS_DELAY - act_rdy_trk.pop_front -1;
                     request   = cas_rw_trk.pop_front;
                     
                     foreach (act_rdy_trk[i]) 
                        act_rdy_trk [i] = {(act_rdy_trk[i] + cas_delay +1 )};
                     //track when RW cmd occurs
                     if (act_rdy == 1'b1)    
                        act_rdy_trk = {act_rdy_trk, (cas_delay - cas_counter )};
                     if ((rw_request[0] ||rw_request [1]) == 1'b1)  
                        cas_rw_trk  = {cas_rw_trk, rw_request};
                     end
                   else  begin
                     cas_next_state <= CAS_IDLE;

                     //track when RW cmd occurs
                     if (act_rdy == 1'b1)    
                        act_rdy_trk = {act_rdy_trk, (cas_delay - cas_counter )};
                     if ((rw_request[0] || rw_request [1]) == 1'b1)   
                        cas_rw_trk  = {cas_rw_trk, rw_request};
                     end
               end

              CAS_WAIT_DATA: begin 
                  clear_cas_counter <= 1'b1;
                  
                  if (rw_done == 1'b1) begin
                     cas_next_state <= CAS_WAIT_EXTRA;
                     clear_cas_counter <= 1'b1;                     
                  end
                  
                  //track when RW cmd occurs
                  if (act_rdy == 1'b1)    
                      act_rdy_trk = {act_rdy_trk, (cas_delay - cas_counter )};
                  if ((rw_request[0] || rw_request [1]) == 1'b1)    
                      cas_rw_trk  = {cas_rw_trk, rw_request};
                  end
               
               CAS_WAIT_EXTRA: begin
                   clear_cas_counter <= 1'b0;
                   
                   if (cas_counter == extra_count) begin
                      cas_next_state <= CAS_CMD;
                      cas_rdy        <= 1'b1;
                      rw             <= request;
                      end
                       
                   //track when RW cmd occurs
                   if (act_rdy == 1'b1)    
                      act_rdy_trk = {act_rdy_trk, (cas_delay - cas_counter )};
                   if ((rw_request[0] || rw_request[1]) == 1'b1)   
                      cas_rw_trk  = {cas_rw_trk, rw_request};
                   end
              
              endcase

         end
         end  
         
   
    //there will be implement later
    //extra count for read to write CL - CWL + BL/2 + 2nclk
    //extra count for write to read 4nclk + tWTR           
    function void extra_wait(input logic[1:0] prev_rw, request, 
                             output logic rtw,
                             output int extra_count);
    begin
       rtw           = 1'b0;
       if ((prev_rw == READ) && (request == WRITE)) begin
          rtw         = 1'b1;
          extra_count = 10;    
          end
       else 
         if ((prev_rw == WRITE) && (request == READ))  
          extra_count = 15;  
       end                        
    endfunction
      
    // simple rw_counter 
    always_ff @(posedge intf.clock_t, posedge intf.reset_n)
    begin
       if (!intf.reset_n) 
          cas_counter <= 0;
       else
          if(clear_cas_counter == 1'b1)
             cas_counter <= 0;
          else 
             cas_counter <= cas_counter + 1;
     end
                    
      //determine the next RW command.
    always_ff @ (posedge intf.clock_t)
    begin
       if ((cas_next_state == RW_DATA) && (act_rdy_trk.size != 0) ) 
          new_cas <= 1'b1;
       else
          new_cas <= 1'b0;
       end     
endmodule      
