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
                  input logic act_cmd,  //connect to simulation model
                  input mem_addr_type mem_addr,
                  input int WR_DELAY,
                  input logic cas_rdy, cas_idle, [1:0] rw_request,
                  output mode_register_type pre_reg,
                  output logic rw_idle, act_rdy,pre_rdy);
                  

   act_fsm_type act_state, act_next_state;
   int act_counter;
   logic clear_act_counter;
   logic act_idle;
   
   logic hit = 1'b0;    //same bank and row
   logic miss= 1'b0;    //same bank different row
   logic bank_ini = 1'b1;  //signal to start initialized bank_activated after reset
   
   int pre_extra_cycles;
   logic [1:0] request;
   logic [NUMBER_BANK-1:0] [RA_WIDTH -1:0] bank_activated = '1;
   
   command_type pre_command;
   
   //rw idle when ACT, CAS, and RW sequence are all idle
   always_comb
   begin
      rw_idle <= act_idle && cas_idle && rw_idle;
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
         act_next_state    <= ACT_IDLE;
         clear_act_counter <= 1'b1;
         act_idle          <= 1'b0;
         act_rdy           <= 1'b0;
         bank_ini           = 1'b1;
         bank_activated_chk();         
         end
      else begin
         case (act_state)         
         ACT_IDLE: begin
            bank_ini = 1'b0;
            act_idle <= 1'b1;
            pre_rdy  <= 1'b0;
            act_rdy  <= 1'b0;
            if (act_cmd == 1'b1) 
               act_next_state <= ACT_WAIT_STATE;
            end
              
         ACT_WAIT_STATE: begin  
            clear_act_counter <= 1'b0;  
            act_idle          <= 1'b0;
            bank_activated_chk();    
               
            if ((act_counter == ACT_DELAY) && (hit)) begin  
               act_next_state <= ACT_CAS;  
               act_rdy        <= 1'b1;
               end
            else if ((act_counter == ACT_DELAY) && (miss))
               act_next_state <= PRE_WAIT_DATA;
            else if ((act_counter == ACT_DELAY) 
                     && (!hit) 
                     && (!miss))begin
                  if (cas_rdy == 1'b0) begin
                     act_next_state <= ACT_CMD;
                     act_rdy        <= 1'b1;
                  
                  end else   //delay to avoid assert both CAS and ACT in one 
                             //cycle. 
                     act_next_state <= ACT_ONE;  
               end
            end 
            
         
         ACT_ONE: begin
             act_next_state <= ACT_CMD;
             act_rdy        <= 1'b1;
             end
            
         ACT_CMD: begin
             clear_act_counter <= 1'b1; 
             act_rdy        <= 1'b0; 
             act_next_state <= ACT_IDLE;
             end
             
         //skip the activate command.
         ACT_CAS: begin
             act_rdy           <= 1'b0;
             clear_act_counter <= 1'b1;  
             act_next_state <= ACT_IDLE;
             end
             
           
         PRE_WAIT_DATA: begin
             clear_act_counter <= 1'b1;
             //wait until the previous CAS command completed or idle  
             if (cas_idle) begin
                act_next_state <= PRE_WAIT_STATE;
                //sample the previous CAS is read or write  
                request <= rw_request;
                end
            end            
            
         PRE_WAIT_STATE: begin   
            clear_act_counter <= 1'b0;
            pre_extra_wait ();
            if (act_counter == pre_extra_cycles) begin
               act_next_state <= PRE_CMD;
               //request        <= 2'b0;
               //get method for setup PRECHARGE command.
               pre_rdy                   <= 1'b1;
               pre_reg  <= {mem_addr.bg_addr, mem_addr.ba_addr, 15'b0};

               end
            end
         
         PRE_CMD: begin
            clear_act_counter <= 1'b1;
            pre_rdy        <= 1'b0;
            act_next_state <= PRE_IDLE;
            end             
             
         PRE_IDLE: begin
            clear_act_counter <= 1'b0;
            if (act_counter == tRP) begin
               act_rdy        <= 1'b1;
               act_next_state <= ACT_CMD;
            end        
         end
      endcase                   
      end
      end
      
    // simple act_counter 
    always_ff @(posedge intf.clock_t, posedge intf.reset_n)
    begin
       if (!intf.reset_n) 
          act_counter <= 0;
       else
          if(clear_act_counter == 1'b1)
             act_counter <= 0;
          else 
             act_counter <= act_counter + 1;
     end 
     
     task bank_activated_chk();
     begin
         static int index;
         miss = 1'b0;
         hit  = 1'b0;
         index = int'({mem_addr.bg_addr,mem_addr.ba_addr});
         if (bank_ini)
            bank_activated = '1;
         else begin    
            if (bank_activated[index] === mem_addr.row_addr) begin
               hit = 1'b1;
               miss = 1'b0; 
               end
            else if (bank_activated[index] === '1) begin //bank not activated
               hit = 1'b0;
               miss = 1'b0;   
               bank_activated[index] = mem_addr.row_addr;
               end
            else if ((bank_activated[index] !== '1) && //miss
                     (bank_activated[index] !== mem_addr.row_addr)) begin
                hit = 1'b0;
                miss= 1'b1;     
                bank_activated[index] ='1;     
                end
          end
          end
     endtask
     
     //function to calculate the time delay from previous CAS to precharge.
     //previous CAS was read, then RTP =  tRTP
     //previous CAS is write then WTP = WL+4+WR
     
     function void pre_extra_wait();
       begin
       if (rw_request == READ) 
          pre_extra_cycles = tRTP;    
       else if (rw_request == WRITE)  
          pre_extra_cycles = WR_DELAY + tWR + 4;  
       end                        
    endfunction 
     
endmodule
