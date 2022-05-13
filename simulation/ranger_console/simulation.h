#pragma once
#include <verilated.h>

#include "model.h"
#include "console_module.h"

class Simulation
{
private:
    

public:
    Simulation();
    ~Simulation();

    int init(void);

    void begin(Model &mdl);
    void update(Model &mdl);
    void end(Model &mdl);

    void begin_reset(Model &mdl);
    void update_reset(Model &mdl, TESTBENCH<VRangerRisc> *tb);
    void end_reset(Model &mdl);

    void run_to_fetch(Model &mdl, TESTBENCH<VRangerRisc> *tb);
    void run_to_decode(Model &mdl, TESTBENCH<VRangerRisc> *tb);
    void run_to_execute(Model &mdl, TESTBENCH<VRangerRisc> *tb);
};
