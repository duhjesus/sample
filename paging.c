#include "lib.h"
#include "types.h"
#include "paging.h"

#define NULL_ADDR   0x00000000
#define VIDMEM_ADDR 0x000B8000
#define KERNEL_ADDR 0x00400000
#define PROGRAM_ADDR 0x08000000

#define PDI(n)  ((n & 0xFFC00000) >> 22) 	//parse a given linear address n for the given page directory index (pdi)
#define PTI(n) 	((n & 0x003FF000) >> 12) 	//parse a given linear address n for the given page table index (pti)
#define KB(n) 	(0x400*n) 	//convert n KB to bytes

#define PRESENT 	0x00000001 	//enable present
#define READ_WRITE 	0x00000002 	//enable read_write
#define USER 		0x00000004	//enable to user mode
#define BIG_PAGE	0x00000080 	//enable as big page 4MB
#define MAX_FILES 	6 //max number of files

#define STANDARD_TABLE (PRESENT | READ_WRITE) 	//initialize standard table entry as present and enabled r/w
#define STANDARD_DIR 	(BIG_PAGE | PRESENT | READ_WRITE)

static unsigned int dir[1024] __attribute__((aligned(KB(4)))); // page directory aligned by 4 KB with max of 1024 entries
static unsigned int table[1024] __attribute__((aligned(KB(4)))); 	//page table aligned by 4 KB with max of 1024 entries
static unsigned int table2[1024] __attribute__((aligned(KB(4)))); 	//page table aligned by 4 KB with max of 1024 entries

/*
 * 	enable_paging 
 *   DESCRIPTION: function initializes the paging
 *   INPUTS: none
 *   OUTPUTS:none
 *   RETURN VALUE: none 
 *   SIDE EFFECTS: sets up the page mapping for the null,video memory in page direcotry 0 and kernel in page directory 1
 */ 
void enable_paging() {

	int i;
	//initializes values for each entry in page directory
	for (i=0; i<1024; i++) {
		dir[i] = (NULL_ADDR | READ_WRITE); 	//enable read/write
	}
	//initializes values for each entry in page table
	for (i=0; i<1024; i++) {
		table[i] = (((i*KB(4)) | READ_WRITE) & !(PRESENT)); 	//make each entry (spaced out by 4KB) r/w enabled and not present
	}

	//map null and video memory
	dir[0] = ( ((unsigned int)table) | STANDARD_TABLE ); 	//link directory entry to table and initialize to standard table entry
	table[PTI(VIDMEM_ADDR)] = (VIDMEM_ADDR | STANDARD_TABLE); 	//link table entry to video memory address and initialize to standard table entry
	table[PTI(VIDMEM_ADDR)+1] = ((VIDMEM_ADDR+KB(4)) | STANDARD_TABLE); 	//link table entry to video memory address and initialize to standard table entry
	table[PTI(VIDMEM_ADDR)+2] = ((VIDMEM_ADDR+2*KB(4)) | STANDARD_TABLE); 	//link table entry to video memory address and initialize to standard table entry


	//kernel
	dir[1] = KERNEL_ADDR | BIG_PAGE | READ_WRITE | PRESENT; 	//4MB, supervisor, R/W enabled, present 

	//enable paging in assembly through registers
	asm volatile ( "movl %0, %%eax \n\
		movl %%eax, %%cr3 \n\
		movl %%cr4, %%eax \n\
		orl $0x00000010, %%eax \n\
		movl %%eax, %%cr4 \n\
		movl %%cr0, %%eax \n\
		orl $0x80000001, %%eax \n\
		movl %%eax, %%cr0"
        : /*blah*/
        : "r"(dir)
        : "eax", "cc"
	);

}
/*
 * 	update_prog 
 *   DESCRIPTION: remaps the memory for each program and flushes the TLB when done initializing the paging
 *   INPUTS: the physical addr of program
 *   OUTPUTS: none
 *   RETURN VALUE: none
 *   SIDE EFFECTS: sets up paging for program you just want to execute or returns the paging back to the parent process that called yourr program
 */ 
void update_prog(uint32_t phys_addr) {
	int pdi = PDI(PROGRAM_ADDR);									//find the index into the program directory
	dir[pdi] = phys_addr | BIG_PAGE | USER | READ_WRITE | PRESENT; 	//initialze to a big page, user mode, present, and read/write mode
	//flush TLB
	asm volatile ("movl	%%cr3, %%eax \n\
		movl %%eax, %%cr3"
		: /*no outputs*/
		: /*no inputs*/
		: "eax"
	);
}

/*
 * 	video_map 
 *   DESCRIPTION: remaps the memory for vidmap to user space and flushes the TLB
 *   INPUTS: none
 *   OUTPUTS: none
 *   RETURN VALUE: none
 *   SIDE EFFECTS: sets up paging for user space vidmap
 */ 
void video_map(int32_t term_num)
{
	dir[33] = ( ((unsigned int)table2) | STANDARD_TABLE | USER);  	//chose pdi to be next after program pdi
	table2[0] = ((VIDMEM_ADDR + term_num*KB(4)) | STANDARD_TABLE | USER); 	//link table entry to video memory address and initialize to standard table entry
	//Flushing the TLB 
	asm volatile ("movl	%%cr3, %%eax \n\
		movl %%eax, %%cr3"
		: /*no outputs*/
		: /*no inputs*/
		: "eax"
	);
}

