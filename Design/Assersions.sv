// Activate Commands
//  Require that CS_n of a specific chip be de-asserted (active low) then ACT_n be
//  de-asserted to begin the activate process.  This may not be needed and the only
//  place this assertion can reasonably go is maybe in the activate method.
property Activate
	CS_n |-> ACT_n;
endproperty

// Input data mask
//  ** This does not need implementing **
//property InputMask
//**********************
//endproperty

// Reset
//  The reset is active low and asynchronous.  System must return to default state
//  a reset command is given
property Reset
	~RESET_n |-> ((((All signals are default))))**************
endproperty

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
property
	
endproperty

// CAS Latency Setting
//  CAS Latency can be set for a particular DDR4 DIMM architecture in MR0 by
//  A2, A4, A5, and A6.  The table for the settings is found on page 16 of the
//  JEDEC guide.  This table changes dependent on the DRAM frequency being used.
//  ** Is this going to be utilized? **
property CASLatencySetting
	
endproperty

// CAS Write Latency Setting
//  CAS Write Latency can be set in MR2 A3-5.  The table for the settings are
//  found on page 16 of the JEDEC Guide.
//  ** Is this going to be utilized? **
property

endproperty

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

// ** Are the CKE Settings going tob be used from Table 17 - CKE Truth Table? **

// Burst Length, Type, and Order
//  The burst settings can be set in A3 of MR0.  The ordering of accesses within
//  a burst is determined by the burst length, burst type, and the starting column
//  address as shown in Table 18 on page 26 of the JEDEC Guide.
//  ** Is this going to be implemented or will it be static? **
//    This is the only mode register bit that will change in our simulation
property
	
endproperty

// Write Leveling
//  The settings for Write Leveling can be found in section 4.7.
//  ** Is this being implemented? **
//     This is not implemented

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


// Active to Active tRRD Timing
//  Timing diagram found in Section 4.19, Figure 57
//  tRRD_S (short) corresponds to consecutive ACTIVATE commands to different Bank Group
//   - Requires 4 clock cycles from ACTIVATE to ACTIVATE
//  tRRD_L (long) corresponds to consecutive ACTIVATE commands to different Banks
//  of the same Bank Group
//   - Requires 6 clock cycles from ACTIVATE to ACTIVATE


// Four Activate Window
//  This is the timing requirement between four consecutive activate ACTIVATE commands.
//  The timing diagram can be found in Section 4.19, Figure 58 and more specific
//  information in Table 101 on pg. 189(197) of the JEDEC Guide.
//   This was ignored in our implementation


