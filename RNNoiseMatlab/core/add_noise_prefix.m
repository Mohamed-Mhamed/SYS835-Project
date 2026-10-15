function [cleanOut, noisyOut, noiseOut, prefixLength] = add_noise_prefix(clean, noisy, noise, seconds, fs)
prefixLength = round(seconds * fs);
if prefixLength <= 0
    cleanOut = clean(:);
    noisyOut = noisy(:);
    noiseOut = noise(:);
    return;
end
prefix = noise(1:min(prefixLength, length(noise)));
prefix = repmat(prefix, ceil(prefixLength / length(prefix)), 1);
prefix = prefix(1:prefixLength);
cleanOut = [zeros(prefixLength, 1); clean(:)];
noisyOut = [prefix; noisy(:)];
noiseOut = [prefix; noise(:)];
end
