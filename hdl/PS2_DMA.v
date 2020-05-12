`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:31:00 12/08/2008 
// Design Name: 
// Module Name:    PS2_DMA - Behavioral 
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

module PS2_DMA (
//	PS2_DMA_STATE : out std_logic_vector(15 downto 0);
	input CLK4,				// 146.6MHz clock input
	input Phase3,		// the phases
////// external pin interface
	output reg cDQ,		// DMA request output
	input cDK,				// DMA acknowledge input
	input cRd,				// read pulse
	input DWrite,			// write and counter pulse
////// controlling signal
	input DMA_ARM		,		// signal from ctrllr to inits DMA
	input PS2WrIDE		,		// level indicating that PS2 is DMA writing IDE bus
//// PS2 DMA connecting to RAM interface
	input PB_OD_Rdy  ,			// set high if at least 512 bytes in buffer (only check high order bits)
	input PB_HvSpace  ,			// set high if there is at least 512 bytes empty space in buffer (only check high order bits)
	input WithinBBlock  ,		// high if (AddrB(6) | AddrB(5)) = 1
	input BBurstEnd	 ,			// high if AddrB = xxxx11111 = 1F
////
	output  reg IncAddrB  ,
	output  RegEB	 ,				// pipeline register enable
	output  reg EnbB	 ,
	output  reg WrB
);

reg DTook;
reg DWrote;

// reworking the state machines at 100807

parameter PIdle 	= 5'b00000;
/// read phases
parameter PR20 	= 5'b00100;
parameter PR21 	= 5'b00101;
parameter PR22 	= 5'b00110;
parameter PR23 	= 5'b00111;
parameter PR32 	= 5'b01000;
parameter PR37 	= 5'b01001;
parameter PR38 	= 5'b01010;
parameter PR38A 	= 5'b01011;
parameter PR38B 	= 5'b01100;
/// write phases
parameter PW01A	= 5'b10001;
parameter PW01B	= 5'b10010;
parameter PW01C	= 5'b10011;
parameter PW01D	= 5'b10100;
parameter PW32		= 5'b10101;
parameter PW35		= 5'b10110;
parameter PW36		= 5'b10111;
parameter PW37		= 5'b11000;
parameter PW38A	= 5'b11001;
parameter PW38B	= 5'b11010;
parameter PW38C	= 5'b11011;
parameter PW38D	= 5'b11100;
parameter PW40		= 5'b11101;

reg [4:0] PSST;
reg OPOvrRide;

////- ============== test stubs
//PS2_DMA_STATE (15 downto 6) <= "0000000000";
//PS2_DMA_STATE ( 5 downto 0) <= STATE(5 downto 0);
//TYPE GBState_type IS (A, B, C, D);
//SIGNAL GBState : GBState_Type;

//////////// ================== END OF TEST STUBBS =======================

assign RegEB = Phase3 & ( cRd | OPOvrRide );

//// ===================

always @(posedge CLK4) begin
if (DMA_ARM == 1'b0) begin
	cDQ			<= 1'b0;	// always no request
	DTook			<= 1'b0;
	DWrote		<= 1'b0;
	IncAddrB		<= 1'b0;
	OPOvrRide	<= 1'b0;
	EnbB			<= 1'b0;
	WrB			<=	1'b0;
	PSST			<= PIdle;
end else begin
	////===== State machine default state ======
	case (PSST)
	PIdle: begin
		if (PS2WrIDE == 1'b0) begin			// if reading from disk
			cDQ	<= 1'b0;						// always 0 if we don't have enough data
			if ((PB_OD_Rdy == 1'b1) && (Phase3 == 1'b1)) begin		// if there is data in the buffer
				PSST	<= PR38;			// go to PR38
			end
		end else begin
			cDQ	<= PB_HvSpace;				// high if we have space
			if ((cDK == 1'b1) && (Phase3 == 1'b1)) begin
				PSST	<= PW40;			// PSST 	<= PW40A;
			end
		end
	end
//////- ======== PS2 reading DMA states //////////////////////-
	PR38: begin
		cDQ		<= 1'b0;			// data not ready
		DTook		<= 1'b1;				// increment address for the every burst
		if (Phase3 == 1'b1) begin
			PSST <= PR38A;	// clock the state machine into correct phase
		end
	end
//////- ========================================================
	PR38A: begin
		EnbB		<= DTook;			// be generous, 4 cycle enable for RAM data
		if (Phase3 == 1'b1) begin
			PSST	<= PR38B;	// one dummy state
		end
	end
//////- ======== PR2 state, latch the data and wait for ACK going high
	PR38B: begin
		EnbB			<= 1'b0;		// no more force read enable for RAM
		OPOvrRide	<= 1'b1;		// always output the data
		cDQ			<= 1'b1;		// can request transfer now
		if ((Phase3 == 1'b1) && (cDK == 1'b1)) begin
			PSST 		<= PR20;			// acknowledge so proceed
			DTook		<= cRd;		// check if first data taken
		end
	end
//// ======= PS2 Reading the DMA RAM // loop here ===========================
	PR20: begin
		OPOvrRide	<= 1'b0;		// no need to force output data now
		IncAddrB		<= DTook;	// data taken, rush data to output
		if ((DTook == 1'b1) && (BBurstEnd == 1'b1)) begin		// if currently pointing to last address and data taken
			PSST		<= PR32;		// address will be inc past, so just goto last stage, output registers are all set already
		end else begin
			PSST		<= PR21;	// continue
		end
	end
	PR21: begin
		IncAddrB	<=	1'b0;			// no more address increment
		EnbB		<= DTook;				// if data taken then update the Enb pulse correct phase enable pulse
		PSST		<= PR22;
	end
	PR22: begin
		EnbB		<= 1'b0;					// RAM enable turn off after this cycle
		cDQ		<= cDQ & ~DTook;		// keep request until first data taken cDQ will fall at end of Phase 2
		PSST		<= PR23;
	end
	PR23: begin
		DTook		<= cRd;			// if read is asserted at phase 3, data was took
		if (cDK == 1'b1) begin
			PSST <= PR20;
		end else begin
			PSST <= PR37;		// cDK gone unexpectedly
		end
	end
//		if (DTaken == 1'b0) begin
//			PSST	<= PR01A;			// data not taken, keep looping
//		end else begin
//			IncAddrB	<= 1'b1;			// data taken, new address
//			if (BBurstEnd == 1'b1) begin		// if currently pointing to last address and data taken
//				PSST		<= PR32;		// go to last state, register must have been set
//			end else begin
//				PSST		<= PR01A;	// loop back
//			end
//		end
////- ======== PR32 state // last clock, cleaning the pipeline
	PR32: begin						// outputing the last data
		IncAddrB	<=	1'b0;			// no more address increment
		if (cDK == 1'b1) begin
			PSST		<= PR32;
		end else begin
			PSST 		<= PR37;		// idle end
		end
	end
////- ======================= End of DMA loops ==========================
	PR37: begin
		if (WithinBBlock == 1'b1) begin
			if (Phase3 == 1'b1) begin
				PSST	<= PR38;		// loop back and do again
			end else begin
				PSST	<= PR37;
			end
		end else begin
			PSST <= PIdle;			// block transferred go back to idle state
		end
	end
//////================== End of DMA Read loop ===========================
//////======== PS2 writing DMA RAM, PW40A ===================== 
	PW40: begin
		if ((Phase3 == 1'b1) && (cDK == 1'b1)) begin
			PSST	<= PW01A;		// clock the state machine into correct phase
		end
	end
////////- =========== PW01A ====================================
	PW01A: begin
		IncAddrB	<= 1'b0;		// no more increment address
		PSST		<= PW01B;
	end
	PW01B: begin
		DWrote	<= DWrite;		// a cleaner condition for testing
		PSST		<= PW01C;
	end
	PW01C: begin
		EnbB		<= DWrote;	// enable write the RAM in the end of phase 3
		WrB		<= DWrote;	// will write the RAM in phase 3
		PSST		<= PW01D;
	end
	PW01D: begin
		EnbB		<= 1'b0;		// always turn off the RAM to conserve power
		WrB		<= 1'b0;
		IncAddrB	<= DWrote;			// need to increment address if we have wrote anything last cycle
		if (DWrote == 1'b1) begin		// if last time we have written
			if (BBurstEnd == 1'b1) begin	// if address before increment is last for this burst
				PSST	<= PW32;		// then we exit the loop for a while
			end else begin
				PSST	<= PW01A;	// else loop back
			end
		end else begin
			PSST	<= PW01A;		// last time we have not written anything; loop again
		end
	end
////- ======== PW32 state, wait for 8 cycles and raise the CDREQ
	PW32: begin
		IncAddrB		<= 1'b0;			// clear the increment address
		if (cDK == 1'b1) begin
			PSST <= PW32;		// loop back and wait until no more cDK
		end else begin
			PSST <= PW35;
		end
	end
//// ======== finish burst writing and cDK deassert, now check status of buffer
	PW35: begin
		if (Phase3 == 1'b1) begin
			PSST <= PW36;
		end
	end
	PW36: begin
		if (WithinBBlock == 1'b1) begin
			if (Phase3 == 1'b1) begin
				PSST <= PW37;	// skip and continue looping to write sector data
			end else begin
				PSST <= PW36;		// loop here waiting
			end
		end else begin
			PSST <= PIdle;	//- lead out to Idle state
		end
	end
//// ============================================================
	PW37:	begin
		if (Phase3 == 1'b1) begin
				PSST <= PW38A;
		end
	end
//// =================================================================
	PW38A: begin
		PSST	<= PW38B;
	end
	PW38B: begin
		PSST	<= PW38C;
	end
	PW38C: begin
		cDQ <= 1'b1;			// Raise the LREQ again at the falling edge of CLK
		PSST	<= PW38D;
	end
	PW38D: begin
		PSST <= PW40;		// loop again
	end
////================== End of DMA Write loop ===========================
	default: begin 
	   PSST <= PIdle;
	end
	endcase
end // rising_edge(CLK4)
end 

endmodule

