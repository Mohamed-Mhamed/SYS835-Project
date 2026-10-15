function bank = design_filterbank(c)
%DESIGN_FILTERBANK Recreate SpeexDSP filterbank.c's linear Bark mapping.
% The formulas and triangular interpolation are from Xiph SpeexDSP
% libspeexdsp/filterbank.c (BSD-licensed source cloned in this project).
N = c.FFTSize;
frequency = (0:N-1)' * c.Fs / (2*N);
bark = 13.1 * atan(0.00074 * frequency) + ...
    2.24 * atan(1.85e-8 * frequency.^2) + 1e-4 * frequency;
maxBark = 13.1 * atan(0.00074 * (c.Fs/2)) + ...
    2.24 * atan(1.85e-8 * (c.Fs/2)^2) + 1e-4 * (c.Fs/2);
interval = maxBark / (c.NumBands - 1);
left = floor(bark / interval);
fraction = (bark - left * interval) / interval;
left(left >= c.NumBands - 1) = c.NumBands - 2;
fraction(bark >= maxBark) = 1;
fraction = min(max(fraction, 0), 1);
bank.Left = left + 1;
bank.Right = bank.Left + 1;
bank.LeftWeight = 1 - fraction;
bank.RightWeight = fraction;
bank.NumBands = c.NumBands;
bank.NumBins = N;
end
