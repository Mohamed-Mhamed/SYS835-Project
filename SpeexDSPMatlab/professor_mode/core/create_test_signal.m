function [clean, noise, noisy, info] = create_test_signal(cleanIn, noiseIn, config)
cleanIn = cleanIn(:) - mean(cleanIn);
noiseIn = noiseIn(:) - mean(noiseIn);
prefix = config.InitialNoiseFrames * config.BlockSize;
noise = repmat(noiseIn, ceil((length(cleanIn)+prefix)/length(noiseIn)), 1);
noise = noise(1:length(cleanIn)+prefix);
clean = [zeros(prefix,1); cleanIn];
scale = sqrt(sum(cleanIn.^2)/(10^(config.TargetSNRdB/10)*sum(noise(prefix+1:end).^2)));
noise = scale * noise;
noisy = clean + noise;
info.PrefixSamples = prefix;
info.SpeechSNRdB = 10*log10(sum(cleanIn.^2)/max(sum(noise(prefix+1:end).^2),eps));
end
