`include "ddr_package.pkg"

module checker;

sequence MRS; 
73 			$fell(intf.cs_n) and $stable(intf.act_n) and $fell(intf.ras_n_a16) and $fell(intf.cas_n_a15) and $fell(intf.we_n_a14); 
74 endsequence 

75 sequence cke_rose; 
76 	$rose(intf.cke); 
77 endsequence 
78 sequence tXPR2MRS;							// Timing for good clock edge after CKE to first MRS write 
79 	##[tXPR:$] MRS; 
80 endsequence 
81 property test_p; 
82 	@(posedge intf.clock_t) cke_rose |-> tXPR2MRS; 
83 endproperty 
84 test_a: assert property (test_p); 

endmodule
