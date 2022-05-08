#pragma once

template <typename T>
class Property
{
private:
    T _value;
    T _p_value;
    bool _changed = true;
    int _when = 0;

public:
    Property<T>(/* args */) {}
    ~Property<T>() {}

    bool changed(void)
    {
        bool chg = _changed;
        _changed = false;
        return chg;
    }

    void set(T val, int when)
    {
        _changed = _p_value != val;
        if (_changed)
            _when = when;
        _p_value = _value;
        _value = val;
    }

    T value() { return _value; }

    int when() { return _when; }
};
