//////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: Assertions.sv
//
// AUTHOR: Benjamin Huntsman
//
// DATE CREATED: 08/07/2014
//
// DESCRIPTION:  
// This is the package of assertions that can be used within any module or interface within the system.
// It contains timing checks and sequence checks to ensure proper operation of the interface.
// 
///////////////////////////////////////////////////////////////////////////////     

`include "ddr_package.pkg"

module CHECKER(DDR_INTERFACE intf, CTRL_INTERFACE ctrl_intf);

// Setup necessary variables for use within the module


// Activate Commands
//  Require that CS_n of a specific chip be de-asserted (active low) then ACT_n be
//  de-asserted to begin the activate process.  This may not be needed and the only
//  place this assertion can reasonably go is maybe in the activate method.
//property Activate
//	CS_n |-> ACT_n;
//endproperty

// Input data mask
//  ** This does not need implementing **
//property InputMask
//**********************
//endproperty


// Reset(pg.17)
//  A reset involves very specific timing for the reset pin (active low and asynchronous)
//  and the clocks (CK_t, CK_c) and the clock enable signal (CKE).
//  Deselect Command is CKE is high over two clock cycles and CS_n is also high.  All other
//  signals don't matter (X).
sequence reset_s;							// Check for reset
    $rose(intf.reset_n);
endsequence
sequence ckeIS_s;							// Check for correct timing for CKE from reset
    ##[tCKE_L - tIS:$] $rose(intf.cke);
endsequence
sequence cke_s;								// Check for setup timing for CKE before next clock
	##[tIS:$] $rose(intf.clock_t);
endsequence

// Initialization (pg.17-18)
//  Initialization requires that reset was accomplished properly and that CKE is held
//  high for the duration of the initialization sequence.
//  
sequence tXPR2MRS;							// Timing for good clock edge after CKE to first MRS write
	##[tXPR:$] $rose(ctrl_intf.mrs_rdy);
endsequence
sequence tMRD2MRS;							// Timing for rest of MRS writes
	##[tMRD:$] $rose(ctrl_intf.mrs_rdy);
endsequence
sequence tMOD2ZQCL;							// Timing for last MRS to ZQCL
	##[tMOD:$] $rose(ctrl_intf.zqcl_rdy);
endsequence
sequence tZQ2Valid;							// Timing required from ZQCL to valid operation
	##[tZQ:$] $rose(ctrl_intf.config_done);
endsequence
sequence all_init_sequences;
	cke_s ##0 tXPR2MRS ##0 tMRD2MRS[*6] ##0 tMOD2ZQCL ##0 tZQ2Valid;
endsequence
sequence cke_throughout_s;					// Sequence that implements all the initialized checks
	(intf.cke) throughout (all_init_sequences); 
endsequence
property reset_p;							// Implement sequences in a property for use
    @(posedge intf.clock_t) reset_s |-> ckeIS_s |-> cke_throughout_s;
endproperty
reset_a: assert property (reset_p);


// Data Strobe
//  This is the signal that transmits data.  It is an inout signal because it is an
//  edge aligned output with read data, and a centered input with write data.
//  ** This does not need an assertion.  It was verified using timing diagram **
//property DataStrobe
//	*************
//endproperty


// Termination Data Strobe
//  This is applicable to x8 DRAMs only.  When enabled in Mode Register A11 = 1
//  in MR1, the DRAM will enable the same termination resistance function on
//  TDQS_t/TDQS_c that is applied to DQS_t/DQS_c.  When disabled via A11 = 0 in
//  MR1, DM/DBI/TDQS will provide the data mask function or Data Bus Inversion
//  depending on MR5.  A11, 12, 10 and TDQS_c are not used.  x4/x16 DRAMs must
//  disable the TDQS function via mode register A11 = 0 in MR1.
//  ** This is set to disabled.  No need to implement. **
//property TerminateDataStrobe
//	if (DRAMType === x8)
//		MR1A11 == 1 |-> ******
//	else
//		MR1A11 == 0;
//endproperty


// Write Recovery and Read to Precharge (cycles)
//  Can be set in MR0 A11, A10, and A9.  The table for these settings are on
//  page 14 of the JEDEC Guide.
//  ** Is this going to be utilized? **
//property
//endproperty


// CAS Latency Setting
//  CAS Latency can be set for a particular DDR4 DIMM architecture in MR0 by
//  A2, A4, A5, and A6.  The table for the settings is found on page 16 of the
//  JEDEC guide.  This table changes dependent on the DRAM frequency being used.
//  ** Is this going to be utilized? **
//property CASLatencySetting
	
//endproperty


// CAS Write Latency Setting
//  CAS Write Latency can be set in MR2 A3-5.  The table for the settings are
//  found on page 16 of the JEDEC Guide.
//  ** Is this going to be utilized? **
//property

//endproperty


// CAL CS to CMD/ADDR Latency Setting
//  Can be set in MR4 A6-8.  The table for the settings are found on page 20
//  and explained in Section 4.15 of the JEDEC guide.
//  ** Is this going to be utilized? **
//  ** Are we going to parameterize for simulation of different speeds? **
// This is being set to disabled


// ** What commands are being implemented **
//  I will write properties for each implemented command to ensure that each
//  follows required timing and settings.  Command Truth Table is found on
//  page 24 (Table 16).


// ** Are the CKE Settings going to be used from Table 17 - CKE Truth Table? **


// Burst Length, Type, and Order
//  The burst settings can be set in A3 of MR0.  The ordering of accesses within
//  a burst is determined by the burst length, burst type, and the starting column
//  address as shown in Table 18 on page 26 of the JEDEC Guide.
//  ** Is this going to be implemented or will it be static? **
//    This is the only mode register bit that will change in our simulation
//property
//endproperty


// Write Leveling
//  The settings for Write Leveling can be found in section 4.7.
//     ** This is not implemented **

// Refresh
//  4.9

//******************************************************************************
// More defined timing parameters for the timing settings below can be found
//  in Section 12.3

// Write to Write tCCD Timing (CAS_n to CAS_n)
//  Timing diagram found in Section 4.19
//  tCCD_S (short) corresponds to consecutive writes to different Bank Group
//   - Requires 4 clock cycles from write to write
//  tCCD_L (long) corresponds to consecutive writes to the same Bank Group
//   - Requires 6 clock cycles from write to write
//     ** Note: Figure 55 shows 6 clocks but Table 101 shows 5 clocks
//       6 was used in our implementation


// Read to Read tCCD Timing
//  Timing diagram found in Section 4.19
//  tCCD_S (short) corresponds to consecutive reads from different Bank Group
//   - Requires 4 clock cycles from read to read
//  tCCD_L (long) corresponds to consecutive reads from the same Bank Group
//   - Requires 6 clock cycles from read to read

// Activate to Activate tRRD Timing
//  Timing diagram found in Section 4.19, Figure 57
//  tRRD_S (short) corresponds to consecutive ACTIVATE commands to different Bank Group
//   - Requires 4 clock cycles from ACTIVATE to ACTIVATE
//  tRRD_L (long) corresponds to consecutive ACTIVATE commands to different Banks
//  of the same Bank Group
//   - Requires 6 clock cycles from ACTIVATE to ACTIVATE
sequence Activate_s;
	(cke) throughout ($fell(cs_n) and $fell(act_n));
endsequence
sequence Act2Act_s;
	##[ACT_DELAY:$] ($fell(cs_n) and $fell(act_n));
endseqeunce
sequence Act2Read_s;
	##[CAS_DELAY:$] ($rose(act_n)

property AccessTiming_p;
	@(posedge intf.clock_n) Activate_s -> (Act2Act_s or 
endproperty
Access_a: asssert property (AccessTiming_p)
	
	property reset_p;							// Implement sequences in a property for use
    @(posedge intf.clock_t) reset_s |-> ckeIS_s |-> cke_throughout_s;
endproperty
reset_a: assert property (reset_p);
// Four Activate Window
//  This is the timing requirement between four consecutive activate ACTIVATE commands.
//  The timing diagram can be found in Section 4.19, Figure 58 and more specific
//  information in Table 101 on pg. 189(197) of the JEDEC Guide.
//   This was ignored in our implementation


endmodule
