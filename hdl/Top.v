`timescale 1ns / 1ps
module  Top(
	input				reset,
	input				clk4,
	input				IDE_CS,
	output			dna_pass,
	output [3:0]	KILL
);


wire [63:0] dna64bits;
wire dna_valid;

wire	SR_ena;

wire [9:0] addra;
wire [15:0] douta;

// constant holder for RAM implementation
// begin
//wire [15:0] dina;
//wire wea;
// end of constant holder

dna_p1 inst_ReadDNA(
	.ATV(~reset),				// Active and arm signal
   .CLK4(clk4),					// very fast clock
   .DNA_64(dna64bits),		// 64 bit DNA code with check bits
   .DNA_Valid(dna_valid)	// the code now is valid
);
	 
CheckDNA inst_CheckDNA (
	.clk4			(clk4),
	.reset		(reset),
	.DNA_64		(dna64bits),			// The DNA code
	.dna_valid	(dna_valid),

	.ROM_Data	(douta),					// ROM data
	.IDE_CS		(IDE_CS),				// chip select
	.DNA_ENA		(SR_ena),				// the enable signal to reduce power consumption
	.DNA_REG		(SR_reg),				// enable output register for faster RAM access
	.DNA_Addr	(addra),					// RAM address

	.dna_pass	(dna_pass),				// result of check
	.KILL			(KILL)						// Killing signals
);

// Inst as block ROM
// begin
RAM inst_RAM (
	.clka(clk4),
	.addra(addra),
	.ena(SR_ena),					// 1 serial register
	.regcea(SR_reg),
	.douta(douta));
// end of block ROM

// Inst as block RAM
// begin
//RAM inst_RAM (
//	.clka(clk4),
//	.ena(SR_ena),
//	.regcea(SR_reg),
//	.wea(wea), // Bus [0 : 0] 
//	.addra(addra), // Bus [9 : 0] 
//	.dina(douta), // Bus [15 : 0] 
//	.douta(douta)); // Bus [15 : 0] 

//assign dina = 16'b0000_0000_0000_0000;	// no dangling pins
//assign wea = 1'b0;				// no writing
// end of block RAM
endmodule			
			
			
			
			
			
		
		
		
		
	
