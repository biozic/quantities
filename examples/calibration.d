module calibration;

import quantities;
import std.math;
import std.stdio;

struct LinearCalibration(Quantity, Signal)
{
    static assert(isQuantity!Quantity && isQuantity!Signal);

    Signal intercept;
    Quotient!(Signal, Quantity) slope;

    void calibrate2Points(Quantity q1, Signal s1, Quantity q2, Signal s2)
    {
        slope = (s2 - s1)/(q2 - q1);
        intercept = s1 - slope * q1;
    }

    Signal signalFor(Quantity quantity)
    {
        return intercept + slope * quantity;
    }

    Quantity quantityFor(Signal signal)
    {
        return (signal - intercept) / slope;
    }
}

unittest
{
    alias EPD = QuantityType!volt;
    alias Time = QuantityType!second;
    
    LinearCalibration!(Time, EPD) cal;
    cal.calibrate2Points(10 * minute, 15 * volt, 2 * hour, 91 * volt);
    
    auto unknown = cal.quantityFor(30 * volt);
    writefln("Time: %.2f min", unknown.value(minute));
}

unittest
{
    alias C = Concentration;
    alias A = Dimensionless;
    
    LinearCalibration!(C, A) cal;
    cal.calibrate2Points(si!"0 mmol/L", si!"0", si!"25 mmol/L", si!"0.507");
    
    auto unknown = cal.quantityFor(si!"0.113");
    writefln("Concentration: %.2f mmol/L", unknown.value(si!"mmol/L"));
}
