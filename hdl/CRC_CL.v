`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:32:40 03/04/2009 
// Design Name: 
// Module Name:    CRC_CL 
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
module CRC_CL(
	input [15:0] D,
	input [15:0] C,
	output [15:0] Q
);

wire [16:1]	f;		// internal wire
// The polynomial is
// G(X) = X16 + X12 + X5 + 1

assign f[1]		= D[0]  ^ C[15];
assign f[2]		= D[1]  ^ C[14];
assign f[3]		= D[2]  ^ C[13];
assign f[4]		= D[3]  ^ C[12];
assign f[5]		= D[4]  ^ C[11]	^ f[1];
assign f[6]		= D[5]  ^ C[10]	^ f[2];
assign f[7]		= D[6]  ^ C[9] 	^ f[3];
assign f[8]		= D[7]  ^ C[8] 	^ f[4];
assign f[9]		= D[8]  ^ C[7] 	^ f[5];
assign f[10]	= D[9]  ^ C[6] 	^ f[6];
assign f[11]	= D[10] ^ C[5] 	^ f[7];
assign f[12]	= D[11] ^ C[4] 	^ f[8]	^ f[1];
assign f[13]	= D[12] ^ C[3]		^ f[9]	^ f[2];
assign f[14]	= D[13] ^ C[2]		^ f[10]	^ f[3];
assign f[15]	= D[14] ^ C[1]		^ f[11]	^ f[4];
assign f[16]	= D[15] ^ C[0]		^ f[12]	^ f[5];

assign Q[0]		= f[16];
assign Q[1]		= f[15];
assign Q[2]		= f[14];
assign Q[3]		= f[13];
assign Q[4]		= f[12];
assign Q[5]		= f[11] 	^ f[16];
assign Q[6]		= f[10]	^ f[15];
assign Q[7]		= f[9] 	^ f[14];
assign Q[8]		= f[8] 	^ f[13];
assign Q[9]		= f[7] 	^ f[12];
assign Q[10]	= f[6]	^ f[11];
assign Q[11]	= f[5]	^ f[10];
assign Q[12]	= f[4]	^ f[9]	^ f[16];
assign Q[13]	= f[3]	^ f[8]	^ f[15];
assign Q[14]	= f[2]	^ f[7]	^ f[14];
assign Q[15]	= f[1]	^ f[6]	^ f[13];

endmodule
