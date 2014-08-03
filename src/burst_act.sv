///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_TCAS.SV
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
module BURST_CAS (DDR_INTERFACE intf,
                  input logic act_cmd,
                  input logic [BG_WIDTH:0] bg_addr,
                  input logic [BA_WIDTH:0] ba_addr,
                  input logic [RA_WIDTH:0] row_addr,
                  input logic rw_done, [1:0] rw_request,
                  output logic act_idle, act_rdy);
                  
   parameter ACT_DELAY = 4; //TEMPORARY VALUE
   parameter tRP       = 10;
   
   act_fsm_type act_state, act_next_state;
   int act_counter;
   logic clear_act_counter;
   
   logic hit = 1'b0;    //same bank and row
   logic miss= 1'b0;    //same bank different row
   logic bank_ini = 1'b1;
   
   int pre_extra_cycles;
   logic [1:0] request;
   logic [NUMBER_BANK-1:0] [RA_WIDTH -1:0] bank_activated = '1;
   
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
            if (act_cmd == 1'b1) 
               act_next_state <= ACT_WAIT_STATE;
            end
              
         ACT_WAIT_STATE: begin  
            clear_act_counter <= 1'b0;  
            act_idle          <= 1'b0;
            bank_activated_chk();       
            if ((act_counter == ACT_DELAY) && (hit))  
               act_next_state <= ACT_CAS;
            else if ((act_counter == ACT_DELAY) && (miss))
               act_next_state <= PRE_WAIT_DATA;
            else if ((act_counter == ACT_DELAY) && (!hit) && (!miss))begin
               act_next_state <= ACT_CMD;
               act_rdy        <= 1'b1;
               end
            end 
            
         ACT_CMD: begin
             clear_act_counter <= 1'b1; 
             act_rdy        <= 1'b0; 
             act_next_state <= ACT_IDLE;
             end
             
         ACT_CAS: begin
             clear_act_counter <= 1'b1;  
             act_next_state <= ACT_IDLE;
             end
             
            
         PRE_WAIT_DATA: begin
             clear_act_counter <= 1'b1;  
             if (rw_done)begin
                act_next_state <= PRE_WAIT_STATE;
                end
              if ((rw_request[0] || rw_request[1]) == 1'b1)
                request <= rw_request;
            end            
            
         PRE_WAIT_STATE: begin   
            clear_act_counter <= 1'b0;
            pre_extra_wait ();
            if (act_counter == pre_extra_cycles) begin
               act_next_state <= PRE_CMD;
               request        <= 2'b0;
               end
            end
         
         PRE_CMD: begin
            clear_act_counter <= 1'b1;
            act_next_state <= PRE_IDLE;
            end             
             
         PRE_IDLE: begin
            clear_act_counter <= 1'b0;
            if (act_counter == tRP)
               act_next_state <= ACT_CMD;
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
         index = int'({ba_addr,bg_addr});
         if (bank_ini)
            bank_activated = '1;
         else begin    
            if (bank_activated[index] === row_addr) begin
               hit = 1'b1;
               miss = 1'b0; 
               end
            else if (bank_activated[index] === '1) begin //bank not activated
               hit = 1'b0;
               miss = 1'b0;   
               bank_activated[index] = row_addr;
               end
            else if ((bank_activated[index] !== '1) && //miss
                     (bank_activated[index] !== row_addr)) begin
                hit = 1'b0;
                miss= 1'b1;     
                bank_activated[index] ='1;     
                end
          end
          end
     endtask
     
     function void pre_extra_wait();
       begin
       if (rw_request == READ) 
          pre_extra_cycles = 10;    
       else if (rw_request == WRITE)  
          pre_extra_cycles = 15;  
       end                        
    endfunction 
     
endmodule
