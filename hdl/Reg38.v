`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:24:03 11/08/2008 
// Design Name: 
// Module Name:    Reg38 - Behavioral 
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

//// Uncomment the following library declaration if instantiating
//// any Xilinx primitives in this code.
//library UNISIM;
//use UNISIM.VComponents.all;
////- Reg0038 has the following bits being mapped
////	bcIRQ	cDQ	cDK	iIRQ	iDQ	ibDK	Mo86	Mo87		
//// 	1		0		0		0		0		1		0060	----	// bus idle
////	1		0		0		0		1		0		0020	----	// IDE side doing transaction buffer not full
////	1		0		0		0		1		0		----	0020	// IDE side doing transaction buffer not full
////	1		1		0		0		1		0		----	00A0	// IDE side doing transaction and buffer full
////	1		1		0		0		1		1		----	0050	// just start DMA and drive not responding
////	1		1		0		0		1		0		0021,23,24	// buffer size
////	1		1		0		1		0		1		0021,22		// fixed ???
////==================================================
////  Design base on above measurements : note the {} value is iDK = NOT(ibDK)
////	cDQ	cDK	iIRQ	iDQ	ibDK	Mo86	Mo87		
////	x		x		1		x		x		21 for NOT(UDMA) 22 for UDMA
////	1		0		0		x		0{1}	buffer size (21,23,24,...27)
////	1		0		0		1		1{0}	-		50
////	0		x		0		0		x		60	bus idle
////	0		x		0		1		x		20 if buffer not full
////	0		x		0		1		x		A0 if buffer full

module Reg38(
	input UDMAC		,
	input PS2WrIDE	,
	input iIRQ		,
	input cDQ		,
	input iDQ		,
	input iDK		,
	input BufEmpty		,
	input PB_HvSpace	,		// Port A have space
	input [3:0] BufSize	,
	output [7:0] DOut		
);

/// Start of Register 38

wire [7:0] R381;
wire [7:0] W381;
wire WCond1;
wire WCond2,WCond2A,WCond2B1,WCond2B2;
wire WCond3;
//wire WCond3A,WCond3B;
//wire RCond1,RCond2;
wire Activity;

assign Activity	= cDQ | iIRQ | iDQ | iDK | BufSize[3] | BufSize[2] | BufSize[1] | BufSize[0];	// if there is no DMA activity
//assign R381[7:2]	= 6'b00_1000; // fix as 2x
//assign R381[1]		= BufSize[2] | BufSize[1];
//assign R381[0]		= BufSize[2] | BufSize[0];
assign R381[7]	= 1'b0;		// always zero
assign R381[6] = ~Activity;	// no activity will be high
assign R381[5:4] = 2'b10;		// set as 2
assign R381[3:0] = BufSize[3:0];

assign W381[7:0] =
	(BufSize[3:0] == 4'b1000) ? 8'h20 :		// no space left, the buffer is full
	(BufSize[3:0] == 4'b0111) ? 8'h21 :		// one page has been taken, so one space left
	(BufSize[3:0] == 4'b0110) ? 8'h22 :		// two page taken
	(BufSize[3:0] == 4'b0000) ? 8'h24 :		// buffer empty
										 8'h23;		// otherwise
//assign W381[1]		= ~(BufSize[2] & BufSize[1]);
//assign W381[0]		= ~(BufSize[2] & BufSize[1] & BufSize[0]);
//assign W381[1]		= BufSize[2];						// take 0304 it representing very little space
//assign W381[0]		= PB_HvSpace;
//assign RCond1	= ~(PS2WrIDE) & ~(Activity);			// DMA reading and bus not active
//assign RCond2	= ~(PS2WrIDE) & Activity;		// DMA reading and bus active
assign WCond1	= PS2WrIDE & ~(PB_HvSpace);			// if there is no space in buffer
assign WCond2	= PS2WrIDE & ~(iDK);			// bus active but drive side no transfer request
assign WCond2A	= WCond2 & BufEmpty;								// we don't have data in output register
assign WCond2B1	= WCond2 & ~(BufEmpty) & UDMAC;			// if there is data and we are UDMA mode, report as "22"
assign WCond2B2	= WCond2 & ~(BufEmpty) & ~(UDMAC);	// if there is data and we are MDMA mode, report as "21"
assign WCond3	= PS2WrIDE & iDK;				// if there is drive side transfer, PS2 writing data to drive
//assign WCond3A	= WCond3 & BufEmpty;
//assign WCond3B	= WCond3 & ~(BufEmpty); // if something in buffer


assign DOut	=
//// 86 mode, PortA input, Port B output data //
//	(RCond1	== 1'b1) ? 8'h60 :
//	(RCond2	== 1'b1) ? R381  :
	(PS2WrIDE == 1'b0) ? R381 :		// PS2WrIDE = 0, reading from drive
//// 87 mode, PortB input, Port A output data //
	(WCond1	== 1'b1) ? 8'hA0 :		// if no space in buffer B, then buffer is full
//// if PortA have no transaction, iDK = 0 then
	(WCond2A	== 1'b1) ? 8'h50 :		// if bufferA is absolutely empty
	(WCond2B1 == 1'b1) ? 8'h22 :	// if bufferA is not empty
	(WCond2B2 == 1'b1) ? 8'h21 :
//// if PortA have transaction, iDK = 1
	(WCond3	== 1'b1) ? W381 :
//	(WCond3A	== 1'b1) ? 8'h24 :		// plenty of buffer space
//	(WCond3B	== 1'b1) ? W381 :
	8'hFF;
///////// end of reg38 ////////////////////////////

endmodule
