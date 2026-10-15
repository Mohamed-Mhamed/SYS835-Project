function results = main_portable_reference_mode(cleanFile, noiseFile, showPlots, playAudio)
%MAIN_PORTABLE_REFERENCE_MODE Run the CCS-oriented MATLAB reference path.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'reference_mode', 'core'));

c = portable_config();
if nargin < 1 || isempty(cleanFile)
    cleanFile = c.CleanFile;
end
if nargin < 2 || isempty(noiseFile)
    noiseFile = c.NoiseFile;
end
if nargin >= 3
    c.ShowPlots = showPlots;
end
if nargin >= 4
    c.PlayAudio = playAudio;
end

cleanSpeech = load_sigd(fullfile(root, 'data', 'Signal', cleanFile));
noiseBase = load_sigd(fullfile(root, 'data', 'Bruit', noiseFile));
prefix = c.InitialNoiseFrames * c.HopSize + c.AnalysisSize;
noise = repmat(noiseBase, ceil((length(cleanSpeech) + prefix) / length(noiseBase)), 1);
noise = noise(1:length(cleanSpeech) + prefix);
noise = noise - mean(noise);
noise = noise * sqrt(sum(cleanSpeech.^2) / ...
    (10^(c.TargetSNRdB / 10) * sum(noise(prefix + 1:end).^2)));

clean = [zeros(prefix, 1); cleanSpeech];
noisy = clean + noise;
[enhanced, diagnostics, state] = process_signal(noisy, c);
idx = prefix + 1:length(enhanced);
inputError = noisy(idx) - clean(idx);
outputError = enhanced(idx) - clean(idx);

results.Config = c;
results.Clean = clean;
results.Noise = noise;
results.Noisy = noisy;
results.Enhanced = enhanced;
results.Diagnostics = diagnostics;
results.State = state;
results.Metrics.InputSNRdB = 10 * log10(sum(clean(idx).^2) / sum(inputError.^2));
results.Metrics.OutputSNRdB = 10 * log10(sum(clean(idx).^2) / sum(outputError.^2));
results.Metrics.ImprovementdB = results.Metrics.OutputSNRdB - ...
    results.Metrics.InputSNRdB;

outputFolder = fullfile(root, 'generated');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
save(fullfile(outputFolder, 'portable_reference_mode_results.mat'), '-struct', 'results');
fprintf('Portable reference mode: input %.3f dB, output %.3f dB, improvement %.3f dB\n', ...
    results.Metrics.InputSNRdB, results.Metrics.OutputSNRdB, ...
    results.Metrics.ImprovementdB);

if c.ShowPlots
    figure('Name', 'Portable SpeexDSP reference waveforms');
    subplot(3, 1, 1); plot(clean); title('Clean');
    subplot(3, 1, 2); plot(noisy); title('Noisy');
    subplot(3, 1, 3); plot(enhanced); title('Denoised');
end
if c.ShowPlots || c.PlayAudio
    plot_and_listen(clean, noise, noisy, enhanced, c.Fs, c.PlayAudio);
end
end
