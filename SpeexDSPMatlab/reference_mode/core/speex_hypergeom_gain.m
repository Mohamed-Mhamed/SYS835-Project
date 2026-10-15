function gain = speex_hypergeom_gain(theta)
%SPEEX_HYPERGEOM_GAIN Floating-point hypergeom_gain approximation.
% The table and asymptotic branch are copied numerically from the
% non-FIXED_POINT branch of SpeexDSP preprocess.c.
table = [0.82157 1.02017 1.20461 1.37534 1.53363 1.68092 ...
    1.81865 1.94811 2.07038 2.18638 2.29688 2.40255 2.50391 ...
    2.60144 2.69551 2.78647 2.87458 2.96015 3.04333 3.12431 3.20326];
table = table(:);
x = max(theta, 0);
index = floor(2 * x);
gain = zeros(size(x));
low = index < 20;
fraction = 2 * x(low) - index(low);
left = index(low) + 1;
right = left + 1;
fraction = fraction(:);
left = left(:);
right = right(:);
gain(low) = ((1 - fraction) .* table(left) + ...
    fraction .* table(right)) ./ sqrt(x(low) + 0.0001);
gain(~low) = 1 + 0.1296 ./ max(x(~low), eps);
gain(~isfinite(gain)) = 1;
end
