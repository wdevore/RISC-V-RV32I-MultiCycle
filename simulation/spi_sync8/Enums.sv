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
    SLIdle,           // Waiting to transmit
    SLTransmit,   // Sending bits
    SLShift,
    SLLoad,
    SLLoad2,
    SLCSLoad,
    SLCSLoad2
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
