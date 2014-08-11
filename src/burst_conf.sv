//////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: BURST_CONF.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/03/2014
//
// DESCRIPTION:  The module implements fsm to control sequence for DDR4 Initialization
//  Refer data sheet for details
// 
///////////////////////////////////////////////////////////////////////////////                       

`include "ddr_package.pkg"

module BURST_CONF (DDR_INTERFACE intf,
                   CTRL_INTERFACE ctrl_intf,
                   //set up timing parameters from stimulus
                   input int cas_dly, wr_dly,rd_dly,
                   input logic w_pre, r_pre, [1:0] al_dly, burst_length
                   //output logic mrs_rdy, des_rdy,zqcl_rdy,config_done,
                   //output mode_register_type mode_reg, mr0  //mr0 to DDR_CONTROLLER                   
                   );
                   

bit [2:0] cas, wr;
bit [3:0] rd;


//use always block to init the sequence any time reset asserted.
always@ (intf.reset_n)
begin
   if(!intf.reset_n)
      init_task();
end

//sequence of initialization 

task init_task ();
   intf.cke  <= 1'b0;
   ctrl_intf.mrs_rdy   <= 1'b0;
   ctrl_intf.des_rdy   <= 1'b0;
   ctrl_intf.zqcl_rdy  <= 1'b0;
   ctrl_intf.config_done <= 1'b0;
//   wait (!intf.reset_n)
   
   wait (intf.reset_n); repeat (tCKE_L) @ (posedge intf.clock_t);
   intf.cke <= 1'b1;
   $cast(cas,(cas_dly -4));
   $cast(wr, (wr_dly -9));
   $cast(rd, (rd_dly -9));
   repeat (tIS + 1) @  (posedge intf.clock_t); //DES
   ctrl_intf.des_rdy <= 1'b1;
   ctrl_intf.mode_reg <= 'x;
   repeat (tXPR+ 1) @ (posedge intf.clock_t); //MR3
   ctrl_intf.des_rdy <= 1'b0;
   ctrl_intf.mrs_rdy <= 1'b1;
   ctrl_intf.mode_reg <= 
            {1'b0,3'b011,2'b00,2'b0,2'b00,3'b000,1'b0,1'b0,1'b0,1'b0,2'b00};
   @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b0; 
   ctrl_intf.des_rdy <= 1'b1;
   ctrl_intf.mode_reg  <= 'x;
   repeat (tMRD) @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy <= 1'b0;
   //MR6
   ctrl_intf.mode_reg <= 
                {1'b0,3'b110,1'b0,1'b0,cas,1'b0,1'b0,1'b0,1'b0,6'b000000};
   @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b0; 
   ctrl_intf.des_rdy <= 1'b1;
   ctrl_intf.mode_reg <= 'x;
   repeat (tMRD) @(posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy <= 1'b0;
   //MR5
   ctrl_intf.mode_reg <= 
      {1'b0,3'b101,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,3'b000,1'b0,1'b0,1'b0,3'b000};
   @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b0; 
   ctrl_intf.des_rdy <= 1'b1;
   ctrl_intf.mode_reg <= 'x;
   repeat (tMRD) @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy <= 1'b0;
   //MR4
   ctrl_intf.mode_reg <= 
         {1'b0,3'b100,1'b0,1'b0,w_pre,r_pre,1'b0,1'b0,3'b000, 1'b0,1'b0,
          1'b0,1'b0,1'b0,1'b0};
   @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b0; 
   ctrl_intf.des_rdy <= 1'b1;
   ctrl_intf.mode_reg <= 'x;
   repeat (tMRD) @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy <= 1'b0;
   //MR2
   ctrl_intf.mode_reg <= 
                  {1'b0,3'b010,1'b0,1'b0,1'b0,1'b0,2'b00,1'b0,2'b00,wr,2'b00};
   @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b0; 
   ctrl_intf.des_rdy <= 1'b1;
   ctrl_intf.mode_reg <= 'x;
   repeat (tMRD) @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy <= 1'b0;
   //MR1
   ctrl_intf.mode_reg <= 
    {1'b0,3'b001,1'b0,1'b0,1'b0,1'b0,3'b000,1'b0, 1'b0,2'b00,al_dly,2'b00,1'b1};
   @ (posedge intf.clock_t); 
   ctrl_intf.mrs_rdy <= 1'b0; 
   ctrl_intf.des_rdy <= 1'b1;
   ctrl_intf.mode_reg <= 'x;
   repeat (tMRD) @ (posedge intf.clock_t); 
   ctrl_intf.mrs_rdy <= 1'b1; 
   ctrl_intf.des_rdy <= 1'b0;
   //MR0
   ctrl_intf.mode_reg <= 
   {1'b0,3'b000,1'b0,1'b0,1'b0, 3'b000, 1'b0,1'b0,rd[3:1],1'b0,rd[0],burst_length};
   ctrl_intf.mr0 <= {1'b0,3'b000,1'b0,1'b0,1'b0, 3'b000, 1'b0,1'b0,rd[3:1],
                     1'b0,rd[0],burst_length};          
   @ (posedge intf.clock_t); ctrl_intf.mrs_rdy <= 1'b0; 
   ctrl_intf.des_rdy <= 1'b1;
   ctrl_intf.mode_reg <= 'x;
   repeat (tMOD) @ (posedge intf.clock_t); ctrl_intf.des_rdy <= 1'b0; 
   ctrl_intf.zqcl_rdy <= 1'b1;
   ctrl_intf.mode_reg <= '1;
   @ (posedge intf.clock_t); ctrl_intf.zqcl_rdy <= 1'b0; 
   ctrl_intf.des_rdy <= 1'b1;
   ctrl_intf.mode_reg <= 'x;
   repeat (tZQ) @ (posedge intf.clock_t); 
   ctrl_intf.config_done <= 1'b1; 
   ctrl_intf.des_rdy <= 1'b0;
   
endtask
                 
endmodule
