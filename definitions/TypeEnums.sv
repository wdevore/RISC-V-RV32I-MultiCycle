typedef enum logic [3:0] {
    AddOp,
    SubOp,
    AndOp,
    OrOp,
    XorOp,
    SltuOp,
    SltOp,
    SllOp,
    SrlOp,
    SraOp
} ALU_Ops /*verilator public*/; 

typedef enum logic [4:0] {
    Vector0,
    Vector1,
    Vector2,
    Vector3,
    Vector4
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
    ITLoad,
    ITLDMemAcc,
    ITLDMemMdr,
    ITLDMemCmpl,
    RType,
    RTCmpl,
    BType,
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
