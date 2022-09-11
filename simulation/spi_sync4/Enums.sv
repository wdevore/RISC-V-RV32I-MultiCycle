// Either MODE0 or MODE1
`define MODE0

typedef enum logic [2:0] {
    // MSReset,   // Uncomment for Comb version
    MSIdle,           // Waiting to transmit
    MSBegin,
    MSTransmitting,   // Sending bits
    MSComplete
} MasterState /*verilator public*/; 

typedef enum logic [2:0] {
    // SLReset,
    SLIdle,           // Waiting to transmit
    SLBegin,
    SLTransmitting,   // Sending bits
    SLComplete
} SlaveState /*verilator public*/; 

typedef enum logic [2:0] {
    IOIdle,           // Waiting to transmit
    IOBegin,
    IOTransmitting,   // Sending bits
    IOComplete
} IOState /*verilator public*/; 
