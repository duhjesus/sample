import lc3b_types::*; /* Import types defined in lc3b_types.sv */
//the cache controller. It is a state machine that controls the behavior of the cache.
module cache_control
(
	 input clk,
	 //input lc3b_word mem_rdata,
	 input logic comp2,
	 input logic LRU_out,
	 //input logic valid,
	 //input logic dirty,
	 input logic dirty_LRU,
	 input logic hit,	 
	 input logic pmem_resp,
	 input logic mem_read,
	 input logic mem_write,
	 input lc3b_128 data1_out,
	 input lc3b_128 data2_out,
	 //
	 output logic LRU_in, LRU_write,
	 output logic allocate_sel,
	 output logic v1_write,v1_in,d1_write,d1_in,t1_write,data1_write,
	 output logic v2_write,v2_in,d2_write,d2_in,t2_write,data2_write,
	 output logic mem_resp,
	 output logic pmem_read,
	 output logic pmem_write,
	 output lc3b_128 pmem_wdata
);
enum int unsigned {
    /* List of states */
	 idlehit, 
	 allocate,
	 write_back
} state, next_state;

always_comb
begin : state_actions
  /* Default output assignments */ 
  //signal =1'b0
  	 LRU_in=0;// ***********  means must write input at every step to insure correctness 
	 v1_write=0;
	 v1_in=0;//***********
	 d1_write=0;
	 d1_in=0;//***********
	 t1_write=0;
	 data1_write=0;
	 v2_write=0;
	 v2_in=0;//***********
	 d2_write=0;
	 d2_in=0;//***********
	 t2_write=0;
	 data2_write=0;
	 mem_resp=0;
	 pmem_read=0;
	 pmem_write=0;	
	 allocate_sel=0; 
	 pmem_wdata=data1_out;
	 LRU_write=0;
  /* Actions for each state */
	case(state)
		idlehit: begin 
		/* set signals specific to this state */ 
		//idle
		if((~mem_read && ~mem_write) || (mem_read && mem_write))
			begin 
			v1_write=0;
			d1_write=0;
			t1_write=0;
			data1_write=0;
			v2_write=0;
			d2_write=0;
			t2_write=0;
			data2_write=0;			
			pmem_read=0;
			pmem_write=0;
			mem_resp=0;			
			end 
		//read hit 
		else if(mem_read && hit) // hit means its valid and in cache 
			begin 
			v1_write=0;
			d1_write=0;
			t1_write=0;
			data1_write=0;
			v2_write=0;
			d2_write=0;
			t2_write=0;
			data2_write=0;			
			pmem_read=0;
			pmem_write=0;
			if(comp2)//way 2 was recently used 
				begin
 				LRU_in=0; //set LRU to way 1
				LRU_write=1;
				end 
			else
				begin
				LRU_in=1; //set LRU to way 2
				LRU_write=1;	
				end 
			mem_resp=1;	 //tell CPU memory ready;it can read mem_rdata now
			end 
		//write hit 
		else if(mem_write && hit) //when writing a line you make dirty bit=1
			begin 
			if(comp2)//the hit was in way 2 
				begin 
				v2_in=1;
				v2_write=1; //if it was a hit valid should be 1 already 
				d2_in=1;
				d2_write=1;				
				t2_write=1; //tag coming from mem_address 
				data2_write=1;//data in handled by hardware 
				allocate_sel=0;//datain will be from mask write block	
				LRU_in=0;//least recently used was way 1
				LRU_write=1;
				end 
			else //the hit was in way 1
				begin 
				v1_in=1;
				v1_write=1;
				d1_in=1;
				d1_write=1;
				t1_write=1;
				data1_write=1;
				allocate_sel=0;
				LRU_in=1;//least recently used was way 2
				LRU_write=1;
				end 
			
			mem_resp=1; //let the cpu know cache memory ready 
			pmem_read=0;//don't tell cpu anything
			pmem_write=0;	
			end 
		/*
		//read miss
	   else if(mem_read && ~hit)
			 
		//read miss clean 
		
		//read miss dirty 
			 
	   //write miss dirty 				
		
	    */ 
		end 
		allocate:begin //read new block from physical mem to cache mem 
			pmem_read=1;//tell physical memory that cache wants to read data from pmem_rdata
			allocate_sel=1; //read the pmem_rdata 
			if(!LRU_out)//if LRU =0 then way 1 will be overwritten 
				begin 
				data1_write=1;
				t1_write=1;
				d1_in=0;//not dirty 
				d1_write=1;
				v1_in=1;//is valid,b/c i wrote it 
				v1_write=1;
				//LRU_in=~LRU_out;//
				end 
			else //LRU =1 overwrite way 2 
				begin 
				data2_write=1;
				t2_write=1;
				d2_in=0;//not dirty 
				d2_write=1;
				v2_in=1;//is valid,b/c i wrote it 
				v2_write=1;
				//LRU_in=~LRU_out;				
				end 				
		end 
		write_back:begin 
			//LRU_write is hit so lru_in doesnt matter 
			v1_write=0; //the in's for these were not written 
			d1_write=0; //bc the writes=0 are preventing anything from
			t1_write=0; //going into the array so doesnt matter
			data1_write=0;
			v2_write=0;
			d2_write=0;
			t2_write=0;
			data2_write=0;
			mem_resp=0;
			pmem_read=0;
			allocate_sel=0; //doesnt matter datax_write=0
			if(LRU_out)//if LRU =1 then way 1 will be overwritten 
				pmem_wdata=data1_out;
			else
				pmem_wdata=data2_out;
			
			pmem_write=1;//tell physical memory cache wants to write 
		end 
	endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */	
	   next_state=state;
		case(state)
			idlehit:begin 
					 if((mem_read || mem_write)  && dirty_LRU && !hit )  
						next_state=write_back; 
					 else if((mem_read || mem_write) && !dirty_LRU && !hit ) 
					   next_state=allocate;
					 else if (mem_read || mem_write ||hit)//( ((mem_read || mem_write) && !(mem_read && mem_write)) || hit) // mem_read xor mem_read  or hit 
						next_state=idlehit; 						
					  end	
		   allocate:begin 
						if(pmem_resp==0)
						  next_state=allocate;
						else 
						  next_state=idlehit;
						end 
			write_back:begin 
						  if(pmem_resp==0)
							next_state=write_back;
						  else
							next_state=allocate;
						  end 
		endcase 
end	
	
always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <=next_state;
end

endmodule : cache_control
