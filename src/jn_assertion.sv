`include "ddr_package.pkg"

module  jn_checker(DDR_INTERFACE intf);

timeunit 10ns;
timeprecision 1ps;

parameter tCCD        = 4;
parameter WR_DLY      = 10;
parameter RD_DLY      = 13;
parameter BURST_LENGTH= 2'b10;

int BL_HALF;
assign BL_HALF = (BURST_LENGTH == 2'b10)? 2:4;

sequence MRS_0; 
  (!intf.cs_n) ##0 (intf.act_n) ##0 (!intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (!intf.we_n_a14) ##0 (intf.bg_addr[0]==1'b0) ##0
  (intf.ba_addr == 2'b00);
endsequence 

sequence MRS_1; 
  (!intf.cs_n) ##0 (intf.act_n) ##0 (!intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (!intf.we_n_a14) ##0 (intf.bg_addr[0]==1'b0) ##0
  (intf.ba_addr == 2'b01);
endsequence 

sequence MRS_2;
  (!intf.cs_n) ##0 (intf.act_n) ##0 (!intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (!intf.we_n_a14) ##0 (intf.bg_addr[0]==1'b0) ##0
  (intf.ba_addr == 2'b10);
endsequence 

sequence MRS_3; 
  (!intf.cs_n) ##0 (intf.act_n) ##0 (!intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (!intf.we_n_a14) ##0 (intf.bg_addr[0]==1'b0) ##0
  (intf.ba_addr == 2'b11);
endsequence 

sequence MRS_4; 
  (!intf.cs_n) ##0 (intf.act_n) ##0 (!intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (!intf.we_n_a14) ##0 (intf.bg_addr[0]==1'b1) ##0
  (intf.ba_addr == 2'b00);
endsequence 

sequence MRS_5; 
  (!intf.cs_n) ##0 (intf.act_n) ##0 (!intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (!intf.we_n_a14) ##0 (intf.bg_addr[0]==1'b1) ##0
  (intf.ba_addr == 2'b01);
endsequence 

sequence MRS_6; 
  (!intf.cs_n) ##0 (intf.act_n) ##0 (!intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (!intf.we_n_a14) ##0 (intf.bg_addr[0]==1'b1) ##0
  (intf.ba_addr == 2'b10);
endsequence 

sequence ZQCL_S;
  (!intf.cs_n) ##0 (intf.act_n) ##0 (intf.ras_n_a16) ##0 
  (intf.cas_n_a15) ##0 (!intf.we_n_a14);
endsequence 

sequence REF_S;
  (!intf.cs_n) ##0 (intf.act_n) ##0 (!intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (intf.we_n_a14);
endsequence

sequence ACT_S;
  (!intf.cs_n) ##0 (!intf.act_n);
endsequence

sequence CKE_ROSE; 
 	$rose(intf.cke);
endsequence 

sequence RESET_S; 
 	$rose(intf.reset_n);
endsequence 

sequence CAS_RD_S;
  (!intf.cs_n) ##0 (intf.act_n)##0 (intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (intf.we_n_a14);
endsequence

sequence CAS_WR_S;
  (!intf.cs_n) ##0 (intf.act_n)##0 (intf.ras_n_a16) ##0 
  (!intf.cas_n_a15) ##0 (!intf.we_n_a14);
endsequence



//CAS to CAS latency  
//Read to Read or Read to Write
property tCCDR_P;
   @ (posedge intf.clock_t)
   CAS_RD_S |=> ((##[tCCD:$] CAS_RD_S) or ( ##[(tCCD + tWTR + 4):$] CAS_WR_S))
endproperty
assert property(tCCDR_P);

property tCCDW_P;
   @ (posedge intf.clock_t)
   CAS_WR_S |=> ((##[tCCD:$] CAS_WR_S) or ( ##[(tCCD + tWTR + 4):$] CAS_RD_S))
endproperty
assert property(tCCDW_P);
 
//verify timming from CKE to MRS_5
property INIT_SEQ_P;
   @ (posedge intf.clock_t) 
   CKE_ROSE |-> ##[(tIS + tXPR):(tIS + tXPR + 1)] MRS_3 ##[tMRD:tMRD+1] MRS_6
                ##[tMRD:tMRD+1] MRS_5 ##[tMRD:tMRD+1] MRS_4
                ##[tMRD:tMRD+1] MRS_2 ##[tMRD:tMRD+1] MRS_1
                ##[tMRD:tMRD+1] MRS_0 ##[tMOD:tMOD+1] ZQCL_S;
                
endproperty
assert property(INIT_SEQ_P);  

//verify timming from INIT_SEQ to ACT
//make sure the > tZQ
property INIT_ACT_P;
   @ (posedge intf.clock_t) 
   ZQCL_S|=> ##[(tZQ):$] ACT_S; 
endproperty
assert property(INIT_ACT_P);  

 //verify period of REF for tREF
property REF_P;
   @ (posedge intf.clock_t) 
   REF_S|=> ##[(tREF):(tREF+3)] REF_S; 
endproperty
assert property(REF_P);  

//verify the latency from ACT - ACT
property ACT_P;
   @(posedge intf.clock_t)
   ACT_S |=> ##[ACT_DELAY: $] ACT_S;
endproperty
assert property(ACT_P);   

endmodule
