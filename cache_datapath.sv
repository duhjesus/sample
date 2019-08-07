import lc3b_types::*;
//the cache_datapath It contains the data array, valid array, dirty array, 
//tag array, LRU array, comparators, muxes, logic gates, and so on. 
module cache_datapath
(
    input clk,
	 //inputs from cache_control 
	 input logic LRU_in,LRU_write,
	 input logic v1_write,v1_in,d1_write,d1_in,t1_write,data1_write,
	 input logic v2_write,v2_in,d2_write,d2_in,t2_write,data2_write,
	 input logic allocate_sel,
	 //inputs from CPU
	 input lc3b_word mem_wdata,
	 input lc3b_word mem_address,
	 //input logic mem_read,
	 input logic mem_write,
	 input lc3b_mem_wmask mem_byte_enable,
	 //inputs from physical memory 
	 //input logic pmem_resp,
	 input lc3b_128 pmem_rdata,
	 
	 //outputs =====================================================	 
	 //outputs to cache control
	 //output lc3b_word cmem_address,// gets outputted 
	 output lc3b_word mem_rdata,
	 output logic comp2,
	 output logic LRU_out,
	 //output logic valid,
	// output logic dirty,
	 output logic dirty_LRU,
	 output logic hit,
	 //output to CPU
	 //output logic mem_resp,
	 //outputs to physical memory 
	// output lc3b_128 pmem_wdata,
	 //output logic pmem_read,
	 //output logic pmem_write,
	 output lc3b_word pmem_address,
	 output lc3b_128 data1_out,
	 output lc3b_128 data2_out
);
/* declare internal signals */
   lc3b_tag tag;
	lc3b_index index;
	lc3b_offset offset;
	
	//logic hit;
	logic v1_out;
	logic v2_out;
	lc3b_tag t1_out;
	lc3b_tag t2_out;
	lc3b_tag tag_out;
	logic d1_out;
	logic d2_out;
	
	//logic comp1;
	//logic comp2;
	logic tag_equal2;
	logic tag_equal1;
	//lc3b_128 data1_out;
	//lc3b_128 data2_out;
	lc3b_128 outdata_128;
	lc3b_128 written_128;
	lc3b_128 write_this_back;
	lc3b_word new_addr;
	logic addrpicker_sel;
	lc3b_3bits small_offset;
	
	//assign cmem_address=mem_address;
	//assign pmem_wdata = outdata_128;
	assign addrpicker_sel=dirty_LRU & ~hit;
	assign small_offset=offset[3:1]; // used only for cache datapath 
/* initialize modules*/
memaddr_decode memaddr_decode
(
	.mem_address(mem_address),
	.tag(tag),
   .index(index),
   .offset(offset)
);

checkhit checkhit
(
	.v1(v1_out),
	.tag_equal1(tag_equal1),
	.v2(v2_out),
	.tag_equal2(tag_equal2),
	//.comp1(comp1),
	.comp2(comp2),
	.hit(hit) 
);

array #(.width(1))LRU
(
    .clk(clk),
    .write(LRU_write),
    .index(index),
    .datain(LRU_in),
    .dataout(LRU_out)
); 
tag_comparator  comptag1
(
   .tag_incache(t1_out),
	.tag_inaddr(tag),
	.tag_equal(tag_equal1)
);
tag_comparator  comptag2
(
	.tag_incache(t2_out),
	.tag_inaddr(tag),
	.tag_equal(tag_equal2)
);
mux2 #(.width(128)) picksdatafromhit
(
	.sel(comp2),
	.a(data1_out),
	.b(data2_out),
	.f(outdata_128)
);
word_decoder word_decoder
(
	.indata_128(outdata_128),
	.offset(small_offset),
	.outdata_16(mem_rdata)
);
maskwrite maskwrite
(
	.indata_128(outdata_128),
	.offset(small_offset),
	.write(mem_write),  
	.mem_byte_enable(mem_byte_enable),
	.mem_wdata(mem_wdata),
	.written_128(written_128)
);
mux2 #(.width(128)) whichwrite 
(
	.sel(allocate_sel),
	.a(written_128),
	.b(pmem_rdata),
	.f(write_this_back) 
);/*
mux2 #(.width(1)) dirtypick
(
	.sel(comp2),
	.a(d1_out),
	.b(d2_out),
	.f(dirty)
); */
/*
mux2 #(.width(1)) validpick
(
	.sel(comp2),
	.a(v1_out),
	.b(v2_out),
	.f(valid)
);*/
mux2 #(.width(9)) tagpicker 
(
	.sel(LRU_out),
	.a(t1_out),
	.b(t2_out),
	.f(tag_out)
);
concatenate concatenate
(
	.tag(tag_out),
	.index(index),
	.new_addr(new_addr)
);
mux2 #(.width(1)) dirtyLRU //for addrpicker only 
(
	.sel(LRU_out),
	.a(d1_out),
	.b(d2_out),
	.f(dirty_LRU)
);
mux2 addrpicker
(
	.sel(addrpicker_sel),
	.a(mem_address),
	.b(new_addr),
	.f(pmem_address)
);
//=====================way 1==============================================
array #(.width(1))valid1
(
    .clk(clk),
    .write(v1_write),
    .index(index),
    .datain(v1_in),
    .dataout(v1_out)
); 
array #(.width(1))dirty1
(
    .clk(clk),
    .write(d1_write),
    .index(index),
    .datain(d1_in),
    .dataout(d1_out)
); 
array #(.width(9))tag1
(
    .clk(clk),
    .write(t1_write),
    .index(index),
    .datain(tag),
    .dataout(t1_out)
); 
array data1
(
    .clk(clk),
    .write(data1_write),
    .index(index),
    .datain(write_this_back),
    .dataout(data1_out)
); 
//========================================================================
//=====================way 2==============================================
array #(.width(1))valid2
(
    .clk(clk),
    .write(v2_write),
    .index(index),
    .datain(v2_in),
    .dataout(v2_out)
); 
array #(.width(1))dirty2
(
    .clk(clk),
    .write(d2_write),
    .index(index),
    .datain(d2_in),
    .dataout(d2_out)
); 
array #(.width(9))tag2
(
    .clk(clk),
    .write(t2_write),
    .index(index),
    .datain(tag),
    .dataout(t2_out)
); 
array data2
(
    .clk(clk),
    .write(data2_write),
    .index(index),
    .datain(write_this_back),
    .dataout(data2_out)
); 
//======================================================================


endmodule: cache_datapath
