// Either MODE0 or MODE1
`define MODE0


typedef enum logic [2:0] {
    SLIdle,       // 000
    SLTransmit,   // 001
    SLShift,// 010
    SLLoad,// 011
    SLLoad2,// 100
    SLCSLoad,// 101
    SLCSLoad2// 110
} SlaveState /*verilator public*/; 

