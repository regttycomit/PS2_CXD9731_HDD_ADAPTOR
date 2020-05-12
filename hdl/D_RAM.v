`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:31:51 12/08/2008 
// Design Name: 
// Module Name:    DMA_RAM - Behavioral 
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


module D_RAM(
	input CLK4	,	
	input DMA_ARM	, 
	input PS2WrIDE	, 			// High if PS2 DMA write to IDE bus
//// =====
	input CRC_ARM ,  
	input CRC_ENB	, 			// the enable for the CRC circuit
	output [15:0] CRC_Q ,
//// =====
	output [3:0] BufSize ,		// data size in 512 bytes ready
	output BufEmpty , 		// set when no words in the FIFO buffer
//// =====
	input [15:0] DInA	,
	output [15:0] DOutA ,
	input [31:0] DInB ,
	output [31:0] DOutB ,
//// =====
	output PA_HvSpace	, 
	output PA_OD_Rdy	, 		// some data availabe for output from Port A
	output PA_AlmostFull , 	// set when buffer has only 4 words left
	output PA_Empty,			// set when buffer is all drained
	output PA_Full,			// Register is full.
	output WithinABlock ,
	output reg A0,					// A0 to put signal to IDE_DMA
	input	HWOE,					// select high order word to output
	input	RegEA,
	input IncAddrA , 
	input EnbA ,					// enable and the control signal
	input WrA	, 
//// =====
	output PB_HvSpace	, 
	output PB_OD_Rdy	, 	// some data availabe for output from Port B
	output WithinBBlock , 		// high if (AddrB[6] | AddrB[5]) = 1
	output BBurstEnd	, 		// high if AddrB = xxxx11111 = 1F
	input IncAddrB , 
	input RegEB	, 
	input EnbB	,	
	input WrB
);


//////////////////////////////////////////////////////
wire	R0Enb,R1Enb,R0Wr,R1Wr,RegEA0,RegEA1;
wire	[15:0] DOutA0,DOutA1,DInBL,DInBH,DOutBL,DOutBH;
reg	[9:0] AddrA,AddrB;
reg	[3:0] Page;
wire	IncPgA,IncPgB;
wire PageNZ,PageZR;
wire HvSpaceA,HvSpaceB;
wire A_Zero,B_Zero;
////-=========================================================================
RAM1 RAM_Lo (
	.clka		(CLK4),
	.dina		(DInA),		// IDE side data bits
	.addra	(AddrA),
	.ena		(R0Enb),
	.wea		(R0Wr),
	.regcea	(RegEA0),
	.douta	(DOutA0),
//
	.clkb		(CLK4),
	.dinb		(DInBL),		// PS2 side data bus
	.addrb	(AddrB),
	.enb		(EnbB),
	.regceb	(RegEB),
	.web		(WrB),
	.doutb	(DOutBL)
);
//// =========================================
RAM1 RAM_Hi(
	.clka		(CLK4),
	.dina		(DInA),		// IDE side data bits
	.addra	(AddrA),
	.ena		(R1Enb),
	.wea		(R1Wr),
	.regcea	(RegEA1),
	.douta	(DOutA1),
//
	.clkb		(CLK4),
	.dinb		(DInBH),		// PS2 side data bus
	.addrb	(AddrB),
	.enb		(EnbB),
	.regceb	(RegEB),
	.web		(WrB),
	.doutb	(DOutBH)
);
//// =========================================

CRC_CAL CRC(
	.CLK4		(CLK4),			// same as RAM clock
	.D			(DInA),			//- same as the RAM data
	.CRC_ARM	(CRC_ARM),			//- from the controller unit
	.CRC_ENB	(CRC_ENB),
	.CRC_Q	(CRC_Q)
);
//-=============================================================================

//-==== Connect the RAM
assign DOutA[15:0]	= (HWOE == 1'b1) ? DOutA1[15:0] : DOutA0[15:0];
assign DOutB[31:16]	= DOutBH[15:0];
assign DOutB[15:0]	= DOutBL[15:0];
assign DInBH[15:0]	= DInB[31:16];
assign DInBL[15:0]	= DInB[15:0];
assign R0Enb	= EnbA & ~A0;
assign R1Enb	= EnbA &  A0;
assign R0Wr		= WrA  & ~A0;
assign R1Wr		= WrA  &  A0;
assign RegEA0	= RegEA & ~A0;
assign RegEA1	= RegEA &  A0;
////
//// = the page counter ////
assign IncPgA	= IncAddrA & AddrA[6] & AddrA[5] & AddrA[4] & AddrA[3] & AddrA[2] & AddrA[1] & AddrA[0] & A0;
assign IncPgB	= IncAddrB & AddrB[6] & AddrB[5] & AddrB[4] & AddrB[3] & AddrB[2] & AddrB[1] & AddrB[0];
assign BufEmpty	= PageZR & A_Zero & B_Zero;
////////-=======================================================
assign HvSpaceA	= ~Page[3] & ( ~(Page[2] & Page[1] & Page[0]) | A_Zero );
assign HvSpaceB	= ~Page[3] & ( ~(Page[2] & Page[1] & Page[0]) | B_Zero );
assign PageNZ	= Page[3] | Page[2] | Page[1] | Page[0];
assign PageZR	= ~(Page[3] | Page[2] | Page[1] | Page[0]);
assign A_Zero	= ~(AddrA[6] | AddrA[5] | AddrA[4] | AddrA[3] | AddrA[2] | AddrA[1] | AddrA[0]);
assign PA_Empty	= PageZR & A_Zero & ~A0;
assign B_Zero	= ~(AddrB[6] | AddrB[5] | AddrB[4] | AddrB[3] | AddrB[2] | AddrB[1] | AddrB[0]);

assign PA_OD_Rdy		= PageNZ;
assign PA_HvSpace		= HvSpaceA;		// have 512 byte space at least
assign PA_AlmostFull	= Page[3] | (Page[2] & Page[1] & Page[0] & AddrA[6] & AddrA[5] & AddrA[4] & AddrA[3]);
// PA_Full - a signal set high to indicate all buffer area is used up and until clear one page, should
// not start DMA read into Port A
//  This signal will be high if incremented and will keep high until PortB dec it
assign PA_Full			= Page[3];

assign WithinABlock	= AddrA[6] | AddrA[5] | AddrA[4] | AddrA[3] | AddrA[2] | AddrA[1] | AddrA[0] | A0;
////
assign PB_OD_Rdy		= PageNZ;			// if there is more than one page of data
assign PB_HvSpace		= HvSpaceB;		// if there is space in buffer
assign WithinBBlock	= AddrB[6] | AddrB[5] | AddrB[4] | AddrB[3] | AddrB[2] | AddrB[1] | AddrB[0];
assign BBurstEnd		= AddrB[4] & AddrB[3] & AddrB[2] & AddrB[1] & AddrB[0]; // high if AddrB = xxxx11111 = 1F
////////
assign BufSize[3:0]	= Page[3:0];

////- ============================================================================
always @(posedge CLK4) begin
	if (DMA_ARM == 1'b0)
	  AddrB		<=  10'b00_0000_0000;
	else
		if(IncAddrB == 1'b1)
		  AddrB		<= AddrB + 1;
end
	
always @(posedge CLK4) begin
	if (DMA_ARM == 1'b0) begin
	  AddrA	<=	10'b00_0000_0000;
	  A0		<= 1'b0;
	end else begin
		if(IncAddrA == 1'b1) begin
			if (A0 == 1'b1) begin
				AddrA	<= AddrA + 1;
				A0		<= 1'b0;
			end else begin
				A0		<= 1'b1;
			end
		end
	end
end

always @(posedge CLK4) begin
	if (DMA_ARM == 1'b0) begin
	  Page		<=  4'b0000;
	end else begin
		if (PS2WrIDE == 1'b1) begin	// PS2 writes to drive
			if (IncPgB == 1'b1) begin
				if (IncPgA == 1'b0) Page <= Page + 1;	// buffer increase in size
			end else begin
				if (IncPgA == 1'b1) Page <= Page - 1;	// buffer decrease in size
			end
		end else begin
			if (IncPgA == 1'b1) begin
				if (IncPgB == 1'b0) Page <= Page + 1;	// buffer has increase in size
			end else begin
				if (IncPgB == 1'b1) Page <= Page - 1; // buffer decrease in size
			end
		end // PS2WrIDE
	end // DMA_ARM
end // always
	
endmodule
