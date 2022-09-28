// Either MODE0 or MODE1
`define MODE0

typedef enum logic [2:0] {
    // MSReset,   // Uncomment for Comb version
    MSIdle,           // Waiting to transmit
    MSStart,
    MSBegin,
    MSTransmitting,   // Sending bits
    MSComplete
} MasterState /*verilator public*/; 

typedef enum logic [2:0] {
    // SLReset,
    SLIdle,           // Waiting to transmit
    SLBegin,
    SLTransmit,   // Sending bits
    SLShift
} SlaveState /*verilator public*/; 

typedef enum logic [2:0] {
    IOBoot,
    IOReset,
    IOIdle,           // Waiting to transmit
    IOBegin,
    IOSend,
    IONext,       // Sending bytes
    IOComplete
} IOState /*verilator public*/; 

typedef enum logic [2:0] {
    SMBoot,
    SMReset,
    SMIdle,
    SMBeginWrite,
    SMWrite,
    SMSend,
    SMComplete
} SimState /*verilator public*/; 
