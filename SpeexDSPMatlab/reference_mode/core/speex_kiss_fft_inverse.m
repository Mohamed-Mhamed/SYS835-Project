function frame = speex_kiss_fft_inverse(packed, fftLength)
%SPEEX_KISS_FFT_INVERSE Inverse of the floating-point SpeexDSP packing.
packed = packed(:);
if length(packed) ~= fftLength
    error('speex_kiss_fft_inverse:Length', 'Packed length must equal fftLength.');
end
half = fftLength / 2;
frame = zeros(fftLength, 1);
for n = 0:fftLength-1
    value = packed(1) + packed(fftLength) * cos(pi*n);
    for k = 1:half-1
        realPart = packed(2*k);
        imagPart = packed(2*k+1);
        angle = 2*pi*k*n/fftLength;
        value = value + 2 * (realPart*cos(angle) - imagPart*sin(angle));
    end
    frame(n+1) = value;
end
end
