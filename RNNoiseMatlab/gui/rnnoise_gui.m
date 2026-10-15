function rnnoise_gui()
%RNNOISE_GUI Thin GUI around the shared RNNoise core.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'core'));
config = default_config();
fig = uifigure('Name', 'RNNoise MATLAB', 'Position', [100 100 520 420]);
uilabel(fig, 'Position', [25 370 120 22], 'Text', 'Clean MAT file');
cleanField = uieditfield(fig, 'text', 'Position', [150 370 330 22], ...
    'Value', config.CleanFile);
uilabel(fig, 'Position', [25 330 120 22], 'Text', 'Noise MAT file');
noiseField = uieditfield(fig, 'text', 'Position', [150 330 330 22], ...
    'Value', config.NoiseFile);
uilabel(fig, 'Position', [25 290 120 22], 'Text', 'Target SNR (dB)');
snrField = uieditfield(fig, 'numeric', 'Position', [150 290 100 22], ...
    'Value', config.TargetSNRdB);
prefixBox = uicheckbox(fig, 'Position', [25 250 300 22], ...
    'Text', 'Add 0.25 s noise-only prefix', 'Value', true);
status = uitextarea(fig, 'Position', [25 25 455 115], 'Editable', 'off');
uibutton(fig, 'Position', [25 205 140 28], 'Text', 'Run experiment', ...
    'ButtonPushedFcn', @runExperiment);
uibutton(fig, 'Position', [180 205 140 28], 'Text', 'Play original', ...
    'ButtonPushedFcn', @playOriginal);
uibutton(fig, 'Position', [335 205 140 28], 'Text', 'Play noise', ...
    'ButtonPushedFcn', @playNoise);
uibutton(fig, 'Position', [25 165 140 28], 'Text', 'Play noisy', ...
    'ButtonPushedFcn', @playNoisy);
uibutton(fig, 'Position', [180 165 140 28], 'Text', 'Play enhanced', ...
    'ButtonPushedFcn', @playEnhanced);
lastEnhanced = [];
lastClean = [];
lastNoise = [];
lastNoisy = [];
function runExperiment(~, ~)
    try
        cfg = default_config();
        cfg.CleanFile = cleanField.Value;
        cfg.NoiseFile = noiseField.Value;
        cfg.TargetSNRdB = snrField.Value;
        cfg.AddNoiseOnlyPrefix = prefixBox.Value;
        cfg.ShowPlots = true;
        projectFolder = root;
        dataFolder = fullfile(projectFolder, 'data');
        generated = fullfile(projectFolder, 'generated');
        executable = fullfile(projectFolder, 'rnnoise', 'examples', ...
            'rnnoise_demo');
        clean = load_sigd(fullfile(dataFolder, 'Signal', cfg.CleanFile));
        noise = load_sigd(fullfile(dataFolder, 'Bruit', cfg.NoiseFile));
        [noisy, scaledNoise] = create_noisy_signal(clean, noise, cfg.TargetSNRdB);
        if cfg.AddNoiseOnlyPrefix
            [clean, noisy, scaledNoise] = add_noise_prefix(clean, noisy, ...
                scaledNoise, cfg.NoiseOnlyPrefixSeconds, cfg.FsInput);
        end
        [fir, ~] = design_fir_resampler(cfg.FirTaps);
        clean48 = resample_fir_8k_to_48k(clean, fir);
        noisy48 = resample_fir_8k_to_48k(noisy, fir);
        noise48 = resample_fir_8k_to_48k(scaledNoise, fir);
        n = min([length(clean48), length(noisy48), length(noise48)]);
        clean48 = clean48(1:n); noisy48 = noisy48(1:n); noise48 = noise48(1:n);
        commonPeak = max(abs(noisy48));
        if commonPeak <= 0
            error('The prepared noisy signal is silent.');
        end
        commonScale = min(1, 0.99 / commonPeak);
        clean48 = commonScale * clean48;
        noisy48 = commonScale * noisy48;
        noise48 = commonScale * noise48;
        [noisy48, pad] = prepare_frames(noisy48, cfg.FrameSize);
        clean48 = [clean48; zeros(pad,1)]; noise48 = [noise48; zeros(pad,1)];
        inputPcm = fullfile(generated, 'pcm', 'gui_noisy_input.pcm');
        outputPcm = fullfile(generated, 'pcm', 'gui_denoised_output.pcm');
        write_pcm16(inputPcm, noisy48);
        run_rnnoise_reference(inputPcm, outputPcm, executable);
        enhanced48 = read_pcm16(outputPcm);
        [cleanRef, lastEnhanced, delay] = align_output(clean48, enhanced48, 960);
        noisyRef = noisy48(1:length(cleanRef));
        metrics = calculate_metrics(cleanRef, noisyRef, lastEnhanced);
        lastClean = cleanRef;
        lastNoise = noise48(1:length(cleanRef));
        lastNoisy = noisyRef;
        plot_results(cleanRef, noise48(1:length(cleanRef)), noisyRef, ...
            lastEnhanced, cfg.FsRNNoise, fullfile(generated, 'figures'), true);
        status.Value = sprintf('Delay: %d samples\nInput SNR: %.3f dB\nOutput SNR: %.3f dB\nImprovement: %.3f dB', ...
            delay, metrics.InputSNRdB, metrics.OutputSNRdB, metrics.ImprovementdB);
    catch exception
        status.Value = getReport(exception, 'basic');
    end
end
    function playOriginal(~, ~)
    playStored(lastClean, 'original speech');
    end
    function playNoise(~, ~)
    playStored(lastNoise, 'noise');
    end
    function playNoisy(~, ~)
    playStored(lastNoisy, 'noisy speech');
    end
    function playEnhanced(~, ~)
    playStored(lastEnhanced, 'RNNoise enhanced speech');
    end
    function playStored(signal, labelText)
    if isempty(signal)
        status.Value = 'Run the experiment first.';
        return;
    end
    try
        play_audio_signal(signal, config.FsRNNoise, labelText);
    catch exception
        status.Value = getReport(exception, 'basic');
    end
    end
    end
