function x = packed_real_ifft(packed, backend)
%PACKED_REAL_IFFT Inverse of the SpeexDSP packed real-spectrum convention.
packed = packed(:);
n = length(packed);
if nargin < 2 || isempty(backend)
    backend = 'kiss_fft';
end
if ~strcmp(backend,'kiss_fft') && ~strcmp(backend,'smallft')
    error('packed_real_ifft:Backend','Unsupported backend: %s',backend);
end
x = zeros(n,1);
for t = 0:n-1
    value = packed(1) + packed(n)*cos(pi*t);
    for k = 1:n/2-1
        a = 2*pi*k*t/n;
        value = value + 2*(packed(2*k)*cos(a)-packed(2*k+1)*sin(a));
    end
    x(t+1) = value;
end
end
