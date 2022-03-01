// ALU operations are identified funct combination.
//                    funct3   +   funct7   = 10 bits (only 6 are used)
typedef enum logic [`ALUOpSize-1:0] {
    AddOp  = `ALUOpSize'b000_000,
    SubOp  = `ALUOpSize'b000_010,
    SllOp  = `ALUOpSize'b001_000,
    SltOp  = `ALUOpSize'b010_000,
    SltuOp = `ALUOpSize'b011_000,
    XorOp  = `ALUOpSize'b100_000,
    SrlOp  = `ALUOpSize'b101_000,
    SraOp  = `ALUOpSize'b101_010,
    OrOp   = `ALUOpSize'b110_000,
    AndOp  = `ALUOpSize'b111_000
} ALU_Ops /*verilator public*/; 

typedef enum logic [4:0] {
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

typedef enum logic [4:0] {
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
    JTJalStr,
    JTJalr,
    JTJalrPC,
    JTJalrStr,
    UType,
    UTStr,
    IRSTUnknown
} InstructionState /*verilator public*/; 

typedef enum logic [2:0] {
    BTBeq = 3'b000,
    BTBne = 3'b001,
    BTBlt = 3'b100,
    BTBge = 3'b101,
    BTBltu = 3'b110,
    BTBgeu = 3'b111
} BranchType /*verilator public*/; 

typedef enum logic [1:0] {
    ASrcPC     = 2'b00,
    ASrcPrior  = 2'b01,
    ASrcZero   = 2'b10,
    ASrcRsa    = 2'b11
} AMuxSrc /*verilator public*/; 

typedef enum logic [1:0] {
    ASrcRsb     = 2'b00,
    ASrcFour    = 2'b01,
    ASrcImm     = 2'b10
} BMuxSrc /*verilator public*/; 

typedef enum logic {
    RgLdEnabled     = 1'b0,
    RgLdDisabled    = 1'b1
} RegisterLoad /*verilator public*/; 

typedef enum logic [1:0] {
    PCSrcAluImm   = 2'b00,
    PCSrcAluOut   = 2'b01,
    PCSrcResetVec = 2'b10,
    PCSrcResetAdr = 2'b11
} PCSrc /*verilator public*/; 
