% MAIN_RNNOISE_MATLAB Reproducible RNNoise experiment.
clear;
clc;
close all;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'core'));
config = default_config();
projectFolder = fileparts(fileparts(mfilename('fullpath')));
dataFolder = fullfile(projectFolder, 'data');
generated = fullfile(projectFolder, 'generated');
if isempty(config.RNNoiseExecutable)
    config.RNNoiseExecutable = fullfile(projectFolder, 'rnnoise', ...
        'examples', 'rnnoise_demo');
end
if ~isfile(config.RNNoiseExecutable)
    error('RNNoise executable not found: %s', config.RNNoiseExecutable);
end

clean = load_sigd(fullfile(dataFolder, 'Signal', config.CleanFile));
noise = load_sigd(fullfile(dataFolder, 'Bruit', config.NoiseFile));
[noisy, scaledNoise, mixInfo] = create_noisy_signal(clean, noise, ...
    config.TargetSNRdB);
prefixLength = 0;
if config.AddNoiseOnlyPrefix
    [clean, noisy, scaledNoise, prefixLength] = add_noise_prefix( ...
        clean, noisy, scaledNoise, config.NoiseOnlyPrefixSeconds, ...
        config.FsInput);
end
[fir, firInfo] = design_fir_resampler(config.FirTaps);
firValidation = validate_fir_resampler(clean, fir);
clean48 = resample_fir_8k_to_48k(clean, fir);
noisy48 = resample_fir_8k_to_48k(noisy, fir);
noise48 = resample_fir_8k_to_48k(scaledNoise, fir);
common = min([length(clean48), length(noisy48), length(noise48)]);
clean48 = clean48(1:common);
noisy48 = noisy48(1:common);
noise48 = noise48(1:common);
commonPeak = max(abs(noisy48));
if commonPeak <= 0
    error('The prepared noisy signal is silent.');
end
commonScale = min(1, 0.99 / commonPeak);
clean48 = commonScale * clean48;
noisy48 = commonScale * noisy48;
noise48 = commonScale * noise48;
[noisy48, padding] = prepare_frames(noisy48, config.FrameSize);
clean48 = [clean48; zeros(padding, 1)];
noise48 = [noise48; zeros(padding, 1)];
inputPcm = fullfile(generated, 'pcm', 'noisy_input_48k.pcm');
outputPcm = fullfile(generated, 'pcm', 'denoised_output_48k.pcm');
write_pcm16(inputPcm, noisy48);
runtime = run_rnnoise_reference(inputPcm, outputPcm, ...
    config.RNNoiseExecutable);
enhanced48 = read_pcm16(outputPcm);
[cleanRef, enhanced, delay] = align_output(clean48, enhanced48, ...
    2 * config.FrameSize);
noisyRef = noisy48(1:length(cleanRef));
noiseRef = noise48(1:length(cleanRef));
metrics = calculate_metrics(cleanRef, noisyRef, enhanced);
metrics.SourceSNRdB = mixInfo.MeasuredSNRdB;
metrics.NoisePrefixSamples = prefixLength;
metrics.PaddingSamples = padding;
fprintf('Source SNR: %.3f dB\n', mixInfo.MeasuredSNRdB);
fprintf('Estimated delay: %d samples\n', delay);
fprintf('Input SNR: %.3f dB\n', metrics.InputSNRdB);
fprintf('Output SNR: %.3f dB\n', metrics.OutputSNRdB);
fprintf('Improvement: %.3f dB\n', metrics.ImprovementdB);

% Export fixed-size vectors for later host C and CCS comparison.
frameCount = floor(length(noisy48) / config.FrameSize);
inputFrames = reshape(single(noisy48(1:frameCount*config.FrameSize)), ...
    config.FrameSize, frameCount);
cleanFrames = reshape(single(clean48(1:frameCount*config.FrameSize)), ...
    config.FrameSize, frameCount);
enhancedFrames = reshape(single(enhanced48(1:min(end, ...
    frameCount*config.FrameSize))), config.FrameSize, []);
save(fullfile(generated, 'results', 'rnnoise_results.mat'), ...
    'config', 'firInfo', 'fir', 'firValidation', 'mixInfo', 'runtime', 'metrics', ...
    'delay', 'inputFrames', 'cleanFrames', 'enhancedFrames');
save(fullfile(generated, 'ccs_vectors', 'rnnoise_vectors.mat'), ...
    'inputFrames', 'cleanFrames', 'enhancedFrames', 'config', 'fir');
save(fullfile(generated, 'ccs_vectors', 'fir_coefficients.mat'), ...
    'fir', 'firInfo');
write_float32(fullfile(generated, 'ccs_vectors', ...
    'input_frames_480_float32.dat'), inputFrames);
write_float32(fullfile(generated, 'ccs_vectors', ...
    'clean_frames_480_float32.dat'), cleanFrames);
write_float32(fullfile(generated, 'ccs_vectors', ...
    'enhanced_frames_480_float32.dat'), enhancedFrames);
plot_results(cleanRef, noiseRef, noisyRef, enhanced, config.FsRNNoise, ...
    fullfile(generated, 'figures'), config.ShowPlots);
if config.PlayAudio
    play_audio_signal(cleanRef, config.FsRNNoise, 'original speech');
    play_audio_signal(noiseRef, config.FsRNNoise, 'noise');
    play_audio_signal(noisyRef, config.FsRNNoise, 'noisy speech');
    play_audio_signal(enhanced, config.FsRNNoise, 'RNNoise enhanced speech');
end
