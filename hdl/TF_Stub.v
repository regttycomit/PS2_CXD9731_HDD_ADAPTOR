`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:38:24 04/11/2010 
// Design Name: 
// Module Name:    TF_Stub 
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
module TF_Stub(
		input	RESET,
		input	CLK4,
// external bus
		inout TFD0,
		inout TFD1,
		inout TFD2,
		inout TFD3,
		output TF_CMD,
		output TF_CLK,
		input TF_SENSE
    );

//////

//// ================================
////////////////////////////////////////////////
// signals
// 25MHz output = 36.6 x 4 / 6 = 24 MHz approx
//////////////////////////////////////
reg TF_CLKSO;
reg [7:0] TF_COUNT;
wire TFD0i,TFD1i,TFD2i,TFD3i;
reg [3:0] TFDD;
wire TerminateCount;
wire FAST;		// select 25MHz or 400kHz output

////==========================================================

//  The ORIGINAL signal - if TF not install, then nothing happen
	assign TFD0	= (TF_SENSE == 1'b1) ? TFDD[0] : 1'bZ;
	assign TFD0i	= TFD0;
	assign TFD1	= (TF_SENSE == 1'b1) ? TFDD[1] : 1'bZ;
	assign TFD1i	= TFD1;
	assign TFD2	= (TF_SENSE == 1'b1) ? TFDD[2] : 1'bZ;
	assign TFD2i	= TFD2;
	assign TFD3	= (TF_SENSE == 1'b1) ? TFDD[3] : 1'bZ;
	assign TFD3i	= TFD3;
	assign TF_CLK	= (TF_SENSE == 1'b1) ? TF_CLKSO : 1'b0;		// do not drive the clock if nothing there
	assign TF_CMD	= (TF_SENSE == 1'b1) ? TFD0i ^ TFD1i ^ TFD2i ^ TFD3i : 1'b0;			// just stub output some dummy data

// ***************************************************
// Terminate Count either FAST (02 ) or (182 = 128 + 32 + 16 + 4 + 2)
	assign	FAST = TFD0i;
	assign	TerminateCount =	(FAST & TF_COUNT[1] & ~TF_COUNT[0] ) | 
										(TF_COUNT[7] & TF_COUNT[5] & TF_COUNT[4] & TF_COUNT[2] & TF_COUNT[1]);
always @(posedge CLK4)begin
if (RESET == 1'b1) begin
// ============================================================
	TF_COUNT		<= 2'b00;		// always clear
	TF_CLKSO		<= 1'b0;			// clock low
	TFDD			<= 4'b0000;
// ============================================================
end else begin
	TFDD	<= TFDD + 1;
// =========================================================
// 400kHz or 25MHz
// 25MHz output = 36.6 x 4 / 6 = 24.4 MHz approx == level change every 3 clocks
// 400kHz output = 36.6 x 4 / 366 = 400 kHz ( level changes every 183 clock )

	if (TerminateCount == 1'b1) begin
		TF_COUNT[7:0] 	<= 8'b0000_0000;		// reset the count
		TF_CLKSO			<= ~TF_CLKSO;	// negate the clock pulse
	end else begin
		TF_COUNT			<= TF_COUNT + 1;
	end
end //RESET
end

endmodule
