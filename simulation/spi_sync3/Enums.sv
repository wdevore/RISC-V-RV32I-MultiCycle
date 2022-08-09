// Either MODE0 or MODE1
`define MODE0

typedef enum logic [2:0] {
    MSReset,
    MSIdle,           // Waiting to transmit
    MSBegin,
    MSTransmitting,   // Sending bits
    MSComplete
} MasterState /*verilator public*/; 

typedef enum logic [2:0] {
    SLIdle,           // Waiting to transmit
    SLBegin,
    SLTransmitting,   // Sending bits
    SLComplete
} SlaveState /*verilator public*/; 
