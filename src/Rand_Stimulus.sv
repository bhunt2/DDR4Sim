// This module randomly generates data, address, and operation fields for testing a DDR4 simulation.
// It stores these in a structure that contains a 64 bit data segement, an 32 bit 
// address segement, and 2 bit op code segement that specifies a read or write operation.
// It then puts these values in a queue to be called by the testbench. 

`include "ddr_package.pkg"
module Rand_Stimulus( DDR_INTERFACE intf,
                      TB_INTERFACE tb_intf);

// Set number of operations to be stored in the queue
parameter num_op = 100;

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

//class Gen_Packet
class Gen_Packet;
    rand Packet Packet_array[];
    bit [31:0] addr_queue[$];
    constraint rw {
         foreach (Packet_array[i])
             Packet_array[i].op_r dist {READ:= 50, WRITE:= 50};
             }          
    
    function void post_randomize;
         foreach (Packet_array[i]) begin
            if ((i == 0) || (addr_queue.size == 0))
               Packet_array[i].op_r = WRITE;
            if(Packet_array[i].op_r == WRITE) 
               addr_queue = {Packet_array[i].addr_r, addr_queue};   
            if ((i > 0) && (Packet_array [i].op_r   == READ ))
                Packet_array[i].addr_r   = addr_queue.pop_back;
         end             
    endfunction
    
    function new();
       addr_queue.delete;
       Packet_array = new[num_op];
       foreach (Packet_array[i])
          Packet_array[i] = new();
    endfunction
    
    //function void print_all() ;
    //foreach (Packet_array[i])
    //   $display ("addr = %h, data = %h, rw = %h", Packet_array[i].addr_r, 
    //      Packet_array[i].data_r, Packet_array[i].op_r);
    //endfunction      
                
endclass
    
// define queue, temp structure union, and class.
input_data_type su[$], Stim_st;
Gen_Packet p;


initial begin
    tb_intf.mrs_update <= 1'b0;
// Generate random fields for num_op operations
	p = new();  // create a packet
	
	assert (p.randomize())
	else $fatal(0, "Gen_Packet::randomize failed");
	//p.print_all();
	
	foreach (p.Packet_array[i]) begin
	   Stim_st.data_wr       = p.Packet_array[i].data_r;
	   Stim_st.physical_addr = p.Packet_array[i].addr_r;
	   Stim_st.rw            = p.Packet_array[i].op_r;

 	   su.push_front(Stim_st);
	end

	wait (tb_intf.rw_proc);
do
   @ (posedge tb_intf.act_cmd ) begin
      tb_intf.data_in = su.pop_back;
    end  
while (su.size != 0);   
end

always_ff @ (intf.clock_t)
begin
    if ((!tb_intf.dev_busy) &&(su.size >0 ) && (tb_intf.next_cmd))
       tb_intf.act_cmd <= 1'b1;
    else   
       tb_intf.act_cmd <= 1'b0;

end

endmodule 

