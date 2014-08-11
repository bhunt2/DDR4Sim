// This module reads in bit vectors containing used as stimulus for a DDR4 simulation.
// It stores the bit vector in a stuct that contains a 64 bit data segement, an 29 bit 
// address segement, and 2 bit op code segement that specifies a read or write operation.
// It does this in a queue. 


`include "ddr_package.pkg"
module Stimulus(CTRL_INTERFACE ctrl_intf,
                input logic dev_busy,
                output input_data_type data,
                output logic act_cmd);

timeunit 10ps;
timeprecision 1ps;

//typedef struct packed{
//	bit [63:0] data;
//	bit [28:0] addr;
//	bit [1:0] op;} Stim_struct;

//typedef union packed{
//	bit [94:0] bv; 
//	Stim_struct Struct;
//	} stim_u;

//stim_u su[$], temp;
input_data_type su[$], temp;
int data_count = 0;

initial begin 
int file, r1, r2, r3;

data_count = 0;

#10
file = $fopen("../sim/Fulltest.txt","r");if(file===0)begin
	$display("Error: Can not open the file.");
end

	while (! $feof(file)) begin
		r1 = $fscanf(file,"%h",temp.physical_addr);
		r2 = $fscanf(file,"%h",temp.data_wr);
		r3 = $fscanf(file,"%h",temp.rw);
		su.push_front(temp);
		
	end
//$display("Contents: %p",su);
wait (ctrl_intf.rw_proc);
do
   @ (posedge act_cmd ) begin
      data = su.pop_back;
      data_count ++;
    end  
while (su.size != 0);   
end

always_ff @ (intf.clock_t)
begin
    if ((!dev_busy) && (su.size >0 ) && (ctrl_intf.act_idle))
       act_cmd <= 1'b1;
    else   
       act_cmd <= 1'b0;

end


endmodule 
