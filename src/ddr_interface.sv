
///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: DDR_INTERFACE.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 07/29/2014
//
// DESCRIPTION:  The module defines all signals connect DDR Controller and DDR
// memory and used as a module port.  The module also includes the method of
//  * translating signal level for device commmands
//  * assertion test for function protocol.
//
///////////////////////////////////////////////////////////////////////////////                       
                  

`include "ddr_package.pkg"                           
                  
interface DDR_INTERFACE;  

timeunit 10ps;
timeprecision 1ps;

   logic [2:0] chip_id = 1'b101;
   logic clock_n, clock_t;
   logic clock_w_n, clock_w_p;   //create data strobe signals
   logic reset_n;
   
   logic cke, cs_n,act_n;
   logic ras_n_a16, cas_n_a15, we_n_a14;
   logic bc_n_a12, ap_a10;
   logic addr17;
   logic addr13;
   logic addr11;
   logic [9:0] addr9_0;
   logic [BG_WIDTH - 1:0] bg_addr;
   logic [BA_WIDTH - 1:0] ba_addr;

   data_type w_data;
   logic dqs, dqs_c, dqsu_t, dqsu_c, dqsl_t, dqsl_c;
   
   //Not necessary use
   wire dm_n, dbi_n, tdqs_t;
   logic PAR;
   wire ODT;
   
   logic [23:0] command_array;
   //index for array of command
   enum {a[9],a10_ap, a11,a13,a17, a12_bc, c[2],ba[2], bg[2],a14_we,a15_cas,
         a16_cas, act,cs} command_index;
   
   //simple clock resource 
   initial
   begin 
      clock_n = FALSE;
      forever #HALF_PERIOD clock_n = ~clock_n;
   end   

   //differential clock 
   initial
   begin 
      clock_t = TRUE;
      forever #HALF_PERIOD clock_t = ~clock_t;
   end 
   
   //write clock with 90 phase shift
   initial
   begin
       clock_w_n = FALSE;
       #QUARTER_PERIOD;
       forever #HALF_PERIOD clock_w_n = ~clock_w_n;
   end    
   
   initial
   begin
       clock_w_p = TRUE;
       #QUARTER_PERIOD;
       forever #HALF_PERIOD clock_w_p = ~clock_w_p;
   end    
   
   
   // method for write data (data out) and strobe pins
   task set_data_pins ();
   endtask

   
   // method for read data (or data in from the Memory) and strobe pins
 
                         
 
 
 
   //method for set command, address pin
   task set_cmd_pins (input command_type command_in);
   @(posedge clock_n);
      begin
       case (command_in.cmd)
          ACT: begin
              cs_n  = 1'b0;
               act_n = 1'b0;
               bg_addr   = command_in.bg_addr;
               ba_addr   = command_in.ba_addr;
               //setup row addr   
               addr17    = 1'b1;
               ras_n_a16 = 1'b1;
               cas_n_a15 = 1'b1;
               we_n_a14  = 1'b1;
               addr13    = command_in.row_addr [13];
               bc_n_a12  = command_in.row_addr [12];
               addr11    = command_in.row_addr [11];
               ap_a10    = command_in.row_addr [10];
               addr9_0   = command_in.row_addr [9:0];
               end

         //nop command       
         NOP:  begin
               cs_n  =  1'b1;
               act_n = 1'b1;      
               bg_addr = '1;
               ba_addr = '1;
               addr17 = 1'b1;
               ras_n_a16 = 1'b1;
               cas_n_a15 = 1'b1;
               we_n_a14  = 1'b1;
               addr13    = 1'b1;
               bc_n_a12  = 1'b1;
               addr11    = 1'b1;
               ap_a10    = 1'b1;
               addr9_0   = '1;               
               end
        endcase;
      end
   endtask
         


endinterface













