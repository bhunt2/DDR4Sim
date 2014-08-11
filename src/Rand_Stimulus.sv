// This module randomly generates data, address, and operation fields for testing a DDR4 simulation.
// It stores these in a structure that contains a 64 bit data segement, an 32 bit 
// address segement, and 2 bit op code segement that specifies a read or write operation.
// It then puts these values in a queue to be called by the testbench. 


module Rand_Stimulus();

// Set number of operations to be stored in the queue
parameter num_op = 1000;

// Define the packed structure for the queue
typedef struct packed{
	bit [63:0] data;
	bit [31:0] addr;
	bit [1:0] op;} Stim_struct;

// Create union with equal sized bit vector for easy transfer
typedef union packed{
	bit [97:0] bv; 
	Stim_struct Struct;
	} stim_u;

// Use class for randomization
class Packet;
// Random variables
randc bit [63:0] data_r;
randc bit [31:0] addr_r;
randc bit [1:0] op_r;
// Limit values for op to R/W (01 or 10)
constraint c {op_r >= 2'b01;
	      op_r <= 2'b10;}
endclass


// define queue, temp structure union, and class.
stim_u su[$], temp;
Packet p;


initial begin
// Generate random fields for num_op operations
for(int i = num_op; i > 0; i--)begin
	p = new();  // create a packet
	p.c.constraint_mode(1);  // turn constraint on
	assert (p.randomize())
	else $fatal(0, "Packet::randomize failed");
	temp.Struct.data = p.data_r;
	temp.Struct.addr = p.addr_r;
	temp.Struct.op = p.op_r;
	su.push_front(temp.bv);
	$display("op: %h",temp.Struct.op);
	$display("addr: %h",temp.Struct.addr);
	$display("data: %h",temp.Struct.data);
	end
end
endmodule 

