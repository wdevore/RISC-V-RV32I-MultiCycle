
typedef enum logic [2:0] {
    Reset,
    Idle,           // Waiting to transmit
    BeginTx,        // Prepare to transmit
    Transmitting,   // Sending bits
    Complete        // Bits sent
} TxState /*verilator public*/; 
