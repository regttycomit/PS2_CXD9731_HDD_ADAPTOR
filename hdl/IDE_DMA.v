`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:38:06 03/04/2009 
// Design Name: 
// Module Name:    IDE_DMA 
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

module IDE_DMA(
//	output IDE_DMA_STATE : out std_logic_vector(15 downto 0);
	input CLK4		,
	input Phase3	,
////// external pin interface
	output reg iDK	,			// DMA acknowledge output to harddisk
	input iDQ		,			// DMA request input from harddisk
	input SiRdy1	,			// Sync ready signal
	input SiRdy2	,			// Sync ready signal
////// system signal
	input DMA_ARM  ,		// extra signal to ARM the IDE DMA part
	input PS2WrIDE	 ,			// 1'b1 if direction is from PS2 to IDE
	input [2:0] UDMA ,			// the mode of the current transfer
	input [2:0] MDMA,
	output iDMARd		,			// active high signal to indicate DMA read
	output iDMAWr	 ,			// active high signal to indicate DMA write
	output reg iDMA_OE	 ,			// active high showing unit wishes to write bus
	output reg iD_245_In  ,			// active high 245 read envelope ( 1 clock before OE and 1 clock after)
	output reg CRC_MUX	 ,			// inform system that need to drive the CRC Q to IDE bus
	output reg CRC_ARM	 ,			// a signal indicate that to clear the CRC state
	output reg CRC_ENB	 ,				// the enable for the CRC circuit
////// interface the RAM buffer, DMA machine will act according to buffer
	input A0	,			// address A0
	input PA_Full		,		// high if PA is full, will be low only one block is cleared
	input PA_HvSpace	 ,	// there is empty space for Port A
	input PA_OD_Rdy	 ,	// some data availabe for output from Port A
	input WithinABlock	 ,	// set within A block
	input PA_AlmostFull  ,		// stop if the buffer is almost full
	input PA_Empty		,		// high if PA is empty
	output IDE_DSTB,		// high if we wish to strobe data
	output reg HWOE,		// high to select high page to output
	output reg RegEA,
	output reg IncAddrA , 
	output reg EnbA ,					// enable and the control signal
	output reg WrA 
);

//////

//// ================================
////////////////////////////////////////////////
// signals
// NDMA : iDQ,iDK,iWr,iRd,iRDY
// UDI  : iDQ,iDK,STOP,HDMARDY,DSTROBE
// UHO  : iDQ,iDK,STOP,HSTROBE,DDMARDY
//////////////////////////////////////
reg HDMARDY,HSTROBE,STOP;
reg ND_Rd,ND_Wr;

wire NBrkOut;	// wire to break out when buffer is empty
reg	iWait;
wire UDMAC,MDMAC;
reg	ND_ARM;
reg	UHO_ARM;
reg	UDI_ARM; // the UDI enable wire
reg	ILatch;		// the latch to control the data path for CRC calculation
//// ========
wire	Proceed;	// wire to proceed to output data in buffer
wire XiRdy1;	// signal to indicate there is a transition

parameter iIdle1	= 6'b00_0000;
parameter iIdle2	= 6'b00_0001;
parameter ND_2 	= 6'b00_0010;
parameter ND_3 	= 6'b00_0011;
parameter ND_4 	= 6'b00_0100;
parameter ND_5 	= 6'b00_0101;
parameter ND_6 	= 6'b00_0110;
parameter ND_7 	= 6'b00_0111;
parameter ND_8 	= 6'b00_1000;
parameter ND_9 	= 6'b00_1001;
parameter ND_A 	= 6'b00_1010;
parameter ND_B 	= 6'b00_1011;
parameter ND_C 	= 6'b00_1100;
parameter Udi1 	= 6'b01_0000;
parameter Udi2 	= 6'b01_0001;
parameter Udi3 	= 6'b01_0010;
//parameter Udi4 	= 6'b01_0011;
parameter Udi10	= 6'b01_0100;
parameter Udi11	= 6'b01_0101;
parameter Udix1 	= 6'b10_0001;
parameter Udix2 	= 6'b10_0010;
parameter Udix3 	= 6'b10_0011;
parameter Udix4 	= 6'b10_0100;
parameter Udix5 	= 6'b10_0101;
parameter Udix6 	= 6'b10_0110;
parameter Uho_G 	= 6'b10_0111;
parameter Uhx_0 	= 6'b10_1000;
parameter Uhx_1 	= 6'b10_1001;
parameter Uhx_2 	= 6'b10_1010;
parameter Uhx_3 	= 6'b10_1011;
parameter Uhx_4 	= 6'b10_1100;
parameter Uhx_5 	= 6'b10_1101;
parameter Uhx_6 	= 6'b10_1110;
//
parameter Uho_0	= 6'b11_0000;
parameter Uho_1	= 6'b11_0001;
parameter Uho_2	= 6'b11_0010;
parameter Uho_3	= 6'b11_0011;
parameter Uho_4	= 6'b11_0100;
parameter Uho_5	= 6'b11_0101;
parameter Uho_6	= 6'b11_0110;
parameter Uho_7	= 6'b11_0111;
parameter Uho_8	= 6'b11_1000;
parameter Uho_9	= 6'b11_1001;
parameter Uho_A	= 6'b11_1010;
parameter Uho_B	= 6'b11_1011;
parameter Uho_C	= 6'b11_1100;
parameter Uho_D	= 6'b11_1101;
parameter Uho_E	= 6'b11_1110;
parameter Uho_F	= 6'b11_1111;


reg [5:0] iSTATE;
reg [4:0] iCount;
reg PipeEmpty;
reg IDE_DSTB1;

////- ============== test stubs
//IDE_DMA_STATE(15 downto 7) <= "100000000";  // starts as 80xx
//IDE_DMA_STATE(6 downto 0) <= Count(6 downto 0);
//////////// ================== END OF TEST STUBBS =======================



////==========================================================
//- Normal DMA only signal
assign iDMAWr  =	(ND_ARM & ND_Wr) | ((UDI_ARM | UHO_ARM) & ~(STOP));                // the external DMA signal
assign iDMARd  =	(ND_ARM & ND_Rd) |
						(UDI_ARM & HDMARDY) |
						(UHO_ARM & ~HSTROBE);

// ===============================================================================
/// signal to stop normal DMA machine
//  either	1/ iDQ is negated
//		or		2/ During Host Out and no data in FIFO
//		or		3/ During Drive In and FIFO is full
assign 	NBrkOut	= ~iDQ | (PS2WrIDE & PA_Empty) | (~PS2WrIDE & PA_Full);
//// ============================================================================

//// ===================================
assign	UDMAC	= (UDMA[2] | UDMA[1] | UDMA[0]) & ~(MDMAC);
assign	MDMAC	= MDMA[2] | MDMA[1] | MDMA[0];
assign	Proceed = PA_OD_Rdy | WithinABlock;	// allow to output data when ready or we are in a transaction period
assign	XiRdy1	= SiRdy1 ^ SiRdy2;				// an early edge signal, lock the data to RAM
assign	IDE_DSTB = (XiRdy1 & UDI_ARM) | ((UHO_ARM | ND_ARM) & ILatch );

always @(posedge CLK4) begin
	IDE_DSTB1	<= IDE_DSTB;
	CRC_ENB		<= IDE_DSTB1 & ~IDE_DSTB;			// trigger 1 clock after its deb
end

always @(posedge CLK4)begin
////DelayHSTB	<= HSTROBE;
//HDMARDY	<= ~STOP & (PA_HvSpace | (HDMARDY & (~PA_AlmostFull | ~XiRdy1)));	//if we are almost full and enabled

if (DMA_ARM == 1'b0) begin
// ============================================================
	UDI_ARM	<= 1'b0;
	UHO_ARM	<= 1'b0;
	STOP		<= 1'b1;		// always STOP
	HDMARDY	<= 1'b0;		// Host always not ready
	iWait		<= 1'b0;		// assume no wait
	HSTROBE	<= 1'b1;		// HSTrobe Control by us
// ===================
	ND_ARM	<= 1'b0;
	ND_Rd		<= 1'b0;     // no reading
	ND_Wr		<= 1'b0;     // stop anything
	ILatch	<= 1'b0;
// ===================
	iDK		<= 1'b0;
	iDMA_OE	<= 1'b0;			// no OE
	iD_245_In	<= 1'b0;		// disable 245 driver direction control
	CRC_ARM	<= 1'b0;			// clear the CRC machine
	CRC_MUX	<= 1'b0;			// not selecting the CRC to output
//	CRC_ENB	<= 1'b0;			// do not enable the CRC
// =============== RAM block control signal
	RegEA		<= 1'b0;
	IncAddrA	<= 1'b0;
	EnbA		<= 1'b0;			// enable and the control signal
	WrA		<= 1'b0;
	iCount	<= 5'b0000;
	HWOE		<= 1'b0;
	PipeEmpty	<= 1'b1;		// pipeline is empty for reset
	iSTATE	<= iIdle1;		// keep the first state machine
// ==================
end else begin
// =========================================================
if (UHO_ARM == 1'b1) begin
	if (SiRdy2 == 1'b1) begin
		iWait		<= 1'b1;			// need to wait
		iCount	<= 5'd00;
	end else begin
		iCount	<= iCount + 1;
		if (iCount[4] == 1'b1) begin
			iWait	<= 1'b0;			// clear the wait 16 clocks after SiRdy2 goes low
		end
	end
end //UHO_ARM
//============================================================
case (iSTATE)
iIdle1: begin
// ============================================================
	UDI_ARM	<= 1'b0;		// Device In mode not ARM
	STOP		<= 1'b1;		// always STOP
	HDMARDY	<= 1'b0;		// always not ready
// ============================================================
	UHO_ARM	<= 1'b0;		// Host Out mode not ARM
	HSTROBE	<= 1'b1;		// HSTrobe Control by us
// ============================================================
	ND_ARM	<= 1'b0;		// Normal DMA not ARM
	ND_Rd		<= 1'b0;		// no reading
	ND_Wr		<= 1'b0;		// stop anything
	ILatch	<= 1'b0;
// ===================
	iDK		<= 1'b0;
	iDMA_OE	<= 1'b0;			// no OE
	iD_245_In	<= 1'b0;		// disable control of 245 driver direction
	CRC_ARM	<= 1'b0;			// clear the CRC machine
	CRC_MUX	<= 1'b0;			// not selecting the CRC to output
// ===============
	RegEA		<= 1'b0;
	IncAddrA	<= 1'b0;
	EnbA		<= 1'b0;			// enable and the control signal
	WrA		<= 1'b0;
	iCount	<= 5'b0000;
// ===============
	iSTATE	<= iIdle2;	// next looping state
end
//// =============================================
iIdle2: begin
	iCount	<= 5'd00;					// set counter as 00 in this state
	if (iDQ == 1'b1) begin
		if (UDMAC == 1'b1) begin			//- Ultra DMA mode
			if (PS2WrIDE == 1'b1) begin
				if (Proceed == 1'b1) begin	// try to proceed to output data
					iSTATE <= Uho_0;			// UW1: Write Data from PS2 to IDE
				end
			end else begin
				if (PA_HvSpace == 1'b1) begin
					iSTATE	<= Udi1;	// Read data from drive if we have space
				end
			end	// PS2WrIDE
		end else begin //- normal mode
			if (PS2WrIDE == 1'b1) begin
				if (Proceed == 1'b1) begin		// if one block of data is valid
					iSTATE <= ND_2;
				end
			end else begin
				if (PA_HvSpace == 1'b1) begin
					iSTATE <= ND_2;	// if there is space
				end
			end //- PS2WrIDE
		end //-UDMA
	end else begin
		iSTATE <= iIdle2;		// loop here until iDQ = 1;
	end // iDQ
end
////// =================================================
//-=== Multiword
//==  mode 0 = 480nS cycle = 72 state = ND_3..ND36 = 36/36
//==  mode 1 = 150nS cycle = 22 state = 01,02,03,04,18,19,20,21,22,23,24  = 12/10
//==  mode 2 = 120nS cycle = 18 state = 01,02,03,04,05,   20,21,22,23     = 10/8
//// =====
ND_2: begin
	iSTATE		<= ND_3;				// always
	iDK			<= iDQ;				// directly map the request
	ND_ARM		<= 1'b1;				// enter the normal DMA mode
	iD_245_In	<= ~PS2WrIDE;		// turn 245 inwards if
end
//// ======
ND_3: begin
	iDK		<= iDQ;						// directly map the request
	if (NBrkOut == 1'b0) begin			// if not breaking out
		EnbA		<= PS2WrIDE;			// enable the RAM if writing
		iSTATE	<= ND_4;					// goto next state if iDQ is not zero and we are within A Block
	end else begin
		iD_245_In	<= 1'b0;				// breaking out, always turn the buffer outwards
		ND_ARM		<= 1'b0;				// no more arming of the signal
		iSTATE		<= iIdle1;			// exit to check again
	end
end
//// =====
ND_4: begin
	iSTATE	<= ND_5;
	EnbA		<= 1'b0;				// already enabled, now turn off to conserve power
	RegEA		<= PS2WrIDE;		// enable the registers if RAM access
end
//// =====
ND_5: begin
	iSTATE	<= ND_6;				// goto next state ND_6 state
	RegEA		<=	1'b0;				// latch gated, turn off now
	iCount	<= 5'd00;			// reset the counter
	iDMA_OE	<= PS2WrIDE;		// if write to drive, we will drive the data bus
end
//// =====
ND_6: begin
	iSTATE	<= ND_7;				// goto next state ND_6 state
	ND_Rd		<= ~PS2WrIDE;		// if read from drive then strobe external signal
	ND_Wr		<=  PS2WrIDE;		// if write to drive then strobe external signal
end
//// =============== determine cycle length =====================	
ND_7:	begin
	iCount	<= iCount + 1;			//count less 5 for processing
	if (((iCount == 5'd05) && (MDMA[2] == 1'b1)) ||			// strobe width is 10 clks 
		 ((iCount == 5'd07) && (MDMA[1] == 1'b1)) || 		// strobe width is 12 clks
		  (iCount == 5'd31) ) begin								// strobe width is 36 clks
		iSTATE	<= ND_8;			// set end Phase
	end
end
//// ===============
ND_8: begin
	ILatch	<= ~PS2WrIDE;		// if read from drive then enable input latch
	iSTATE	<= ND_9;				// proceed if I/O ready
end
ND_9: begin
//	if (SiRdy2 == 1'b1) begin
		iSTATE	<= ND_A;			// proceed if I/O ready
//	end
end
//// ===============
ND_A: begin
	WrA		<= ~PS2WrIDE;		// if mode is read from drive then we pulse RAM
	EnbA		<= ~PS2WrIDE;		// if mode is read from drive then we pulse RAM
	iCount	<= 5'd00;			// reset counter
	iSTATE	<= ND_B;
end
ND_B: begin
	WrA		<=	1'b0;				// always disable internal RAM Block write pulse
	EnbA		<= 1'b0;				// always disable the RAM Block control signal
	ND_Rd		<=	1'b0;				// always turn off external strobe
	ND_Wr		<= 1'b0;				// always turn off external strobes now
	ILatch	<= 1'b0;				// switch off data latch
	IncAddrA	<= 1'b1;				// inc internal RAM Block address to next location
	iSTATE	<= ND_C;
end
//// ====================== end Phase
ND_C: begin
	iDMA_OE	<= 1'b0;				// turn off the internal busdrivers
	IncAddrA	<= 1'b0;				// turn off RAM Block address
	HWOE		<= A0;				// select the next output data
	iCount	<= iCount + 1;		//count less 5 for processing
	if (((iCount == 5'd03) && (MDMA[2] == 1'b1)) ||			// recharge is 8 clks 
		 ((iCount == 5'd05) && (MDMA[1] == 1'b1)) || 		// recharge is 10 clks
		  (iCount == 5'd31) ) begin								// recharge is 36 clks
		iSTATE	<= ND_3;			// loop again
	end
end
////-============================================================
//- Ultra DMA Drive In mode - we read from drive and write to FIFO
////-============================================================
Udi1:	begin						// Udi1 state
	UDI_ARM		<= 1'b1;		// now the DMA_machine is UDI controlled
	iDK			<= 1'b0;		// no DMA first
	iDMA_OE		<= 1'b0;		// ensure we are not driving the FPGA output
	STOP			<= 1'b1;		// set to stop first
	HDMARDY		<= 1'b0;		// set to not ready first
	if (Phase3 == 1'b1) begin
		iSTATE	<= Udi2;
	end
end
Udi2:	begin					// Udi2 state -- at least one clock
	if (iDQ == 1'b1) begin
		if ((Phase3 == 1'b1) && (SiRdy2 == 1'b1)) begin  // wait until the drive drives high the IORDY signal
			iSTATE	<= Udi3;
		end
	end else begin
		iSTATE	<= iIdle1;			// exit to idle if iDQ suddenly gone
	end
end
Udi3:	begin					// Udi3 state -- at least one clock
	iDK			<= 1'b1;		// we issue DMA ready for iDQ
	iD_245_In	<= 1'b1;		// turn the driver inwards
	CRC_ARM		<=	1'b1;		// start the CRC machine
	if (Phase3 == 1'b1) begin
		iSTATE	<= Udi10;
	end
end
//// ==================
//HDMARDY	<= ~STOP & (PA_HvSpace | (HDMARDY & ~(PA_AlmostFull & XiRdy1)));	//if we are almost full and enabled

Udi10:	begin
	IncAddrA	<= 1'b0;						// always clear the increment address pulse
	if (XiRdy1 == 1'b1) begin	// delay 2 and 3
		EnbA		<= 1'b1;
		WrA		<= 1'b1;
//		CRC_ENB	<= 1'b1;			// calculate the CRC
		iSTATE	<= Udi11;
	end else begin
		if (iDQ	== 1'b1) begin			// if iDQ still valid
			HDMARDY	<= ~PA_AlmostFull;		//20100623 still have space
			STOP		<= 1'b0;						// 20100623 not stopping
			iSTATE	<= Udi10;					// loop here
		end else begin
			HDMARDY	<= 1'b0;						//20100623
			STOP		<= 1'b1;						//20100623
			iSTATE	<= Udix1;					// no more iDQ then exit
		end
	end
end
Udi11:	begin
	iSTATE	<= Udi10;			// loop back for fast processing
	EnbA		<= 1'b0;				// no more RAM enable
	WrA		<= 1'b0;				// no more Wr enable
//	CRC_ENB	<= 1'b0;				// no more CRC
	IncAddrA	<=	1'b1;				// just increment the address
end
//// ========================= exit routine ====================
Udix1:	begin
	if ((Phase3 == 1'b1) && (SiRdy2 == 1'b1)) begin  // wait until the drive drives high the IORDY signal
		iSTATE 	<= Udix2;
	end
end
Udix2:	begin
	CRC_MUX		<= 1'b1;		//20100622 add one clock earlier to turn the CRC_MUX to data bus
	iD_245_In	<= 1'b0;		//20100622 add one clock earlier to turn the 245 outwarts
	if (Phase3 == 1'b1) begin
		iSTATE 	<= Udix3;		// wait at least one clock
	end
end
Udix3:	begin
	iDMA_OE		<= 1'b1;		// 20100622 add one clock earlier drive high the OE to output the CRC address
	if (Phase3 == 1'b1) begin
		iSTATE <= Udix4;			// wait at least two clock
	end
end
Udix4:	begin
	if (Phase3 == 1'b1) begin
		iSTATE <= Udix5;		// wait at least two clock
	end
end
Udix5:	begin
	iDK		<= 1'b0;		// stop the iDK
	if (Phase3 == 1'b1) begin
		iSTATE <= Udix6;		// wait at least two clock
	end
end
Udix6:	begin
	if (Phase3 == 1'b1) begin
		iSTATE <= iIdle1;		// wait at least two clock
	end
end
////-======================================================
//- Ultra DMA Host Out mode - we read from DMA RAM and write to drive
//- only here we detemine the cycle time
//- UDMA(2) = 60nS cycle time = 8 clock
//- UDMA(1) = 80nS (81.6) = 12 clock
//- UDMA(0) = 120nS cycle time = 16 clock
////-======================================================
Uho_0: begin							// UW1 state
	UHO_ARM		<= 1'b1;
	iDK			<= 1'b1;				// enable the iDKs
	STOP			<= 1'b1;				// STOP the system first
	HSTROBE		<= 1'b1;				// STROBE is high
	EnbA			<=	PipeEmpty;		// enable the RAM if the pipeline is empty
	iSTATE		<= Uho_1;			// UW2 state
end
//// ======= entry from temporary stop with refill data  =================
Uho_1: begin							// UW2 state
	iDK			<= 1'b1;				// DMA ready
	EnbA			<= 1'b0;				// already enable the RAM, turn it off
	RegEA			<= PipeEmpty;		// enable register if the pipeline is empty
	iD_245_In	<= 1'b0;				// turn the driver outwards, data is now put to bus
	iSTATE		<= Uho_2;			// UW3 state
end
//// =======
Uho_2: begin
	RegEA			<= 1'b0;						// register already enabled
	HWOE			<= ~PipeEmpty ^ A0;		// if empty uses A0; if not empty uses ~A0
	iSTATE		<= Uho_3;					// UW4 state
end
//// ========
Uho_3: begin		// UW4 state
	STOP			<= 1'b0;						// remove the STOP signal
	if ((SiRdy2 == 1'b0) && (Phase3 == 1'b1)) begin
		iSTATE	<= Uho_4;					// wait till ready
		iDMA_OE	<= 1'b1;						// drive the OE data
	end
end
//// ======== wait 2 clocks ; restart from old break
Uho_4: begin
	if ((SiRdy2 == 1'b0) && (Phase3 == 1'b1)) begin
		IncAddrA	<=	PipeEmpty;				//Increment the address if the pipe is empty
		iSTATE	<= Uho_5;					//wait 1 clock
	end
end
//// ==== already have valid data in the bus
Uho_5: begin
	IncAddrA	<= 1'b0;			// no more increment the address
	if ((SiRdy2 == 1'b0) && (Phase3 == 1'b1)) begin
		EnbA		<=	1'b1;					// after increment address, enable the RAM
		iSTATE	<= Uho_6;
	end
end
/// === one clock +ve data advance offset data bus
Uho_6:	begin
	iSTATE	<= Uho_7;		// jump into the main loop
	EnbA		<= 1'b0;			// disable the RAM
	iWait		<= 1'b0;			// no need to wait here
	HSTROBE	<= 1'b0;			// first strobe edge is low
	CRC_ARM	<= 1'b1;			// enable the CRC machine
end
//// ====== host output loop is here ==================
Uho_7:	begin
/// data bus and associate control signal
	ILatch	<= 1'b1;			// house keeping enable data bus ilatch for CRC calculation
/// determine buffer content, check if more data to send
	if (PA_Empty == 1'b1) begin
		iSTATE	<= Uho_F;			// last data on bus and no more data, normal exit now
	end else begin
		RegEA		<= UDMA[2];			// enable the register now if UDMA-mode 2
		iSTATE	<= Uho_8;			// more data to send, keep looping
	end
end
////
Uho_8:	begin
/// data bus control signal
	RegEA		<= UDMA[1];				// enable the register now if UDMA-mode 1 / disable if mode 2
	ILatch	<= 1'b0;				// stop the input data latch and pass data to CRC engine
	HWOE		<= (UDMA[2] == 1'b1) ? A0 : HWOE;
///////////
	if (UDMA[2] == 1'b1) begin
		IncAddrA	<=	1'b1;			// increase the address
		iSTATE	<= Uho_D;		// 4 clocks 7,8,D,E
	end else begin
		iSTATE	<= Uho_9;
	end
end
/////// ==================================
Uho_9: begin
/// data bus control signal
	RegEA		<= 1'b0;				// disable the register access always
	HWOE		<= (UDMA[1] == 1'b1) ? A0 : HWOE;
/////////
	if (UDMA[1] == 1'b1) begin
		iSTATE	<= Uho_C;	// 6 clocks	7,8,9,C,D,E
	end else begin
		iSTATE	<= Uho_A;
	end
end
////// ===================================
Uho_A: begin
	RegEA		<= UDMA[0];		// enable the register now if UDMA-mode 0 / disable otherwise
	iSTATE	<= Uho_B;		// 8 cycles 7,8,9,A,B,C,D,E
end
///// middle point of the strobe //////======================
Uho_B: begin
/// data bus control signal
	RegEA		<= 1'b0;			// disable the register access always
	HWOE		<= (UDMA[0] == 1'b1) ? A0 : HWOE;
	iSTATE	<= Uho_C;
end
Uho_C:	begin
	iSTATE	<= Uho_D;
	IncAddrA	<=	1'b1;			// increase the address for one clock
end
Uho_D:	begin
	iSTATE	<= Uho_E;
	IncAddrA	<= 1'b0;			// no more increment the address
	EnbA		<=	1'b1;			// after increment address, enable the RAM
end
Uho_E: begin
	EnbA		<= 1'b0;				// disable the RAM
	if (iDQ	== 1'b0) begin		// check iDQ 
		iSTATE	<= Uhx_0;			// lost iDQ abnormal exit
	end else begin
		if (iWait == 1'b0) begin
//			CRC_ENB	<= 1'b1;			// data stobed, so can calculate CRC
			HSTROBE	<= ~HSTROBE;	// toggle the strobe and keep
			iSTATE	<= Uho_7;		// loop back for another data
		end else begin
			iSTATE	<= Uho_E;		// loop here until no more wait
		end
	end
end
//// =========================== end of host output loop =========
/// === all host data out now, determine exit or re-run refill =====================
Uho_F:	begin
	PipeEmpty	<= 1'b1;			// pipe is empty
	ILatch	<= 1'b0;				// stop the input data latch and pass data to CRC engine
	if (Phase3 == 1'b1) begin
		iSTATE		<= Uho_G;		// exit now
	end
end
Uho_G:	begin
	STOP			<= 1'b1;						// drive high the stop signal
	if (Phase3 == 1'b1) begin
		if ((SiRdy2 == 1'b1) && (iDQ == 1'b0)) begin			// wait here until ready and DMA request is gone
			iSTATE <= Uhx_3;			// wait at least two clock
		end else begin
			if (PA_OD_Rdy == 1'b1) begin	// or wait until there is one block of data to transfer out
				EnbA		<=	PipeEmpty;		// enable the RAM if the pipeline is empty (always 1'b1)
				iSTATE 	<= Uho_1;			// jump back into the main loop if there is data
			end
		end
	end
end
//// ==== lost of iDQ, data still in RAM BLOCK Register exit ============
Uhx_0:	begin
	PipeEmpty	<= 1'b0;		// clear flag as the UHO machine has unread content
	if (Phase3 == 1'b1) begin
		iSTATE		<= Uhx_1;
	end
end
Uhx_1:	begin
	if (Phase3 == 1'b1) begin
		iSTATE 	<= Uhx_2;		// wait at least two clock
	end
end
Uhx_2:	begin
	STOP			<= 1'b1;						// drive high the stop signal
	if ((Phase3 == 1'b1) && (SiRdy2 == 1'b1) && (iDQ == 1'b0)) begin			// wait here until ready and DMA request is gone
		iSTATE <= Uhx_3;			// wait at least two clock
	end
end
Uhx_3:	begin
	HSTROBE		<= 1'b1;					// must set high the HSTROBE signal now
	CRC_MUX		<= 1'b1;					// turn the CRC_MUX to data bus
	if (Phase3 == 1'b1) begin
		iSTATE <= Uhx_4;					// wait at least two clock
	end
end
Uhx_4:	begin
	if (Phase3 == 1'b1) begin			// wait here until ready is gone
		iSTATE <= Uhx_5;					// wait at least two clock
	end
end
Uhx_5:	begin
	iDK		<= 1'b0;					// stop the iDK
	if (Phase3 == 1'b1) begin
		iSTATE <= Uhx_6;				// wait at least two clock
	end
end
Uhx_6:	begin
	if (Phase3 == 1'b1) begin
		iSTATE <= iIdle1;				// wait at least two clock
	end
end
//// ======================== end of UHO loop =================
default: begin
	iSTATE <= iIdle1;		// jump to idle for rouge states
end
endcase
end // DMA_ARM
end // clock edges

endmodule
