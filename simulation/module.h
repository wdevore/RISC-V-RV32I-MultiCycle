template <class MODULE>
class TESTBENCH
{
private:
    vluint64_t tickcount;
    MODULE *_core;
    VerilatedVcdC *m_trace;
    const int picosecs = 10;

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
        _core->trace(m_trace, 99);
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

    virtual vluint64_t time(void)
    {
        return tickcount;
    }

    virtual int tick(void)
    {
        // Increment our own internal time reference
        return tickcount += picosecs;
    }

    virtual int moveBy(vluint64_t by) {
        return tickcount += by;
    }

    virtual void eval(void)
    {
        // Increment our own internal time reference
        _core->eval();
    }

    virtual void flush(void)
    {
        // Increment our own internal time reference
        m_trace->flush();
    }

    virtual void sample(void)
    {
        _core->eval();
        m_trace->dump(tickcount);
    }

    virtual void dump(int count)
    {
        m_trace->dump(count);
    }

    virtual void sampletick(void)
    {
        tick();
        sample();
    }

    virtual void show(void)
    {
        std::cout << "Time (" << tickcount << ") " << std::endl;
    }

    virtual bool done(void) { return (Verilated::gotFinish()); }
};