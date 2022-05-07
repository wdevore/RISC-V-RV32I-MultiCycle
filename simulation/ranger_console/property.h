#pragma once

template <typename T>
class Property
{
private:
    T _value;
    T _p_value;
    bool _changed = true;

public:
    Property<T>(/* args */) {}
    ~Property<T>() {}

    bool changed(void)
    {
        bool chg = _changed;
        _changed = false;
        return chg;
    }

    void set(T val)
    {
        _changed = _p_value != val;
        _p_value = _value;
        _value = val;
    }

    T value() { return _value; }
};
