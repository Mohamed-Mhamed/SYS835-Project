function [coefficients, design] = design_fir_resampler(tapCount)
%DESIGN_FIR_RESAMPLER 8 kHz to 48 kHz interpolation filter.
% Coefficients are organized as six output phases and are C-portable.
if mod(tapCount, 2) == 0 || tapCount < 3
    error('tapCount must be an odd integer greater than two.');
end
L = 6;
center = floor(tapCount / 2);
coefficients = zeros(L, tapCount);
for phase = 0:L-1
    for tap = 0:tapCount-1
        t = tap - center - phase / L;
        if abs(t) < eps
            value = 1;
        else
            value = sin(pi * t) / (pi * t);
        end
        window = 0.54 - 0.46 * cos(2 * pi * tap / (tapCount - 1));
        coefficients(phase + 1, tap + 1) = value * window;
    end
    coefficients(phase + 1, :) = coefficients(phase + 1, :) / ...
        sum(coefficients(phase + 1, :));
end
design.InputRate = 8000;
design.OutputRate = 48000;
design.InterpolationFactor = L;
design.TapCount = tapCount;
design.CutoffInputCycles = 0.5;
design.Description = 'Windowed-sinc six-phase interpolation FIR';
end
