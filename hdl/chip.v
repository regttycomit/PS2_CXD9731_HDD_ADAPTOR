`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:53:18 09/05/2008 
// Design Name: 
// Module Name:    chip - Behavioral 
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


module chip(
	inout [15:0] iD	,
	// iD15..8	= LQFP(32);LQFP(31);LQFP(30);LQFP(29);LQFP(28);LQFP(27);LQFP(25);LQFP(24);
	// iD7..0	= LQFP(49);LQFP(48);LQFP(47);LQFP(46);LQFP(21);LQFP(20);LQFP(19);LQFP(42);
	output [2:0] iA,
	// iA2 = I50(3)/LQFP(8);		iA1 = I50(5)/LQFP(5);		iA0 = I50(4)/LQFP(7);
	output ibCS0		, 			// LQFP(10)/I50(2)
	output ibCS1		, 			// LQFP(11)/I50(1)
	output ibRST		, 			// LQFP(121)/I50(50)
	input	iIRQ		,   			// LQFP(12)/I50(6) ( needs pull up)
	output ibWr		,				// LQFP(3)/I50(14)
	output ibRd		,				// LQFP(6)/I50(12)
	input iDQ 		,   			// LQFP(18)/I50(16)(1) DMA request - (need pull low) drive inform chip that it wishes to do DMA
	output ibDK		, 				// LQFP(4)/I50(8)(0) DMA acknoledge - chip inform drive that DMA is in progress
	input iRdy		,   			// LQFP(16)/I50(10)(1) high - will means IO channel ready, (needs pull up)
	input ibDASP	,   			// LQFP(13)/I50(7)(0) low - will shows drive is active
//////- the CN110 interface
	input CLKin		,  			// LQFP(129)/J110(81) = 36.6MHz (27.27nS clock pulses)
	input bCSRST	,  			// LQFP(69)/J110(49)power on is high
	input bCRST		,  			// LQFP(70)/J110(52)actual reset signal
	inout [15:0] cDP		,  	// data bus
	// cDP(15..8) = LQFP/J110 = (114/2,113/6,112/8,111/12,110/14,105/18,104/20,103/24)
	// cDP(7 ..0) = LQFP/J100 = (102/26,101/30,99/32,98/36,120/38,117/42,116/44,115/48)
	inout [15:0] cAP		, 	// address bus
	// cAP(15..8) = LQFP/J110 = (96/1,93/3,92/7,91/9,90/13,88/15,87/19,85/21)
	// cAP(7 ..0) = LQFP/J110 = (84/25,83/27,82/31,79/33,78/37,77/39,76/43,75/45)
//
	input bcCS		,  		// LQFP(50)/J110(72)
	input bcWr		,  		// LQFP(60)/J110(73)
	input bcRd		,  		// LQFP(58)/J110(77)
	input bCRT		,  		// LQFP(51)/J110(70)
//
	output	bcWait 	, 		// LQFP(64)/J110(59) ** high a 120ns pulse
	output	bcIRQ		, 		// LQFP(68)/J110(55) ** high at int9 
	output	cDQ		, 		// LQFP(54)/J110(66)
	input		cDK		,  	// LQFP(55)/J110(62)
//
	output	DR245		,		// LQFP(45)
	output	OE245		,		// LQFP(43)
//

////- the following signals are connected but never change
	input ACS_LED  ,  		// LQFP(63)/J110(90) measured high always (pull-high)
	input HDD_ACK  ,  		// LQFP(59)/J110(92) measured high always (pull-high)
////- the following signals are unconnected in the original board
//	input INP1		,			// LQFP(33)
//	input INP2		,			// LQFP(35)
//	input INP3		,			// LQFP(53)
//	input INP4		,			// LQFP(80)
//	input INP5		,			// LQFP(97)
//	input INP6		,			// LQFP(123)
//	input INP7		,			// LQFP(140)
	inout		TFD0	,			// LQFP(124)	TFlash SD D0 (I/OPP) or SPI Data Out (OPP)
	inout		TFD1	,			// LQFP(125)	TFlash SD D1 (I/OPP) or SPI reserve
	inout 	TFD2	,			// LQFP(126)	TFlash SD D2 (I/OPP) or SPI reserve
	inout		TFD3	,			// LQFP(127)	TFlash SD D3 (I/OPP) or SPI Chip Select bCS (I)
	output	TFCLK	,			// LQFP(130)	TFlash CLK
	input		TFSENSE	,		// LQFP(131)	TFlash Sense ( low if TF inserted )
	output	TFCMD		,		// LQFP(132)	TFlash Command		or SPI Data In (I)

// Fixed signals for connecting the SPI external flash
//	FbCS,FMOSI,FDIN,FCCLK {LQFP(41,62,71,72)}
//
// testing signals
//
	output	JT_Result		,		// LQFP(44)
	output	JT_Pin1		,		// LQFP(37)
	input		JT_bTest				// LQFP(38)
);

wire DCM_RST,CLK1,CLK4,DCM_LOCKED ;

reg DWrite;
wire IDERd,IDEWr;
reg iIRQ1;
reg iDQ1,SiIRQ,SiDQ;
wire iDMARd,iDMAWr ;
wire BufEmpty ;
wire PA_HvSpace,PA_OD_Rdy ;
wire PB_HvSpace,PB_OD_Rdy ;
wire WithinBBlock,BBurstEnd;
wire WithinABlock;

wire iCS0,iCS1,cWr,cRd,iWr,iRd,iDK ;
wire [15:0] RegData;
wire [31:0] DMARAMQ;
reg  [31:0] DMARAMD;
reg  [15:0] DIn1,DIn2;
wire cDMA_OE ;
wire cRdt;		// tri-state control signal
wire RegEB;		// the register control signal 


//////
//wire RegSC,RegCMD	_vector(7 downto 0);
//////-=============================================
//// read only registers ( logical wire groups )
wire	[7:0] Reg0038 ;
//// wire	Reg0002,Reg0004,Reg000E _vector(7 downto 0);
wire	[15:0] Reg0028 ;
//// write only registers
//wire Reg002C,Reg0070,Reg0072,Reg0074	_vector(7 downto 0);
////- read write registers //// =====================
reg	[7:0] Reg002A;
wire [7:0] Reg002E;
reg [7:0] Reg0064;
////////- ===========================================
//wire AICtrl,DICtrl ;
wire cDOE,cAOE ;
wire IDE_CS;
reg DMA_ARM,DMARMC,PS2WrIDE ;
wire PA_AlmostFull ;
wire [3:0] BufSize;
reg [2:0] R44;
wire INT9,INT9OE,DMA_IrqCond;
reg DMA_IrqMask, DMA_IrqFF;		// set high if DMA IRQ condition met
wire DMA_IrqCTRL ;
wire bHardReset;
reg ATV1,ATV2,ATV;
wire UDMAC,CmdIsEF,UDMA_SEL,MDMA_SEL,D_UnChg ;
reg R42Is03,R44Is2X,R44Is4X;
wire [2:0] UDMA,MDMA;
reg  [2:0] UDO;
reg [2:1] MDO;

wire Combo_CS,Combo_OE ;
reg cWr1,cRd1,ScWr,ScRd,ScWr1,ScRd1 ;
wire [15:0] cAi,cDi,CRC_Q,iDi,iDO,DOutA;
wire iDOEnb,CRC_MUX ;
wire IDEiOE,iDMA_OE ;
reg [6:0] cRgA;
reg [7:0] cRgD;
wire cRgRd2E,cRgWr;
reg bcRd2E;
reg cRgWrEnb ;
reg [5:0] Rd2ECnt;
reg [3:0] cWaitCnt;
reg cWait;
//// wire BusMatch ;
wire iD_245_In,IDE_Rd_Env ;	// standard logic for envelop
reg SiRdy2,SiRdy1; // a short input buffer
reg IgnoreIRdyPin;		// if IORDY from the drive is always low, then ignore it in normal IDE IO-Read Write cycles
reg Ph0,Ph1,Ph2,Phase3;

wire Reg002E_0, Reg002E_1, Reg002E_2, Reg002E_3, Reg002E_5, Reg002E_6, Reg002E_7;
reg Reg002E_4;
assign Reg002E = {Reg002E_7, Reg002E_6, Reg002E_5, Reg002E_4, Reg002E_3, Reg002E_2, Reg002E_1, Reg002E_0};
//wire ProbeOut ;
//wire ClrDMAPulse,ClrD1,ClrD2 ;
//// =====================
//wire	IDE_INTF_STATE,IDE_DMA_STATE,PS2_DMA_STATE _vector(15 downto 0);
//wire	D_RAM_ReportOut _vector(15 downto 0);
//wire	D_RAM_ReportIn	 _vector(1 downto 0);
//wire	ReportOut		_vector(15 downto 0);
//wire	ReportC			_vector(5 downto 0);
//wire   R380016			_VECTOR(15 DOWNTO 0);
//wire  iRdd1,iRdd2,DOEnb	;
//// ================================================

//wire	[63:0] dna64bits;
//reg	[7:0] dnac;
wire	DNA_Pass,DNA_RST;
wire [3:0] KILL;				// 4 bit killer signals
//reg	DNAS0,DNAS1,DNAS2;		// the DNA output control
//wire	DNA_CS,DNA_OE;				// signal to show the DNA value to IDE bus
//wire  [15:0] DNAO;
//// =========== test stubs ========================
//ReportOut <= X"AAAA"				when (ReportC(5 downto 2) = "0010") else
//				 X"5555"				when (ReportC(5 downto 2) = "0011") else
//				 D_RAM_ReportOut	when (ReportC(5 downto 4) = "01") else
//				 PS2_DMA_STATE		when (ReportC(5 downto 2) = "1000") else
//				 IDE_DMA_STATE		when (ReportC(5 downto 2) = "1001") else
//				 IDE_INTF_STATE	when (ReportC(5 downto 2) = "1010") else
//				 Reg0028				when (ReportC(5 downto 2) = "1011") else
//				 R380016				when (ReportC(5 downto 2) = "1100") else
//				 X"CCCC";
//D_RAM_ReportIn(1 downto 0)	<= ReportC(3 downto 2);
//R380016(15 DOWNTO 8) <= X"00";
//R380016(7 DOWNTO 0) <= Reg0038;

////////////////////////////////////////////////////-
////////////////////////////////////////////////////-

dcm3	Inst_DCM(
	.CLKIN_IN		(CLKin),
	.RST_IN			(DCM_RST),
	.CLKFX_OUT		(CLK4),
	.CLKIN_IBUFG_OUT(),			// same phase as CLKin
	.CLK0_OUT		(CLK1),				// same phase as CLK
	.LOCKED_OUT		(DCM_LOCKED)
);

////- ===== TF machine ======
TF_Stub	Inst_TF_Stub(
	.RESET (DNA_RST),
	.CLK4	(CLK4),
	.TFD0	(TFD0),
	.TFD1	(TFD1),
	.TFD2	(TFD2),
	.TFD3	(TFD3),			// same phase as CLKin
	.TF_CLK		(TFCLK),				// same pahse as CLK
   .TF_CMD		(TFCMD), 
	.TF_SENSE	(TFSENSE)
);


////- ===== DNA 
Top dna1 (
    .reset(DNA_RST), 
    .clk4(CLK4),
	 .IDE_CS(IDE_CS),
    .dna_pass(DNA_Pass),
	 .KILL(KILL)
    );

////- ===============================================
Reg38	R_38(
	.UDMAC		(UDMAC),
	.PS2WrIDE	(PS2WrIDE),
	.iIRQ			(SiIRQ),
	.cDQ			(cDQ),
	.iDQ			(SiDQ),		// synchronize iDQ
	.iDK			(iDK),
	.BufEmpty	(BufEmpty),
	.PB_HvSpace	(PB_HvSpace),
	.BufSize		(BufSize),
	.DOut			(Reg0038)
);
////=========================================================
PS2_DMA	PS2DMA(
//	PS2_DMA_STATE	(PS2_DMA_STATE),
	.CLK4			(CLK4),
	.Phase3		(Phase3),		// the phases
////// external pin interface
	.cDQ			(cDQ),  		// DMA request output
	.cDK			(cDK),  		// DMA acknowledge input
	.cRd			(cRd),		// read signal pulse
	.DWrite		(DWrite),	// write and counter pulse
////// controlling signal
	.DMA_ARM		(DMA_ARM),		// signal from ctrllr to inits DMA
	.PS2WrIDE	(PS2WrIDE),	// level indicating that PS2 is DMA writing IDE bus
//// PS2 DMA connecting to RAM interface
	.PB_HvSpace	(PB_HvSpace),		// there is empty space for Port B
	.PB_OD_Rdy	(PB_OD_Rdy),		// some data availabe for output from Port B
////
	.WithinBBlock	(WithinBBlock),	// high if (AddrB(6) OR AddrB(5)) = 1
	.BBurstEnd	(BBurstEnd),			// high if AddrB = xxxx11111 = 1F
	.IncAddrB	(IncAddrB),
	.RegEB		(RegEB),
	.EnbB			(EnbB),
	.WrB			(WrB )			// write pulse
);
////-======================================================
D_RAM		DMARAM(
	.CLK4			(CLK4),
	.DMA_ARM		(DMA_ARM),
	.PS2WrIDE	(PS2WrIDE), 			// High if PS2 DMA write to IDE bus
//// =====
	.CRC_ARM		(CRC_ARM),
	.CRC_ENB		(CRC_ENB),
	.CRC_Q		(CRC_Q),
//// =====
	.PA_HvSpace	(PA_HvSpace),		// there is empty space for Port A
	.PA_OD_Rdy	(PA_OD_Rdy),		// some data availabe for output from Port A
	.PA_AlmostFull	(PA_AlmostFull),
	.PA_Full		(PA_Full),
	.PA_Empty	(PA_Empty),
	.WithinABlock	(WithinABlock),
//// =====	
	.PB_HvSpace	(PB_HvSpace),		// there is empty space for Port B
	.PB_OD_Rdy	(PB_OD_Rdy),		// some data availabe for output from Port B
//// =====
	.BufSize		(BufSize),
	.BufEmpty	(BufEmpty),			// set when no words in the FIFO buffer
//// =====
	.DInA			(DIn2),
	.DOutA		(DOutA),
	.DInB 		(DMARAMD), 
//// ==== 1st port RAM access
	.A0			(A0),
	.HWOE			(HWOE),
	.IncAddrA	(IncAddrA),
	.EnbA		(EnbA),
	.WrA			(WrA),
	.RegEA	(RegEA),
//// ==== 2nd port RAM access
	.WithinBBlock	(WithinBBlock),		// high if (AddrB(6) OR AddrB(5)) = 1
	.BBurstEnd	(BBurstEnd),				// high if AddrB = xxxx11111 = 1F
	.IncAddrB		(IncAddrB),
	.EnbB			(EnbB),
	.RegEB			(RegEB),
	.WrB 			(WrB),  
	.DOutB 		(DMARAMQ)
);
//// =========================================
IDE_DMA	IDEDMA (
//	IDE_DMA_STATE	(IDE_DMA_STATE),
	.CLK4		(CLK4),
	.Phase3	(Phase3),
////// external pin interface
	.iDK		(iDK),  			// (o) DMA acknowledge output to harddisk
	.iDQ		(SiDQ),  			// (i) DMA request input from harddisk
	.SiRdy1	(SiRdy1),				// (i) IDE bus ready signal
	.SiRdy2	(SiRdy2),
////// system signal
	.DMA_ARM(DMA_ARM),	// do not request transaction if this is not armed
	.PS2WrIDE	(PS2WrIDE), 		// (i) '1' if direction is from PS2 to IDE
	.UDMA 		(UDMA),
	.MDMA		(MDMA),
	.iDMARd	(iDMARd),			// (o) active high signal to indicate DMA read
	.iDMAWr	(iDMAWr), 			// (o) active high signal to indicate DMA write
	.iDMA_OE	(iDMA_OE),			// (o) active high signal showing DMA wishes to drive iD bus
	.iD_245_In	(iD_245_In),	// (o) active high envelop signal to drive output bus
	.CRC_MUX	(CRC_MUX),			// inform system that need to drive the CRC Q to IDE bus
	.CRC_ARM	(CRC_ARM),			// a signal indicate that to clear the CRC state
	.CRC_ENB	(CRC_ENB),
////// interface the RAM buffer), DMA machine will act according to buffer
	.PA_HvSpace	(PA_HvSpace),		// there is empty space for Port A
	.PA_OD_Rdy	(PA_OD_Rdy),		// some data availabe for output from Port A
	.WithinABlock	(WithinABlock),
	.PA_AlmostFull(PA_AlmostFull),
	.PA_Full		(PA_Full),
	.PA_Empty	(PA_Empty),
	.IDE_DSTB	(IDE_DSTB),
	.IncAddrA	(IncAddrA),
	.A0		(A0),
	.HWOE		(HWOE),
	.EnbA		(EnbA),
	.WrA			(WrA),
	.RegEA	(RegEA)
);
//// =========================================

//- Probes
// (I/P) JT_bTest is the tester control port, during config, this is high; this should be DONE signal inverted by a 74LS04
// (I/P) JT_Pin1 is the selection port of ROM
// (O/P) JT_Result is the result port (if DNA_Pass then it is low)
assign JT_Result	= (JT_bTest == 1'b0) ? ( ~DNA_Pass ) : ( HDD_ACK | ACS_LED | ibDASP | bCRT ); // will output low if DNA_Pass
assign JT_Pin1		=  TFCLK;			// pull low for 50A, left high for 50AN

/// ===========================================================================
/// ===========================================================================
//	ClrDMAPulse = ~(bcCS) & ~(bcWr) & ClrD1 & ClrD2;
//	ClrD1	= '1' when (cAi(15 downto 0) = X"0032") else '0';
//	ClrD2 = '1' when (cDi(15 downto 0) = X"0003") else '0';

////- ===  CLOCK & reset signals ===========================================
assign DCM_RST		= ~bCRST | ~bCSRST;		// drive high if any pin is low
assign bHardReset	=  bCRST & DCM_LOCKED;	// the lowest level of reset
assign DNA_RST		= ~DCM_LOCKED;					// active high reset signal
/// ===== Phase generation logic ==================================
always @(negedge CLK1) begin
	if (DCM_LOCKED == 1'b0) begin
		Ph0 <= 1'b0;
	end else begin
		Ph0 <= ~Ph0;				// a toggling signal
	end
end

always @(negedge CLK4) begin
	Ph1	<=	Ph0;
	Ph2	<= Ph1;
end

always @(posedge CLK4) begin
	Phase3	<= Ph1 ^ Ph2;
end
//// ==========================================================================

	
//// ==========================================================================
// output signal
//// Register 64 signals
	assign ibRST	= ~(Reg0064[7]);
	assign ibCS0	= ~(iCS0);		// convert to correct pin polarity
	assign ibCS1	= ~(iCS1);
	assign ibRd		= ~(iRd);
	assign ibWr		= ~(iWr);
	assign ibDK		= ~(iDK);		// DMA acknowledge output, active low
//// IDE Data bus control signal
	assign iRd	= ( IDERd & ~iDK ) | (iDMARd & iDK);
	assign iWr	= ( IDEWr & ~iDK ) | (iDMAWr & iDK);
//////- the CN110 interface
// input signal
	assign cRd	= ~bcRd & ~KILL[0];
	assign cRdt	= ~bCRT & ~KILL[0];		// tristate control circuit
	assign cWr	= ~bcWr & ~KILL[0];
//// ============================================================================================
//// Interrupt signal
// interrupt will be set either by IDE interrupt line | an interrupt signal by DMA F/F
	assign INT9OE	= Reg002A[1] | Reg002A[0];
	assign bcIRQ	= (INT9OE == 1'b1) ? ~(INT9) : 1'bZ;
	assign INT9		= (SiIRQ & Reg002A[0]) | (DMA_IrqFF & DMA_IrqCTRL);
////============= c-Connector data bus  =======================
	assign cDMA_OE	=	cRdt & cDK;					// output the data bus
	assign cDOE	= ATV & (cDMA_OE | Combo_OE);	// DMA/CS PS2 read will drive the bus
	assign cDP 	=	(cDOE		== 1'b0) ?	{16{1'bZ}}		:
						(cDK 		== 1'b1) ?	DMARAMQ[15:0]	:
						(IDE_CS	== 1'b1)	?	iDi[15:0]		:	RegData[15:0];
	assign cDi	= cDP;
//- c-Connector Address bus
	assign cAOE	= ATV &  cDMA_OE;					// DMA PS2 read will drive the bus
	assign cAP 	=	(cAOE == 1'b0) ? {16{1'bZ}}		: DMARAMQ[31:16];
	assign cAi	= cAP;
////
//// ============================================================================================
//// Control signals // must wait until bus matching for IDE signals
//	assign BusMatch = ((cDi[15] ~^ iDi[15]) & (cDi[14] ~^ iDi[14]) & (cDi[13] ~^ iDi[13]) &
//					 (cDi[12] ~^ iDi[12]) & (cDi[11] ~^ iDi[11]) & (cDi[10] ~^ iDi[10]) &
//					 (cDi[9]  ~^ iDi[9])  & (cDi[8]  ~^ iDi[8])  & (cDi[7]  ~^ iDi[7])  &
//					 (cDi[6]  ~^ iDi[6])  & (cDi[5]  ~^ iDi[5])  & (cDi[4]  ~^ iDi[4])  &
//					 (cDi[3]  ~^ iDi[3])  & (cDi[2]  ~^ iDi[2])  & (cDi[1]  ~^ iDi[1])  &
//					 (cDi[0]  ~^ iDi[0]));
//- the combo chip select range = 0x0000-0x007F
	assign Combo_CS = ATV & ~cDK & ~(bcCS | cAi[15] | cAi[14] | cAi[13] | cAi[12] |
												cAi[11] |	cAi[10] | cAi[9] | cAi[8] | cAi[7]);
	assign Combo_OE = cRd & Combo_CS;			// asynchronous active reading signal
	
//// ================== IDE interface section =================================================

//====== iDE data bus ================================
// IDE data bus control
//	ProbeOut				= (cWr | cRd) & ~(IDE_CS) & ~(iDK) & ~(cDK);
//	iDOEnb				= IDEiOE | iDMA_OE | ProbeOut;		// signal we can drive the bus
//
// 090313
//  The ORIGINAL signal
	assign iD[15:0]	= (iDOEnb == 1'b1) ? iDO[15:0] : {16{1'bZ}};
	assign iDOEnb		= IDEiOE | iDMA_OE;		// signal we can drive the bus
	assign iDi[15:0]	= iD[15:0];
	assign iDO[15:0]	=	(IDE_CS  == 1'b1) ?	 cDi[15:0] : 
								(CRC_MUX == 1'b1) ? CRC_Q[15:0] : DOutA[15:0];
//
//// --- iD out also output DNA data
//// ==== The DNA showing session ====
//	assign	iDOEnb		= 1'b1;
//	assign	iD[15:0]		= iDO[15:0];
//	assign	iDO[15:0]	=	(dnac[7] == 1'b0) ? 
//										((dnac[6] == 1'b0) ? dna64bits[63:48] : dna64bits[47:32] ) :
//										((dnac[6] == 1'b0) ?	dna64bits[31:16] : dna64bits[15:0] );
//	assign	iDi[15:0]	= iD[15:0];
//// 
//
// 090313
//
//
//  0000 0000 010* **** = 0x0040-0x005F
assign IDE_CS	= Combo_CS & ~iDK & cAi[6] & ~cAi[5]; //- if address range is correct and we are not doing iDK
assign iCS1		= IDE_CS &  cAi[4] & ~KILL[2];
assign iCS0		= IDE_CS & ~cAi[4] & ~KILL[2];
assign iA[2]	= IDE_CS & cAi[3] & ~KILL[1];
assign iA[1]	= IDE_CS & cAi[2] & ~KILL[2];
assign iA[0]	= IDE_CS & cAi[1] & ~KILL[3];
assign IDERd	= IDE_CS & cRd & ~KILL[1];
assign IDEWr	= IDE_CS & cWr & ~KILL[2];	// narrow down the write pulse
assign IDEiOE	= IDE_CS & cWr;	// writing IDE, we drive the IDE i Bus
//	IDE_Rd_Env	= (IDE_CS & cRd) | IDERd1;		// reading, we drive the 245 inwards
assign IDE_Rd_Env	= IDE_CS & cRd;
//////////////////////////////////////////////////////////////////////
//- Local Register Block
//// ===== Read only registers
//	Reg0002(7 downto 2) = "000100";	// prepare to be 13
//	Reg0002(1) = ~(DNA_Fail);		// should always be 1 ( ~ fail)
//	Reg0002(0) = DNA_Pass;				// should always be 1 (pass)
//	Reg0002[7:0] = "00010011";	// fixed at 13
//	Reg0004	= X"0B";
//	Reg000E	= X"02";
// Reg0028 has many bits being zero ////////////////////////
// Reg0028 is probably the DMA RAM Buffer register
//	assign Reg0028[15]	= Reg2815;			// set when buffer is full
	assign Reg0028[15]	= BufSize[3];		// set when buffer is full
	assign Reg0028[14]	= BufEmpty;
//	Reg0028(14) = (~(PS2WrIDE) & BufEmpty) | (PS2WrIDE & (AlmostEmpty | BufEmpty));			// BufEmpty
//	Reg0028(14) = (~(PS2WrIDE) & (AlmostEmpty | BufEmpty)) | (PS2WrIDE & HaveSpace);			// Performs much better than BufEmpty in xboot writing
//	Reg0028(14) = AlmostEmpty;			// Performs much better than BufEmpty in xboot writing
	assign Reg0028[13:2] = 12'b0000_0000_0000;
	assign Reg0028[1]	= cDQ;
	assign Reg0028[0]	= SiIRQ;				// the interrupt condition of external
//// Reg002A the interrupt control register ///////////////////////////////////////////
//// local registers //////////////////////////
	assign RegData[15:8] =	(cAi[6:0] == 7'h28)	?	Reg0028[15:8]	: 8'h00;
////////////////////////////////////////
	assign RegData[7:0]	=	(cAi[6:0] == 7'h02)	?	8'h13 			:
									(cAi[6:0] == 7'h04)	?	8'h0B 			:
									(cAi[6:0] == 7'h0E)	?	8'h02				:
									(cAi[6:0] == 7'h28)	?	Reg0028[7:0]	:
									(cAi[6:0] == 7'h2A)	?	Reg002A[7:0]	:
						//			(cAi[6:0] == 7'h2C)	?	Reg002C[7:0]	:
									(cAi[6:0] == 7'h2E)	?	Reg002E[7:0]	:
									(cAi[6:0] == 7'h38)	?	Reg0038[7:0]	:
									(cAi[6:0] == 7'h64)	?	Reg0064[7:0]	: 8'h00;
////- Reg0064 has zero bits write 4C then will write IDECmd87 to set direction
//	Probably Reg0064 is the reset & interrupt control
// if reading & PortB have data
//  | Writing & PortA have space
	assign DMA_IrqCond	=	(~(PS2WrIDE) & PB_OD_Rdy) | (PS2WrIDE & PB_HvSpace);
	assign DMA_IrqCTRL	= Reg002A[1];
	
////- ====================================	
	assign UDMAC	= UDO[2] | UDO[1] | UDO[0];
//////////////////////////////////////////////////////////////////


//- ===== selecting the drive mode is by ===
//- ATA command set features (EF,xx,xx,xx,xx,Table20,03)
assign CmdIsEF		= cRgD[7] & cRgD[6] & cRgD[5] & ~(cRgD[4]) &	cRgD[3] & cRgD[2] & cRgD[1] & cRgD[0];
assign UDMA_SEL	= CmdIsEF & R44Is4X & R42Is03;
assign MDMA_SEL 	= CmdIsEF & R44Is2X & R42Is03;
assign D_UnChg		= ~(UDMA_SEL | MDMA_SEL);		// do not change the data if both control are low
assign UDMA[2:0]	= UDO[2:0];
assign MDMA[2] 	= MDO[2];
assign MDMA[1]		= MDO[1];
assign MDMA[0]		= ~(UDO[2] | UDO[1] | UDO[0] | MDO[2] | MDO[1]);
//////- =======================================
assign Reg002E_7 = 1'b1;
assign Reg002E_6 = 1'b1;
assign Reg002E_5 = 1'b0;

assign Reg002E_3 = 1'b1;
assign Reg002E_2 = 1'b1;
assign Reg002E_1 = 1'b1;
assign Reg002E_0 = 1'b0;
// Reg002E is always CE | DE

//////- =======================================
assign cRgWr	= ATV & ScWr1 & ~(ScWr) & cRgWrEnb;		// old time is 1, new is off
assign cRgRd2E	= ATV & ScRd1 & ~(ScRd) & bcRd2E;			// the single read pulse for 2E
//////- =============== control the direction of the buffers ============
assign OE245	= ~(ATV);		// almost always valid
assign DR245	= ~(IDE_Rd_Env | iD_245_In);			// high = 3V3 bus drives disk I/O, = iWR |
																		//- low when ( iRd for MDMA and normal, or iDK AND UDI mode)
////- ===================================================================
always @(posedge bcWr) begin
	cRgWrEnb		<=	Combo_CS & ScWr & ScWr1;		// if selecting the register, then we might have write pulse
	cRgA[6:0]	<= cAi[6:0];
	cRgD[7:0]	<= cDi[7:0];
end

always @(posedge bcRd) begin
	bcRd2E	<= Combo_CS & ScRd & ScRd1 & ~(cAi[6]) & cAi[5] & ~(cAi[4]) & cAi[3] & cAi[2] & cAi[1] & ~(cAi[0]);
end

//// =============================
//always @(negedge CLK1) begin
//	DMARAMD[15:0] 	<= cDi[15:0];		// lower word to RAM
//	DMARAMD[31:16]	<= cAi[15:0];		// upper word to RAM
//end
always @(posedge CLK4) begin
	if ((Ph1 ^ Ph2) == 1'b1) begin
		DMARAMD[15:0] 	<= cDi[15:0];		// lower word to RAM
		DMARAMD[31:16]	<= cAi[15:0];		// upper word to RAM
	end
end
//// =============================
always @(posedge CLK1) begin
	DWrite	<= cWr & cDK;
end

//// ============================================================================================
//// ===== IDE bus interface wait engine ========================================================
//// ============================================================================================
assign bcWait	= (IDE_CS == 1'b1) ? ~cWait : 1'bZ; // will output low if cWait = '1'

always @(posedge CLK4) begin
	if (IDE_CS == 1'b0) begin
		cWaitCnt	<= 4'b0000;		// clear wait counter
		cWait		<= 1'b1;			// must wait
		IgnoreIRdyPin	<= ~SiRdy2;		// if IORDY is always low then ignore it, it will not affect our engine
	end else begin
		if (cWaitCnt == 4'b1010) begin 
//			if ((SiRdy2 == 1'b1) && (BusMatch == 1'b1)) begin
			if ((IgnoreIRdyPin == 1'b1) || (SiRdy2 == 1'b1)) begin
				cWait	<= 1'b0;		// end if
			end
		end else begin
			cWaitCnt <= cWaitCnt + 1;
		end
	end
end
//// ============================================================================================
//// ============================================================================================

always @(posedge CLK4) begin
//// synchronous Reset section
	if (bHardReset == 1'b0) begin
////
		Reg002A		<= 8'h00;
		Reg002E_4	<= 1'b0;		// first data is CE, next data can be CE or DE
		Rd2ECnt		<= 6'b000001;	// clear the Rd2E counter
		Reg0064		<= 8'h80;		// activate the IDE reset signal
		DMA_IrqMask	<= 1'b0;
		DMA_IrqFF 	<= 1'b0;			// clear the DMA request flipflop
		PS2WrIDE	 	<= 1'b0;			// set up the direction
		MDO[2]		<= 1'b0;		// DMA mode is multiword mode 0
		MDO[1]		<= 1'b0;
		UDO			<= 3'b000;		// not UDMA mode
		DMARMC		<= 1'b0;
		DMA_ARM		<= 1'b0;
////--- first filter
		iDQ1			<= 1'b0;
		iIRQ1			<= 1'b0;
		cWr1			<= 1'b0;
		cRd1			<= 1'b0;
		SiRdy1		<= 1'b1;
//// ========  2nd filter ========
		SiDQ			<= 1'b0;
		SiIRQ			<= 1'b0;
		ScWr			<= 1'b0;
		ScRd			<= 1'b0;
		SiRdy2		<= 1'b1;
//// ========= 3rd filter ======
		ScRd1			<= 1'b0;
		ScWr1			<= 1'b0;
//// =============================
		ATV1			<= 1'b0;
		ATV2			<= 1'b0;
		ATV			<= 1'b0;
//// =========
//		DNAS0			<= 1'b0;
//		DNAS1			<= 1'b0;
	end else begin
		ATV1			<= 1'b1;
		ATV2			<= ATV1;
		ATV			<= ATV2;		// 2 filter for ATV signal
//// ======== first filter =====
		iDQ1		<= iDQ;			// try to synchronize the system clock
		iIRQ1		<= iIRQ;			// synchronize again
		cWr1		<= cWr;
		cRd1 		<= cRd;
		SiRdy1	<= iRdy;
		DIn1		<= iDi;							// get the data
//		IDERd1	<= IDERd;		// one delay signal to control output buffer direction
//// ========  2nd filter ========
		SiDQ		<= iDQ1;
		SiIRQ		<= iIRQ1;
		ScWr		<= cWr1;
		ScRd		<= cRd1;
		SiRdy2	<= SiRdy1;
		if (IDE_DSTB == 1'b1) DIn2		<= DIn1;
//// ========= 3rd filter ======
		ScRd1		<= ScRd;
		ScWr1		<= ScWr;
//// =============================
//		The DNA output counter value
//		if (((ScRd1 == 1'b1) && (ScRd == 1'b0)) || ((ScWr1 == 1'b1) && (ScWr == 1'b0))) begin
//			DNAS0		<= ~DNAS0;
//			DNAS1		<= DNAS1 ^ DNAS0;
//		end
//		Reg2815	<= PS2WrIDE & (PA_AlmostFull | (~(PA_HvSpace) & Reg2815));
//// =======================================
		if (cRgRd2E == 1'b1) begin		// read pulse post processing, check which register is read
			if ((Rd2ECnt == 6'b000110) || (Rd2ECnt == 6'b010010) || (Rd2ECnt == 6'b010011) || (Rd2ECnt == 6'b010101) ||
				(Rd2ECnt == 6'b010111) || (Rd2ECnt == 6'b011100) || (Rd2ECnt == 6'b011101) || (Rd2ECnt == 6'b011110) ||
				(Rd2ECnt == 6'b011111) || (Rd2ECnt == 6'b100000) || (Rd2ECnt == 6'b100011) || (Rd2ECnt == 6'b100100) ||
				(Rd2ECnt == 6'b100101) || (Rd2ECnt == 6'b100110) || (Rd2ECnt == 6'b100111) || (Rd2ECnt == 6'b101000) ||
				(Rd2ECnt == 6'b101001) || (Rd2ECnt == 6'b101110) || (Rd2ECnt == 6'b110000) || (Rd2ECnt == 6'b110001) ||
				(Rd2ECnt == 6'b110011) || (Rd2ECnt == 6'b110101) || (Rd2ECnt == 6'b110110) || (Rd2ECnt == 6'b111000) ||
				(Rd2ECnt == 6'b111001) || (Rd2ECnt == 6'b111011) || (Rd2ECnt == 6'b111110))
			begin
				Reg002E_4	<= 1'b1;		// Reg002E <= x"DE";
			end else begin
				Reg002E_4	<= 1'b0;		// Reg002E <= x"CE";
			end
			Rd2ECnt <= Rd2ECnt + 1;
		end
////- ==============================
		if (cRgWr == 1'b0) begin
	//// Always running section the DMA controller reset section ////
			DMARMC	<= ATV;			// DMA_ARM is two clock width
			DMA_ARM	<= DMARMC;		// DMA_ARM is two clock width, put to clear register
	//// The interrupt controller section always running after hard reset////
			if (DMA_IrqMask == 1'b1) begin
				DMA_IrqMask <= DMA_IrqCond;		// only interrupt once until the condition is remove
			end
			if ((DMA_IrqCond == 1'b1) && (DMA_IrqMask == 1'b0)) begin
				DMA_IrqMask	<= DMA_IrqCTRL;	// no more retrigger
				DMA_IrqFF 	<= DMA_IrqCTRL;	// the DMA interrupt request pulse from DMA/IDE unit
			end
		end else begin		// only one write pulse
	//// 002A
		case (cRgA[6:0])
			7'b0101010: begin		// 002A
				Reg002A[7:0] <= cRgD[7:0];
				if (cRgD[7:0] == 8'h00) DMA_IrqFF <= 1'b0;			// clear the DMA_IrqFF
			end
	//// 002C
			7'b0101100: begin		// 002C
				if (cRgD == 8'hE1) begin
					Rd2ECnt <= 6'b00_0001;		// start up the counter
	//				Reg002C[7:0]	<= cRgD[7:0];
				end
			end
	//// 0032
			7'b0110010: begin		// 0032
				DMARMC		<= 1'b0;
				DMA_ARM		<= 1'b0;	//// clear the ARM signal
				DMA_IrqFF	<= 1'b0;	// clear all possible old DMA interrupt
				Reg0064[2]	<= 1'b0;
				PS2WrIDE		<= cRgD[0];		// set the direction
			end
	//// 0038
	//			if (cRgA[6:0]= "0111000") begin		// 0038
	//				if (cRgD = X"03") begin
	//					DMA_ARM	<= 1'b0;
	//				end if;
	//			end if;
	//// 0042
			7'b1000010: begin		// 0042
				R42Is03	<= ~(cRgD[7] | cRgD[6] | cRgD[5] | cRgD[4] | cRgD[3] | cRgD[2]) & cRgD[1] & cRgD[0];
			end
	//// 0044
			7'b1000100: begin		// 0044
				R44Is2X	<= ~(cRgD[7] | cRgD[6] | cRgD[4] | cRgD[3]) & cRgD[5];
				R44Is4X	<= ~(cRgD[7] | cRgD[5] | cRgD[4] | cRgD[3]) & cRgD[6];
				R44[2]	<= cRgD[2];
				R44[1]	<= cRgD[1];
				R44[0]	<= cRgD[0];
			end
	//// 004E
			7'b1001110: begin		// 004E
				UDO[2]	<= (D_UnChg & UDO[2]) | (~(D_UnChg) & UDMA_SEL & R44[2]);
				UDO[1]	<= (D_UnChg & UDO[1]) | (~(D_UnChg) & UDMA_SEL & R44[1]);
				UDO[0]	<= (D_UnChg & UDO[0]) | (~(D_UnChg) & UDMA_SEL & R44[0]);
				MDO[2]	<= (D_UnChg & MDO[2]) | (~(D_UnChg) & MDMA_SEL & R44[2]);
				MDO[1]	<= (D_UnChg & MDO[1]) | (~(D_UnChg) & MDMA_SEL & R44[1]);
			end
	//// 0064
			7'b1100100: begin		// 0064 
				Reg0064[7:0] <= cRgD[7:0];
			end
		endcase
		end	// Write Pulse group
	end // bcRST group
end	// clock
endmodule
