function gain = hypergeom_gain(theta)
%HYPERGEOM_GAIN Floating-point table from SpeexDSP preprocess.c.
table = [0.82157 1.02017 1.20461 1.37534 1.53363 1.68092 ...
    1.81865 1.94811 2.07038 2.18638 2.29688 2.40255 2.50391 ...
    2.60144 2.69551 2.78647 2.87458 2.96015 3.04333 3.12431 3.20326]';
x = max(theta,0);
idx = floor(2*x);
gain = zeros(size(x));
low = idx < 20;
f = 2*x(low)-idx(low);
left = idx(low)+1;
gain(low) = ((1-f).*table(left)+f.*table(left+1))./sqrt(x(low)+0.0001);
gain(~low) = 1+0.1296./max(x(~low),eps);
gain(~isfinite(gain)) = 1;
end
