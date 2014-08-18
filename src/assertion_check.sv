///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: ASSERTION_CHECK.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 08/052014
//
// DESCRIPTION:  The module contains the concurrent assertions to check DDR
// timming and protocols. Included: Initialization, CKE, CL (Read Latency),
// CWL (Write Latency, tCCD (read-to-read, read-to-write, write-to-read, and
// write-to-write), tWTP (Write to PreCharge), tRTP (Read to PreCharge),
// tRCD (Act to Cas latency), tZQ (init to Act), tREF (Refresh Period),
// tRAS (Act to Precharge), tRP (PreCharge to Act).
// 
// Note: use clock_t as main clock
//
///////////////////////////////////////////////////////////////////////////////

`include "ddr_package.pkg"

module ASSERTION_CHECK(DDR_INTERFACE intf);

timeunit 10ns;
timeprecision 1ps;

parameter tCCD        = 4;
parameter tCAS_W      = 10;
parameter tCAS_R      = 13;
parameter W_PRE       = 1'b1;
parameter R_PRE       = 1'b1;
parameter BURST_LENGTH= 2'b00;
parameter AL_DLY      = 2'b00;

//BL_HALF must set according to parameterized BURST_LENGTH
parameter BL_HALF = 2;


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

sequence PRE_CHARGE_S;
 (!intf.cs_n) ##0 (intf.act_n)##0 (!intf.ras_n_a16) ##0 
  (intf.cas_n_a15) ##0 (!intf.we_n_a14);
endsequence

sequence DSQ_S;
  $fell (intf.dqs_t) ##0 $rose(intf.dqs_c);
endsequence  

//CAS - Read Data latency
//min CL

property CL_P;
   @(posedge intf.clock_t)
   CAS_RD_S |=> (##[(tCAS_R + AL_DLY): $]DSQ_S);
endproperty
assert property(CL_P);

//CAS - Write Data latency
//min CWL

property CWL_P;
   @(posedge intf.clock_t)
   CAS_WR_S |=> (##[(tCAS_W + AL_DLY): $]DSQ_S);
endproperty
assert property(CWL_P);

//CKE de-assert low for 500us - tIS after reset
//
property CKE_P;
   @(posedge intf.clock_t)
   RESET_S |-> (##[(tCKE_L - tIS):$]CKE_ROSE);
endproperty
assert property(CKE_P);   

//min CAS to CAS latency  
//Read to Read or Read to Write

property tCCDR_P;
   @ (posedge intf.clock_t)
   CAS_RD_S |=> ((##[tCCD:$] CAS_RD_S) or ( ##[(tCCD + tWTR + 4):$] CAS_WR_S));
endproperty
assert property(tCCDR_P);

//min CAS to CAS latency  
//Write to Write or Write to Read
property tCCDW_P;
   @ (posedge intf.clock_t)
   CAS_WR_S |=> ((##[tCCD:$] CAS_WR_S) or ( ##[(CAS_R + BL_HALF + 2):$] CAS_RD_S));
endproperty
assert property(tCCDW_P);

//min CAS_W to PRE_CHARGE
//tWTP = WL+4+WR

property tWTP_P;
   @ (posedge intf.clock_t)
   CAS_WR_S |=> (tCCDW_P or ( ##[(tWTR + 4 + tWR):$] PRE_CHARGE_S));
endproperty
assert property(tWTP_P);

//CAS_R to PRE_CHARGE
//tRTP

property tRTP_P;
   @ (posedge intf.clock_t)
   CAS_RD_S |=> (tCCDR_P or ( ##[(tRTP):$] PRE_CHARGE_S));
endproperty
assert property(tRTP_P);
 
//min ACT to CAS delay
//tRCD

property tRCD_P;
   @ (posedge intf.clock_t)
   ACT_S |=> ((##[tRCD: $]CAS_RD_S) or (##[tRCD:$]CAS_WR_S));
endproperty
assert property(tRCD_P);   
 
//verify initialization sequence

property INIT_SEQ_P;
   @ (posedge intf.clock_t) 
   CKE_ROSE |-> ##[(tIS + tXPR):(tIS + tXPR + 1)] MRS_3 ##[tMRD:tMRD+1] MRS_6
                ##[tMRD:tMRD+1] MRS_5 ##[tMRD:tMRD+1] MRS_4
                ##[tMRD:tMRD+1] MRS_2 ##[tMRD:tMRD+1] MRS_1
                ##[tMRD:tMRD+1] MRS_0 ##[tMOD:tMOD+1] ZQCL_S;
                
endproperty
assert property(INIT_SEQ_P);  

//verify timming from INIT_SEQ to ACT
//min tZQ

property INIT_ACT_P;
   @ (posedge intf.clock_t) 
   ZQCL_S|=> ##[(tZQ):$] ACT_S; 
endproperty
assert property(INIT_ACT_P);  

//verify period of REF 
//min tREF
 
property REF_P;
   @ (posedge intf.clock_t) 
   REF_S|=> ##[(tREF):(tREF+3)] REF_S; 
endproperty
assert property(REF_P);  

//verify ACT to ACT latency
//and ACT - PRECHARGE latency
//min tRAS

property ACT_P;
   @(posedge intf.clock_t)
   ACT_S |=> ((##[ACT_DELAY: $] ACT_S) or (##[tRAS:$] PRE_CHARGE_S));
endproperty
assert property(ACT_P);   

//verify PRECHARGE to ACT latency
//min tRP

property ACT_PRE_P;
    @(posedge intf.clock_t)
    PRE_CHARGE_S |=> ##[tRP:$] ACT_S;
endproperty
assert property(ACT_PRE_P);

    
endmodule
