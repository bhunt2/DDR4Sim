// This module reads in bit vectors containing used as stimulus for a DDR4 simulation.
// It stores the bit vector in a stuct that contains a 64 bit data segement, an 29 bit 
// address segement, and 2 bit op code segement that specifies a read or write operation.
// It does this in a queue. 


module Stimulus();



typedef struct packed{
	bit [63:0] data;
	bit [28:0] addr;
	bit [1:0] op;} Stim_struct;

typedef union packed{
	bit [94:0] bv; 
	Stim_struct Struct;
	} stim_u;

stim_u su[$], temp;

initial begin 

int file, r1, r2, r3;

file = $fopen("RWonly.txt","r");if(file===0)begin
	$display("Error: Can not open the file.");
end
	while (! $feof(file)) begin
		r1 = $fscanf(file,"%h",temp.Struct.data);
		r2 = $fscanf(file,"%h",temp.Struct.addr);
		r3 = $fscanf(file,"%h",temp.Struct.op);
		su.push_front(temp.bv);
	end
$display("Contents: %p",su);
end
endmodule 
