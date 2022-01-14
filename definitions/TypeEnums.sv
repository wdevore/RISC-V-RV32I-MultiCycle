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
    Reset,
    Vector1,
    Vector2,
    Fetch,
    Decode,
    STStore,
    STMemAcc,
    ITLoad,
    ITLDMemAcc,
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
    BugHalt
} MatrixState /*verilator public*/; 
