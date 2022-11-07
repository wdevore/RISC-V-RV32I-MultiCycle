
typedef enum logic [2:0] {
    TxReset,
    TxIdle,         // Waiting to transmit
    TxStartBit,
    TxSending,      // Transmitting
    TxStopBit
} TxState; 

typedef enum logic [2:0] {
    RxReset,
    RxIdle,
    RxHalfBit,
    RxStartBit,
    RxReceiving,
    RxStopBit
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

