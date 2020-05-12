`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:53:31 03/10/2009 
// Design Name: 
// Module Name:    CheckDNA 
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
module CheckDNA(
input				clk4,
input				reset,
input [63:0] 	DNA_64,			// The DNA code
input 			dna_valid,

input [15:0]	ROM_Data,		// ROM data
input				IDE_CS,			// chip select killer signal
output reg		DNA_ENA,				// the enable signal to reduce power consumption
output reg		DNA_REG,				// enable output register for faster RAM access
output reg [9:0]	DNA_Addr,			// RAM address

output			dna_pass,		// result of check
output [3:0]	KILL					// Killing signals
);

// Result of check
// DNA_FailR[0] = set to 1 if (XOR check sum is not zero) or (DNA address in [1018-1022] does not match with local DNA)
// DNA_FailR[1] = set to 1 if {DNA address in [1018-1022] not match with local DNA)
// DNA_FailR[2] = set to 1 if (
// DNA_FailR[3] = set to 1 if
// parameter no_of_ran_no = 1021; // for server1104
parameter no_of_ran_no = 1016;	// For Server1108

reg	[15:0]	xor_check;		// overall check key of the XOR 
reg	[63:0]	dna;				// local dna code	
reg	[9:0]		L_Addr;		// the addres of the check code
reg	[15:0]	check;			// the content of the check code
reg	multi_ce;				// enable the multiplier signal
reg [4:0]  dna_gen_st;		// dna state machine
reg	[3:0]		DNA_FailR;		// dna failing reigster

parameter DcIdle	= 5'b00000;
parameter Dc01		= 5'b00001;
parameter Dc02		= 5'b00010;
parameter Dc03		= 5'b00011;
parameter Dc04		= 5'b00100;
parameter Dc10		= 5'b00101;
parameter Dc11		= 5'b00110;
parameter Dc12		= 5'b00111;
parameter Dc13		= 5'b01000;
parameter Dc14		= 5'b01001;
parameter Dc20		= 5'b01010;
parameter Dc21		= 5'b01011;
parameter Dc22		= 5'b01100;
parameter Dc23		= 5'b01101;
parameter Dc24		= 5'b01110;
parameter Dc25		= 5'b01111;
parameter Dc26		= 5'b10000;
parameter Dc27		= 5'b10001;
parameter Dc28		= 5'b10010;
parameter Dc29		= 5'b10011;
parameter Dc30		= 5'b10100;
parameter Dc31		= 5'b10101;
parameter Dc32		= 5'b10110;
parameter Dc33		= 5'b10111;
parameter Dc34		= 5'b11000;
parameter Dc35		= 5'b11001;
parameter Dc90		= 5'b11010;
parameter Dc91		= 5'b11011;
parameter Dc92		= 5'b11100;

reg	[15:0] multi_a;
reg	[15:0] multi_b;
reg	[15:0] Simp_XOR;		// simple XOR register
reg	FinishCheck;			// flip flop to show checking is finished
wire	[15:0] multi_p;		// output of register
wire	[15:0] ma;				// input feed of multi_a
wire	[15:0] mb;				// input feed of multi_b
wire	K_WINDOW;				// wire key window

///////////////////////////////////////////////////////////////

multi_16 inst_multi_16 (
	.ce(multi_ce),
	.clk(clk4),
	.a(multi_a), // Bus [15 : 0] 
	.b(multi_b), // Bus [15 : 0] 
	.p(multi_p)); // Bus [15 : 0] 

// Server1104 = algorithm
//Multi_A = XOR_REG(	DNA_64(18,24) + DNA_64(26,28) + DNA_64(30,32) + DNA_64(33,39)),
//							Multi_P(0,6) + Multi_P(8, 10) + Multi_P(6, 8) + Multi_P(10, 16));
//Multi_B = XOR_REG(ROM_Data(0,16), DNA_64(48,64));
//assign ma[15:10]	= multi_p[15:10]	^ dna[45:40];		// Multi_P(0,6) ^ DNA_64(18,24)
//assign ma[9:8]		= multi_p[7:6]		^ dna[37:36];		// Multi_P(8,10) ^ DNA_64(26,28)
//assign ma[7:6]		= multi_p[9:8]		^ dna[33:32];		// Multi_P(6,8) ^ DNA_64(30,32)
//assign ma[5:0]		= multi_p[5:0]		^ dna[30:25];		// Multi_P(10,16) ^ DNA_64(33,39)
//assign mb[15:0]	= ROM_Data[15:0]	^ dna[15:0];		// ROM_Data(0,16) ^ DNA_64(48,64)

// Server1108 = algorithm
//Multi_A = XOR_REG(	DNA_64(16,22) + DNA_64(26,28) + DNA_64(30,32) + DNA_64(33,39)),
//							Multi_P(0,6) + Multi_P(8, 10) + Multi_P(6, 8) + Multi_P(10, 16));
//Multi_B = XOR_REG(ROM_Data(0,16), DNA_64(44,60));
assign ma[15:10]	= multi_p[15:10]	^ dna[47:42];		// Multi_P(0,6) ^ DNA_64(16,22)
assign ma[9:8]		= multi_p[7:6]		^ dna[37:36];		// Multi_P(8,10) ^ DNA_64(26,28)
assign ma[7:6]		= multi_p[9:8]		^ dna[33:32];		// Multi_P(6,8) ^ DNA_64(30,32)
assign ma[5:0]		= multi_p[5:0]		^ dna[30:25];		// Multi_P(10,16) ^ DNA_64(33,39)
assign mb[15:0]	= ROM_Data[15:0]	^ dna[20:4];		// ROM_Data(0,16) ^ DNA_64(44,60)

/////////////////////// Killing signals ////////////////////
assign	KILL[0]	=  DNA_FailR[0];			// Fail register to output the signal
assign	KILL[1]	= ~DNA_FailR[0] & DNA_FailR[1] & K_WINDOW & Simp_XOR[2];		// If someone modify the Fail 0, then we create new fail for them
assign	KILL[2]	= ~DNA_FailR[0] & ~DNA_FailR[1] & DNA_FailR[2] & K_WINDOW & ~Simp_XOR[2];
assign	KILL[3]	= ~DNA_FailR[0] & ~DNA_FailR[1] & DNA_FailR[3] & K_WINDOW &  Simp_XOR[2];
assign	K_WINDOW	= Simp_XOR[9] & Simp_XOR[8] & ~Simp_XOR[7] & Simp_XOR[6] & ~Simp_XOR[5] & ~Simp_XOR[3];
assign	dna_pass	= FinishCheck & ~DNA_FailR[3] & ~DNA_FailR[2] & ~DNA_FailR[1] & ~DNA_FailR[0];

always @(posedge clk4) begin
	if(reset) begin
		DNA_Addr		<= 10'b00_0000_0000;		// address of ROM_Data
		L_Addr	<= 10'b00_0000_0000;		// address of check_code
		xor_check 	<= 16'b0000_0000_0000_0000;	// the XOR A bus check code
		multi_a	 	<= 16'b0000_0000_0000_0000;	// the two multipliers check code
		multi_b	 	<= 16'b0000_0000_0000_0000;	// the two multipliers bus check code
		Simp_XOR		<= 16'b0000_0000_0000_0000;	// simple XOR register
		DNA_FailR	<= 4'b0000;							// clear the fail register
		FinishCheck	<= 1'b0;								// clear the check phase
		DNA_ENA		<= 1'b0;
		DNA_REG		<= 1'b0;
		multi_ce		<= 1'b0;
		dna_gen_st	<= DcIdle;			// start in the idle state
	end else begin
		case(dna_gen_st)
//// ===== state 0, wait until dna code is valid ============
//// Formulate a dna_check_key to combat zero code attack
		DcIdle	: begin
			if(dna_valid == 1'b1) begin
				dna_gen_st	<= Dc01;
			end
		end
		Dc01	: begin
			DNA_ENA		<= 1'b1;			// enable reading the ROM
			multi_ce	<= 1'b1;			// flush the multiplier with 0s
			dna		<= DNA_64;			// clock in the main register
			dna_gen_st	<= Dc02;
		end
		Dc02	: begin
			DNA_ENA		<= 1'b0;			// disable reading the ROM
			DNA_REG		<= 1'b1;			// fetch first ROM data to bus
			dna_gen_st	<= Dc03;
		end
		Dc03	: begin
			DNA_REG		<= 1'b0;
			dna_gen_st	<= Dc04;
		end
		Dc04	: begin
			multi_ce				<=  1'b0;			// multiplier completely flushed
			multi_a[15:0]		<=  ma[15:0];
			multi_b[15:0]		<=  mb[15:0];
			L_Addr[9]		<= ~mb[10];			// mult address is stable now
			L_Addr[8:0]	<=  mb[10:2];		// check address is between 256-767
			dna_gen_st			<=  Dc10;				// go to the main loop
		end
//// ====== Check on the data block ===========
	Dc10: begin
		DNA_REG		<= 1'b0;
		dna_gen_st	<= Dc11;			// next state
	end	
	Dc11: begin
		multi_ce			<= 1'b1;
		multi_a[15:0]	<= ma[15:0];			// activate the multipliers
		multi_b[15:0]	<= mb[15:0];
		dna_gen_st		<= Dc12;			// next state
	end	
	Dc12:	begin
		dna[63:1]		<= dna[62:0];
		dna[0]			<= dna[63] ^ ROM_Data[1];	// bitwise rotate the data
		DNA_ENA			<= 1'b0;							// save power for the ROM
		if (DNA_Addr == L_Addr)	check <= multi_a;	// store up the value of check instance
		DNA_Addr			<= DNA_Addr + 1;					// proceed to next address
		Simp_XOR[15:0]	<= Simp_XOR[15:0] ^ ROM_Data[15:0];		// mask the registers
		xor_check		<= xor_check ^ multi_b;		// the xor algorithm is base on dna XOR ROM_Data
		dna_gen_st		<= Dc13;
	end
	Dc13:	begin
		DNA_ENA			<= 1'b1;							// enable back the ROM
		dna_gen_st		<= Dc14;
	end
	Dc14:	begin
		DNA_ENA			<= 1'b0;							// disable ROM access
		DNA_REG			<= 1'b1;							// enable back the ROM and reg
		if (DNA_Addr == no_of_ran_no) begin
			DNA_Addr			<= DNA_Addr + 1;					// advance the address
			dna_gen_st 	<= Dc20;							// go to the result phase
		end else begin
			dna_gen_st	<= Dc10;							// loop back for new computation
		end
	end
//// ======================================================
	Dc20	: begin											// DNA_Addr = 1016
		multi_ce			<= 1'b0;							// save some power
		DNA_REG			<= 1'b0;							// lock down the reg
		DNA_ENA			<= 1'b1;							// clock out the data to register side
		dna_gen_st		<= Dc21;
	end
	Dc21	: begin
		Simp_XOR[15:0]	<= Simp_XOR[15:0] ^ ROM_Data[15:0];		// mask the registers
		if (multi_a != ROM_Data) begin
			DNA_FailR[3]	<= 1'b1;						// 3rd level fail
		end
		DNA_REG			<= 1'b1;							// clock out the data to compare
		DNA_ENA			<= 1'b0;							// lock down the RAM area
		DNA_Addr				<= DNA_Addr+1;						// pipe the new address 1017 to RAM
		dna_gen_st		<= Dc22;
	end
	Dc22	: begin											// DNA_Addr = 1017
		DNA_REG			<= 1'b0;							// lock down the reg
		DNA_ENA			<= 1'b1;							// clock out the data to register side
		dna_gen_st		<= Dc23;
	end
	Dc23	: begin
		Simp_XOR[15:0]	<= Simp_XOR[15:0] ^ ROM_Data[15:0];		// mask the registers
		if (xor_check != ROM_Data) begin
			DNA_FailR[2]	<= 1'b1;						// 2nd level fail
		end
		DNA_REG			<= 1'b1;							// clock out the data to compare
		DNA_ENA			<= 1'b0;							// lock down the RAM area
		DNA_Addr				<= DNA_Addr+1;						// pipe the new address to RAM
		dna_gen_st		<= Dc24;
	end
////////
	Dc24	: begin											// DNA_Addr = 1018
		DNA_REG			<= 1'b0;							// lock down the reg
		DNA_ENA			<= 1'b1;
		dna_gen_st		<= Dc25;
	end
	Dc25	: begin											// DNA_Addr = 1018
		Simp_XOR[15:0]	<= Simp_XOR[15:0] ^ ROM_Data[15:0];		// mask the registers
		if (check != ROM_Data) begin
			DNA_FailR[1]	<= 1'b1;						// set the general fail
		end
		DNA_REG			<= 1'b1;							// clock out the data to compare
		DNA_ENA			<= 1'b0;							// lock down the RAM area
		DNA_Addr			<= DNA_Addr+1;						// pipe the new address to RAM
		dna_gen_st		<= Dc26;
	end
//////////
	Dc26	: begin											// DNA_Addr = 1019
		DNA_REG			<= 1'b0;							// lock down the reg
		DNA_ENA			<= 1'b1;
		dna_gen_st		<= Dc27;
	end
	Dc27	: begin											// DNA_Addr = 1019
		Simp_XOR[15:0]	<= Simp_XOR[15:0] ^ ROM_Data[15:0];		// mask the registers
		if (DNA_64[63:48] != ROM_Data[15:0]) begin
			DNA_FailR[0]	<= 1'b1;
		end
		DNA_REG			<= 1'b1;							// clock out the data to compare
		DNA_ENA			<= 1'b0;							// lock down the RAM area
		DNA_Addr				<= DNA_Addr+1;						// pipe the new address to RAM
		dna_gen_st		<= Dc28;
	end
//////////
	Dc28	: begin											// DNA_Addr = 1020
		DNA_REG			<= 1'b0;							// lock down the reg
		DNA_ENA			<= 1'b1;
		dna_gen_st		<= Dc29;
	end
	Dc29	: begin											// DNA_Addr = 1020
		Simp_XOR[15:0]	<= Simp_XOR[15:0] ^ ROM_Data[15:0];		// mask the registers
		if (DNA_64[47:32] != ROM_Data[15:0]) begin
			DNA_FailR[0]		<= 1'b1;
		end
		DNA_REG			<= 1'b1;							// clock out the data to compare
		DNA_ENA			<= 1'b0;							// lock down the RAM area
		DNA_Addr				<= DNA_Addr+1;						// pipe the new address to RAM
		dna_gen_st		<= Dc30;
	end
//////////
	Dc30	: begin											// DNA_Addr = 1021
		DNA_REG			<= 1'b0;							// lock down the reg
		DNA_ENA			<= 1'b1;
		dna_gen_st		<= Dc31;
	end
	Dc31	: begin											// DNA_Addr = 1021
		Simp_XOR[15:0]	<= Simp_XOR[15:0] ^ ROM_Data[15:0];		// mask the registers
		if (DNA_64[31:16] != ROM_Data[15:0]) begin
			DNA_FailR[0]	<= 1'b1;
		end
		DNA_REG			<= 1'b1;							// clock out the data to compare
		DNA_ENA			<= 1'b0;							// lock down the RAM area
		DNA_Addr				<= DNA_Addr+1;						// pipe the new address to RAM
		dna_gen_st		<= Dc32;
	end
//////////
	Dc32	: begin											// DNA_Addr = 1022
		DNA_REG			<= 1'b0;							// lock down the reg
		DNA_ENA			<= 1'b1;							// read from ram
		dna_gen_st		<= Dc33;
	end
	Dc33	: begin											// DNA_Addr = 1022
		Simp_XOR[15:0]	<= Simp_XOR[15:0] ^ ROM_Data[15:0];		// mask the registers
		if (DNA_64[15:0] != ROM_Data[15:0]) begin
			DNA_FailR[0]	<= 1'b1;
		end
		DNA_REG			<= 1'b1;							// clock out the data to compare
		DNA_ENA			<= 1'b0;							// lock down the RAM area
//		DNA_Addr				<= DNA_Addr+1;						// pipe the new address to RAM
		dna_gen_st		<= Dc34;
	end
//////////
	Dc34	: begin											// DNA_Addr = 1023
		DNA_REG			<= 1'b0;							// lock down the reg
//		DNA_ENA			<= 1'b1;
		dna_gen_st		<= Dc35;
	end
	Dc35	: begin											// DNA_Addr = 1023
		if (Simp_XOR[15:0] != ROM_Data[15:0]) begin
			DNA_FailR[0]	<= 1'b1;
		end
//		DNA_REG			<= 1'b1;							// clock out the data to compare
//		DNA_ENA			<= 1'b0;							// lock down the RAM area
//		DNA_Addr				<= DNA_Addr+1;						// pipe the new address to RAM
		FinishCheck		<= 1'b1;							// exit the check phase
		dna_gen_st		<= Dc90;
	end
///// ============= result found loop here forever
	Dc90:	begin
		if	(IDE_CS == 1'b0) begin
			dna_gen_st	<= Dc91;
		end else begin
			dna_gen_st	<= Dc90;					// loop here if CS is 1
		end
	end
//////
	Dc91:	begin
		Simp_XOR			<= Simp_XOR + 1;					// increment the Simp_XOR to generate the internal kill signal
		dna_gen_st		<= Dc92;
	end
//////
	Dc92:	begin
		if	(IDE_CS == 1'b1) begin
			dna_gen_st	<= Dc90;						// if 1 goto next state
		end else begin
			dna_gen_st	<= Dc92;						// loop here if CS is 0
		end
	end

//// ===================================
	default : begin
		dna_gen_st		<= DcIdle;						// loop back to idle
	end
//// =================================
	endcase
	end	/// reset
end //// clock
endmodule
