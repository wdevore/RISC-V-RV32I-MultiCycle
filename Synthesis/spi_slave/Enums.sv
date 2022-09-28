// Either MODE0 or MODE1
`define MODE0


typedef enum logic [2:0] {
    // SLReset,
    SLIdle,           // Waiting to transmit
    SLBegin,
    SLTransmitting,   // Sending bits
    SLComplete
} SlaveState /*verilator public*/; 

