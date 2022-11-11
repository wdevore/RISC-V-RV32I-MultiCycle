
typedef enum logic [2:0] {
    TxReset,
    TxIdle,         // Waiting to transmit
    TxStartBit,
    TxSending,      // Transmitting
    TxStopBit,
    TxComplete
} TxState; 

typedef enum logic [2:0] {
    RxReset,
    RxIdle,
    RxHalfBit,
    RxStartBit,
    RxReceiving,
    RxStopBit,
    RxComplete
} RxState; 

// ----------- Simulation only ----------------------
typedef enum logic [2:0] {
    SMReset,
    SMResetComplete,
    SMIdle,         // Waiting to transmit
    SMSend,         // Transmitting
    SMSending,
    SMStop,
    SMDelayReset
} SimState; 

