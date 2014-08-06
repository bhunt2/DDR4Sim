//////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: DDR_CONTROLLER.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/03/2014
//
// DESCRIPTION:  The module implements fsm to control between initialization,
//               read/write, refresh, and update.
// 
///////////////////////////////////////////////////////////////////////////////                       

`include "ddr_package.pkg"

module ddr_controller (DDR_INTF intf,
                       input logic config_done,
                       input logic rw_idle,
                       input logic mrs_update, update_done, //from sim model
                       output logic dev_busy,   //connect to sim to stop data.
                       refresh_rdy);       
                       
  ctrl_fsm_type ctrl_state, ctrl_next_state;
  
  int   refresh_counter;
  logic clear_counter, refresh_almost,refresh_done;

  assign  dev_busy = (ctrl_state == CTRL_RW)? 1'b0: 1'b1;
  
  //fsm ddr controller
   always_ff @(posedge intf.clock_t, negedge intf.reset_n)
   begin
      if (!intf.reset_n) 
         ctrl_state <= CTRL_IDLE;
      else 
         ctrl_state <= ctrl_next_state;
   end
   
   
   //next state generate logic
   //
   always_comb
   begin
      case (ctrl_state)
         CTRL_IDLE: begin
            clear_counter <= 1'b1;
            if (intf.reset_n)
               ctrl_next_state    <= CTRL_INIT;
            end   
            
         CTRL_INIT: begin  
           clear_counter <= 1'b1;
           if(config_done)
              ctrl_next_state  <= CTRL_RW;
           end
           
          CTRL_RW: begin
            clear_counter <= 1'b0;    // assume refresh occurs only rw, and update
            if ((mrs_update) || (refresh_almost))
              ctrl_next_state <= CTRL_WAIT;                        
            end
           
          CTRL_WAIT: begin
             if(rw_idle) begin
               if (mrs_update)
                 ctrl_next_state <= CTRL_UPDATE;
               else 
                 ctrl_next_state <= CTRL_REFRESH;  
             end
             end
             
          CTRL_UPDATE: begin
             if(update_done)
               ctrl_next_state <= CTRL_RW;
             end
           
          CTRL_REFRESH: begin
             if(refresh_done)
               ctrl_next_state <= CTRL_RW;
             end
             
          default: ctrl_next_state <= CTRL_IDLE;
          
          endcase
    end             
              
      // simple act_counter 
    always_ff @(posedge intf.clock_t, posedge intf.reset_n)
    begin
       if(clear_counter == 1'b1) begin
          refresh_counter <= 0;
          refresh_almost  <= 1'b0;
          refresh_rdy     <= 1'b0;
          refresh_done    <= 1'b0;
          end
       else begin
          refresh_counter <= refresh_counter + 1;
          if (refresh_counter == tREF - 100) 
             refresh_almost <= 1'b1;
          else if (refresh_counter == tREF)
             refresh_rdy    <= 1'b1;
          else if (refresh_counter == tREF + 1)
             refresh_rdy    <= 1'b0;   
          else if (refresh_counter == tREF + tRC)
             refresh_done    <= 1'b1;
          end        
     end 
                          


endmodule
