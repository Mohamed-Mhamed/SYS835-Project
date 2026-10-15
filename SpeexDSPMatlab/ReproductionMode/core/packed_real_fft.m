function packed = packed_real_fft(x, backend)
%PACKED_REAL_FFT Packed real FFT reference for Kiss FFT and SmallFT modes.
x = x(:);
n = length(x);
if mod(n,2) ~= 0
    error('packed_real_fft:Length','FFT length must be even.');
end
% Both selected floating-point backends use this public packed layout.
% The backend label is retained in the API so an optimized implementation
% can replace this reference without changing the processing code.
if nargin < 2 || isempty(backend)
    backend = 'kiss_fft';
end
if ~strcmp(backend,'kiss_fft') && ~strcmp(backend,'smallft')
    error('packed_real_fft:Backend','Unsupported backend: %s',backend);
end
packed = zeros(n,1);
for k = 0:n/2
    re = 0;
    im = 0;
    for t = 0:n-1
        a = 2*pi*k*t/n;
        re = re + x(t+1)*cos(a);
        im = im - x(t+1)*sin(a);
    end
    re = re/n;
    im = im/n;
    if k == 0
        packed(1) = re;
    elseif k == n/2
        packed(n) = re;
    else
        packed(2*k) = re;
        packed(2*k+1) = im;
    end
end
end
