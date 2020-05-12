`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:46:11 02/27/2009 
// Design Name: 
// Module Name:    CRC_CAL 
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
module CRC_CAL(CLK4, D, CRC_ARM, CRC_ENB, CRC_Q);
    input CLK4;
    input [15:0] D;
    input CRC_ARM;
    input CRC_ENB;
    output [15:0] CRC_Q;

wire [15:0] R_D;
reg  [15:0] R_Q;


// CRC combination logic block
CRC_CL CF(	.D(D),			// one input is the data block
				.C(R_Q),			//	other input is the register feed back
				.Q(R_D)			// result feed into the data register data port
				);
				
assign CRC_Q =	R_Q;


always @(posedge CLK4) begin //negedge
  if(CRC_ARM == 1'b0) begin
    R_Q <= 16'h4ABA;				
  end else if(CRC_ENB == 1'b1) begin
    R_Q <= R_D;  				// clock the data into the port
  end
end

endmodule
