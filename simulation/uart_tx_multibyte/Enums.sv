
typedef enum logic [2:0] {
    TxReset,
    TxIdle,         // Waiting to transmit
    TxStartBit,
    TxSending,      // Transmitting
    TxStopBit,
    TxDelayReset
} TxState /*verilator public*/; 

// ----------- Simulation only ----------------------
typedef enum logic [2:0] {
    SMReset,
    SMResetComplete,
    SMIdle,         // Waiting to transmit
    SMSend,         // Transmitting
    SMSending,
    SMStop,
    SMDelayReset
} SimState /*verilator public*/; 

