
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

typedef enum logic [3:0] {
    CSReset,
    CSReset1,
    CSResetComplete,
    CSIdle,
    CSSend,
    CSSending,
    CSStop
} ControlState; 

