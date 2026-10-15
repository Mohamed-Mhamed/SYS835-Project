function bank = design_bank(c)
%DESIGN_BANK 24-band Bark mapping based on SpeexDSP filterbank.c.
N = c.FFTSize;
f = (0:N-1)'*c.Fs/(2*N);
b = 13.1*atan(0.00074*f)+2.24*atan(1.85e-8*f.^2)+1e-4*f;
maxB = 13.1*atan(0.00074*c.Fs/2)+ ...
    2.24*atan(1.85e-8*(c.Fs/2)^2)+1e-4*c.Fs/2;
step = maxB/(c.NumBands-1);
left = floor(b/step);
frac = (b-left*step)/step;
left(left >= c.NumBands-1) = c.NumBands-2;
frac(b >= maxB) = 1;
bank.Left = left+1;
bank.Right = left+2;
bank.LeftWeight = 1-frac;
bank.RightWeight = frac;
bank.NumBins = N;
bank.NumBands = c.NumBands;
end
