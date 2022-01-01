template <class MODULE>
class TESTBENCH
{
private:
    vluint64_t tickcount;
    MODULE *_core;
    VerilatedVcdC *m_trace;

public:
    TESTBENCH(void)
    {
        _core = new MODULE;
        tickcount = 0l;
    }

    virtual ~TESTBENCH(void)
    {
        delete _core;
        _core = NULL;
    }

    virtual void setup(void)
    {
        std::cout << "Setting up" << std::endl;
        Verilated::traceEverOn(true);
        m_trace = new VerilatedVcdC;
        _core->trace(m_trace, 5);
        m_trace->open("/media/RAMDisk/waveform.vcd");
    }

    virtual void shutdown(void)
    {
        std::cout << "Shutting down" << std::endl;
        _core->final(); // simulation done
        m_trace->close();
    }

    virtual MODULE *core(void)
    {
        return _core;
    }

    virtual void tick(void)
    {
        // Increment our own internal time reference
        tickcount++;
    }

    virtual void sample(void)
    {
        _core->eval();
        m_trace->dump(tickcount);
    }

    virtual void sampletick(void)
    {
        sample();
        tick();
    }

    virtual void show(void)
    {
        std::cout << "Time (" << tickcount << ") " << std::endl;
    }

    virtual bool done(void) { return (Verilated::gotFinish()); }
};