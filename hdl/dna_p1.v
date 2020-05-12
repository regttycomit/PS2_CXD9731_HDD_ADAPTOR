`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:48:37 03/14/2009 
// Design Name: 
// Module Name:    dna_p1 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module dna_p1(
    input ATV,					// Active and arm signal
    input CLK4,				// very fast clock
    output [63:0] DNA_64,		// 64 bit DNA code with check bits
    output reg DNA_Valid	// the code now is valid
);

reg 		dna_read,dna_shift,dna_clk;
wire 		dna_out;
reg	[5:0]	dna_counter;	// a six bit counter for the dna
reg	[3:0]	dna_ST;		// 4 bit state machine
reg	[5:0]	Adder1;		// a six bit result of bit adding
reg	Parity;				// a one bit result of parity
reg	[56:0] DNA_R;

DNA_PORT	#(
//		.SIM_DNA_VALUE(57'b100011100001110000111010011010100000111001001000111110001)

//	board6 dna = 01EB D518 35FC 6A8
// In Hex VALUE(57'b0000_0001_1110_1011_1101_0101_0001_1000_0011_0101_1111_1100_0110_1010_1)
		.SIM_DNA_VALUE(57'b101010110001111111010110000011000101010111101011110000000)
//	board5 dna = 8139 68AB EA9A 7A8
// In Hex  VALUE(57'b1000 0001 0011 1001 0110 1000 1010 1011 1110 1010 1001 1010 0111 1010 1)
//		.SIM_DNA_VALUE(57'b101011110010110010101011111010101000101101001110010000001)
//	board1 dna = 4AA7 56E8 BE70 9A8
// In Hex  VALUE(57'b0100 1010 1010 0111 0101 0110 1110 1000 1011 1110 0111 0000 1001 1010 1)
//   .SIM_DNA_VALUE(57'b101011001000011100111110100010111011010101110010101010010)
//	board2 dna = D891 1863 FA0F 4A8
// In Hex  VALUE(57'b110110001001000100011000011000111111101000001111010010101)
// .SIM_DNA_VALUE(57'b101010010111100000101111111000110000110001000100100011011)
//	board3 dna = A2B6 540A 9221 088
// In Hex  VALUE(57'b1010_0010_1011_0110_0101_0100_0000_1010_1001_0010_0010_0001_0000_1000_1)
//.SIM_DNA_VALUE(57'b1_0001_0000_1000_0100_0100_1001_0101_0000_0010_1010_0110_1101_0100_0101)
//	board4 dna = E070 9EE6 453D CA8
// In Hex  VALUE(57'b111000000111000010011110111001100100010100111101110010101)
//  .SIM_DNA_VALUE(57'b101010011101111001010001001100111011110010000111000000111)
		) dna_code(
		.DIN(1'b0),
		.READ(dna_read),
		.SHIFT(dna_shift),
		.DOUT(dna_out),
		.CLK(dna_clk)		
		);

//
// DNA raw 57  = 1000_1111_1000_1001_0011_1000_0010_1011_0010_1110_0001_1100_0011_1000_1
//					= 8F89382B2E1C38xx
// adder will be 26(1'b1)	= 011010
// Parity is     odd			= 26(1'b1)(raw) + 3(1'b1)adder = odd = 1
//
parameter DnIdle	= 4'b0000;
parameter Dn01		= 4'b0001;
parameter Dn02		= 4'b0011;
parameter Dn03		= 4'b0010;
parameter Dn04		= 4'b0110;
parameter Dn10		= 4'b0111;
parameter Dn11		= 4'b0101;
parameter Dn12		= 4'b0100;
parameter Dn13		= 4'b1100;
parameter Dn20		= 4'b1101;
parameter Dn99		= 4'b1111;


assign	DNA_64[63:7] = DNA_R[56:0];
assign	DNA_64[6:1]	 = Adder1[5:0];
assign	DNA_64[0]	 = Parity;

always @(posedge CLK4) begin
if (ATV == 1'b0) begin
	dna_read		<= 0;
	dna_shift	<= 0;
	dna_clk		<= 0;
	dna_counter	<= 6'b00_0000;
	Adder1		<= 6'b00_0000;
	Parity		<= 1'b0;
	DNA_Valid	<= 1'b0;			// always not valid yet
	dna_ST		<= DnIdle;		// always idle now
end else begin
//// ========= State machine default state ======
	case (dna_ST)
	DnIdle: begin
		dna_read		<= 0;
		dna_shift	<= 0;
		dna_clk		<= 0;
		dna_counter	<= 6'b00_0000;
		Adder1		<= 6'b00_0000;
		Parity		<= 1'b0;
		DNA_Valid	<= 1'b0;			// always not valid yet
		dna_ST		<= Dn01;
	end
	Dn01	: begin
		dna_read		<= 1;			// raise the read port
		dna_ST		<= Dn02;
	end
	Dn02	: begin
		dna_clk		<= 1;			// rising edge of pulse, will clock the DNA port
		dna_ST		<= Dn03;
	end
	Dn03	: begin
		dna_clk		<= 0;			// remove clock pulse
		dna_ST		<= Dn04;
	end
	Dn04	: begin
		dna_read		<= 0;			// remove read signal, bit 57 will be in the output port
		dna_shift	<= 1;			// enable shift signal
		dna_ST		<= Dn10;
	end
//// =========== shift the DNA raw data now =======================
	Dn10	: begin
		DNA_R[55:0]	<= DNA_R[56:1];	// shift the register
		DNA_R[56]	<= dna_out;			// shift the register
		if (dna_out == 1'b1) begin
			Adder1	<= Adder1 + 1;
			Parity	<= ~Parity;
		end
		dna_ST		<= Dn11;
	end
	Dn11	: begin
		dna_counter	<= dna_counter + 1;		// add the counter
		dna_ST		<= Dn12;
	end
	Dn12	: begin
		dna_clk		<= 1'b1;			// rising edge
		dna_ST		<= Dn13;
	end
	Dn13	: begin
		dna_clk		<= 1'b0;			// falling edge
		if (dna_counter == 6'b11_1001) begin		// check 57 for 57 data
			dna_ST	<= Dn20;
		end else begin
			dna_ST	<= Dn10;					// loop back for the data
		end
	end
//// =========== compute final Parity now =======================
	Dn20	: begin
		Parity		<= Parity ^ Adder1[5] ^ Adder1[4] ^ Adder1[3] ^ Adder1[2] ^ Adder1[1] ^ Adder1[0];
		dna_ST		<= Dn99;
	end
//// =========== parity out now =======================
	Dn99	: begin
		DNA_Valid	<= 1'b1;			// say valid
		dna_ST		<= Dn99;			// loop forever
	end
//// ============================================
	default: begin
		dna_ST 		<= DnIdle;		// jump to idle for rouge states
	end
	endcase
end // ATV
end // clock edges
	
endmodule
