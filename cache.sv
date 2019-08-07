import lc3b_types::*; /* Import types defined in lc3b_types.sv */
//the cache design. It contains the cache controller and cache datapath.
module cache 
(
	 input clk,
	 input logic pmem_resp,
	 input logic mem_read,
	 input logic mem_write, 	 
	 output logic mem_resp,
	 output logic pmem_read,
	 output logic pmem_write,
	 output lc3b_128 pmem_wdata,
	 
	 input lc3b_word mem_wdata, 
	 input lc3b_word mem_address,
	 input lc3b_2bits mem_byte_enable,
	 input lc3b_128 pmem_rdata,
	 output lc3b_word mem_rdata,
	 output lc3b_word pmem_address
	 
);
//	 lc3b_word cmem_address;// just mem_address do i need? 
	 //lc3b_word mem_rdata;
	 logic comp2;
	 logic LRU_out;
	 logic dirty_LRU;
	 logic hit;
	 //logic pmem_resp;
	 //logic mem_read;
	 //logic mem_write;
	 lc3b_128 data1_out;
	 lc3b_128 data2_out;
	 
	 logic LRU_in;
	 logic LRU_write;
	 logic allocate_sel;
	 logic v1_write,v1_in,d1_write,d1_in,t1_write,data1_write;
	 logic v2_write,v2_in,d2_write,d2_in,t2_write,data2_write;
	 
cache_control aCache_control
(
	 .clk(clk),	  	 
	 .comp2(comp2),
	 .LRU_out(LRU_out),
	 .dirty_LRU(dirty_LRU),
	 .hit(hit),	 
	 .pmem_resp(pmem_resp),
	 .mem_read(mem_read),
	 .mem_write(mem_write),
	 .data1_out(data1_out),
	 .data2_out(data2_out),
	 .LRU_in(LRU_in),
	 .LRU_write(LRU_write),
	 .allocate_sel(allocate_sel),
	 .v1_write(v1_write),
	 .v1_in(v1_in),
	 .d1_write(d1_write),
	 .d1_in(d1_in),
	 .t1_write(t1_write),
	 .data1_write(data1_write),
	 .v2_write(v2_write),
	 .v2_in(v2_in),
	 .d2_write(d2_write),
	 .d2_in(d2_in),
	 .t2_write(t2_write),
	 .data2_write(data2_write),
	 .mem_resp(mem_resp),
	 .pmem_read(pmem_read),
	 .pmem_write(pmem_write),
	 .pmem_wdata(pmem_wdata)
);
cache_datapath aCache_datapath 
(
    .clk(clk),
	 .LRU_in(LRU_in),
	 .LRU_write(LRU_write),
	 .v1_write(v1_write),
	 .v1_in(v1_in),
	 .d1_write(d1_write),
	 .d1_in(d1_in),
	 .t1_write(t1_write),
	 .data1_write(data1_write),
	 .v2_write(v2_write),
	 .v2_in(v2_in),
	 .d2_write(d2_write),
	 .d2_in(d2_in),
	 .t2_write(t2_write),
	 .data2_write(data2_write),
	 .allocate_sel(allocate_sel),
	 .mem_wdata(mem_wdata),
	 .mem_address(mem_address),
	 .mem_write(mem_write),
	 .mem_byte_enable(mem_byte_enable),
	 .pmem_rdata(pmem_rdata),
	 .mem_rdata(mem_rdata),
	 .comp2(comp2),
	 .LRU_out(LRU_out),
	 .dirty_LRU(dirty_LRU),
	 .hit(hit),
	 .pmem_address(pmem_address),
	 .data1_out(data1_out),
	 .data2_out(data2_out)
);
endmodule: cache 

