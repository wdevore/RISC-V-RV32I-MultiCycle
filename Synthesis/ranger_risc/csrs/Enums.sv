
typedef enum logic [4:0] {
    // -------------------------------
    // TOP reset sequence
    // -------------------------------
    CSReset,
    CSReset1,
    CSResetComplete,

    // -------------------------------
    // CPU reset sequence
    // -------------------------------
    CSCPUResetAssert,
    CSCPUResetDeassert,
    CSResetAssertToggle,

    // -------------------------------
    // Status sequence
    // -------------------------------
    CSStatusRequest,
    CSStatusSend,
    CSStatusSending,

    // -------------------------------
    // CPU rising/falling sequence
    // -------------------------------
    CSCPUClockRise,
    CSCPUClockFall,
    CSCPUClockToggle,

    CSClockControlMan,
    CSClockControlRun,
    CSClockControlPll,

    // -------------------------------
    // UART Tx sequence
    // -------------------------------
    CSIdle,
    CSSend,
    CSSending
} ControlState; 

// -------------------------------------------------------------------
// UART
// -------------------------------------------------------------------
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
