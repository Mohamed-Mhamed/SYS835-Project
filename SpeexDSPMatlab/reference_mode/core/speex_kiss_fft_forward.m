function packed = speex_kiss_fft_forward(frame, fftLength)
%SPEEX_KISS_FFT_FORWARD Floating-point Kiss FFT real packing used by SpeexDSP.
% The result is the source's packed layout:
% [DC, Re(X1), Im(X1), ..., Re(X(N/2-1)), Im(X(N/2-1)), Nyquist].
% The floating-point SpeexDSP wrapper applies 1/fftLength scaling.
frame = frame(:);
if length(frame) ~= fftLength
    error('speex_kiss_fft_forward:Length', 'Frame length must equal fftLength.');
end
packed = zeros(fftLength, 1);
half = fftLength / 2;
for k = 0:half
    realPart = 0;
    imagPart = 0;
    for n = 0:fftLength-1
        angle = 2*pi*k*n/fftLength;
        realPart = realPart + frame(n+1) * cos(angle);
        imagPart = imagPart - frame(n+1) * sin(angle);
    end
    realPart = realPart / fftLength;
    imagPart = imagPart / fftLength;
    if k == 0
        packed(1) = realPart;
    elseif k == half
        packed(fftLength) = realPart;
    else
        packed(2*k) = realPart;
        packed(2*k+1) = imagPart;
    end
end
end
