// Either MODE0 or MODE1
`define MODE0

typedef enum logic [2:0] {
    Reset,          // Unused
    Idle,           // Waiting to transmit
    BeginTx,        // Unused
    Transmitting,   // Sending bits
    Complete        // Unused
} TxState /*verilator public*/; 
