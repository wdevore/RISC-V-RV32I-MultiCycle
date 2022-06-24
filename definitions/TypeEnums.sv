// ALU operations are identified funct combination.
//            funct3   +   funct7   = 10 bits (only 6 are used)
typedef enum logic [`ALUOpSize-1:0] {
    AddOp  = `ALUOpSize'b000_000,
    SubOp  = `ALUOpSize'b000_010,
    XorOp  = `ALUOpSize'b100_000,
    OrOp   = `ALUOpSize'b110_000,
    AndOp  = `ALUOpSize'b111_000,
    SllOp  = `ALUOpSize'b001_000,
    SrlOp  = `ALUOpSize'b101_000,
    SraOp  = `ALUOpSize'b101_010,
    SltOp  = `ALUOpSize'b010_000,
    SltuOp = `ALUOpSize'b011_000
} ALU_Ops /*verilator public*/; 

typedef enum logic [4:0] {
    Sync0,
    Vector0,
    Vector1,
    Vector2,
    Vector3
} ResetState /*verilator public*/; 

typedef enum logic [4:0] {
    Reset,
    Fetch,
    Decode,
    Execute,
    Halt        // Not technically a RISC-V state
} MatrixState /*verilator public*/; 

typedef enum logic [`IRStateSize-1:0] {
    STStore,
    STMemAcc,
    STMemWrt,
    STMemRrd,
    ITLoad,
    ITLDMemAcc,
    ITLDMemMdr,
    ITLDMemCmpl,
    RType,
    RTCmpl,
    BType,
    BTBranch,
    BTCmpl,
    ITALU,
    ITALUCmpl,
    JTJal,
    JTJalRtr,
    ITJalr,
    ITJalrRtr,
    UType,
    UTCmpl,
    UTypeAui,
    UTAuiCmpl,
    ITEbreak,
    ITECall,
    ITCSR,
    ITCSRLd,
    IRQ0,
    IRQ1,
    IRQ2,
    ITMret,
    ITMretClr,
    PreFetch,
    IRUnknown
} InstructionState /*verilator public*/; 

typedef enum logic [2:0] {
    BTBeq  = 3'b000,
    BTBne  = 3'b001,
    BTBlt  = 3'b100,
    BTBge  = 3'b101,
    BTBltu = 3'b110,
    BTBgeu = 3'b111
} BranchType /*verilator public*/; 

typedef enum logic [2:0] {
    ITSlli = 3'b001,
    ITSrli = 3'b101  // srai as well
} ITypeImm /*verilator public*/; 

typedef enum logic [1:0] {
    ASrcPC     = 2'b00,
    ASrcPrior  = 2'b01,
    ASrcZero   = 2'b10,
    ASrcRsa    = 2'b11
} AMuxSrc /*verilator public*/; 

typedef enum logic [1:0] {
    BSrcRsb     = 2'b00,
    BSrcFour    = 2'b01,
    BSrcImm     = 2'b10,
    BSrcZero    = 2'b11
} BMuxSrc /*verilator public*/; 

typedef enum logic [1:0] {
    WDSrcImm     = 2'b00,
    WDSrcALUOut  = 2'b01,
    WDSrcMDR     = 2'b10,
    WDSrcCSR     = 2'b11
} WDMuxSrc /*verilator public*/; 

typedef enum logic {
    RgLdEnabled     = 1'b0,
    RgLdDisabled    = 1'b1
} RegisterLoad /*verilator public*/; 

typedef enum logic {
    RWActive     = 1'b0,
    RWInActive   = 1'b1
} ReadWriteSignal /*verilator public*/; 

typedef enum logic [2:0] {
    PCSrcAluImm   = 3'b000,
    PCSrcAluOut   = 3'b001,
    PCSrcResetVec = 3'b010,
    PCSrcRDCSR    = 3'b011,
    PCSrcResetAdr = 3'b100
} PCSrc /*verilator public*/; 

// ------------------------------------------------------
// CSRs
// ------------------------------------------------------
typedef enum logic [2:0] {
    CSRRW  = 3'b001,
    CSRRS  = 3'b010,
    CSRRC  = 3'b011,
    CSRRWI = 3'b101,
    CSRRSI = 3'b110,
    CSRRCI = 3'b111
} CSRType /*verilator public*/; 

typedef enum logic[`CSRAddrSize-1:0] {
    Mstatus  = 12'h300,
    Mie      = 12'h304,
    Mtvec    = 12'h305,
    Mscratch = 12'h340,
    Mepc     = 12'h341,
    Mcause   = 12'h342,
    Mtval    = 12'h343,
    Mip      = 12'h344
} CSReg /*verilator public*/; 

// typedef enum logic {
//     CMCSRAddr  = 1'b0,  // Control matrix supplies address
//     IRSource   = 1'b1   // Immediate in IR
// } CSRAddrSrc /*verilator public*/; 

// typedef enum logic [1:0] {
//     CSRSrcCM  = 2'b10,  // CM data sources
//     CSRSrcPC  = 2'b01,  // PC sources
//     CSRSrcRsA = 2'b00   // RsA sources
// } CSRSrc /*verilator public*/; 

// typedef enum logic {
//     CMCSRIr    = 1'b0,  // Control matrix supplies address
//     IIRSource  = 1'b1   // Immediate in IR
// } CSRIRSrc /*verilator public*/; 
