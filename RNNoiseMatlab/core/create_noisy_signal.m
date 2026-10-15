function [noisy, scaledNoise, info] = create_noisy_signal(clean, noise, targetSNRdB)
clean = double(clean(:));
noise = double(noise(:));
noise = noise - mean(noise);
noise = repmat(noise, ceil(length(clean) / length(noise)), 1);
noise = noise(1:length(clean));
cleanEnergy = sum(clean.^2);
noiseEnergy = sum(noise.^2);
if cleanEnergy <= 0 || noiseEnergy <= 0
    error('Clean and noise signals must have positive energy.');
end
scale = sqrt(cleanEnergy / (10^(targetSNRdB / 10) * noiseEnergy));
scaledNoise = scale * noise;
noisy = clean + scaledNoise;
info.TargetSNRdB = targetSNRdB;
info.MeasuredSNRdB = 10 * log10(cleanEnergy / max(sum(scaledNoise.^2), eps));
info.NoiseScale = scale;
end
