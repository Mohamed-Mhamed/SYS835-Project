function [y,d,state] = process_signal(x,c)
%PROCESS_SIGNAL SpeexDSP-style denoiser with its 24-band gain path.
% State and update order follow preprocess.c. The filterbank equations follow
% the cloned libspeexdsp/filterbank.c implementation.
x = double(x(:));
N = c.FFTSize;
M = c.NumBands;
bins = N;
frameCount = ceil(length(x) / c.HopSize);
outputLength = frameCount * c.HopSize;
input = zeros(outputLength + c.FrameSize, 1);
input(1:length(x)) = x;
if c.UseSourceWindow
    window = speex_source_window(2*N, c.FrameSize);
else
    window = sqrt(hann(c.AnalysisSize, 'periodic'));
end
y = zeros(outputLength, 1);
windowPower = zeros(outputLength, 1);
bank = design_filterbank(c);

state.S = zeros(bins, 1);
state.Smin = zeros(bins, 1);
state.Stmp = zeros(bins, 1);
state.Noise = eps * ones(bins, 1);
state.OldPower = zeros(bins, 1);
state.Prior = ones(bins, 1);
state.Post = zeros(bins, 1);
state.Zeta = zeros(bins, 1);
state.Gain = ones(bins, 1);
state.GainFloor = exp(0.2302585 * c.NoiseSuppressDb) * ones(bins, 1);
state.UpdateProb = ones(bins, 1);
state.FrameIndex = 0;
state.MinCount = 0;
state.NbAdapt = 0;

d.Gain = zeros(bins, frameCount);
d.Gain2 = zeros(bins, frameCount);
d.Noise = zeros(bins, frameCount);
d.Presence = zeros(1, frameCount);
d.APosterioriSNR = zeros(bins, frameCount);
d.APrioriSNR = zeros(bins, frameCount);
d.BandPresence = zeros(M, frameCount);

for frame = 1:frameCount
    first = (frame - 1) * c.HopSize + 1;
    last = first + c.AnalysisSize - 1;
    analysis = input(first:last) .* window;
    if c.UsePortableFFT
        packed = speex_kiss_fft_forward(analysis, 2*N);
        positive = zeros(N, 1);
        positive(1) = packed(1);
        for k = 1:N-1
            positive(k+1) = packed(2*k) + 1i * packed(2*k+1);
        end
    else
        spectrum = fft(analysis, 2*N);
        positive = spectrum(1:N);
    end
    power = abs(positive).^2;
    state.FrameIndex = state.FrameIndex + 1;
    state.MinCount = state.MinCount + 1;
    state.NbAdapt = min(state.NbAdapt + 1, 20000);

    state.S = 0.8 * state.S;
    state.S(1) = state.S(1) + 0.2 * power(1);
    state.S(end) = state.S(end) + 0.2 * power(end);
    state.S(2:end-1) = state.S(2:end-1) + ...
        0.05 * power(1:end-2) + 0.10 * power(2:end-1) + ...
        0.05 * power(3:end);
    if state.FrameIndex == 1
        state.Smin(:) = 0;
        state.Stmp(:) = 0;
    end
    if state.MinCount > 15
        state.Smin = min(state.Stmp, state.S);
        state.Stmp = state.S;
        state.MinCount = 0;
    else
        state.Smin = min(state.Smin, state.S);
        state.Stmp = min(state.Stmp, state.S);
    end
    state.UpdateProb = double(0.4 * state.S > state.Smin);

    beta = max(0.03, 1 / state.NbAdapt);
    if state.FrameIndex <= c.InitialNoiseFrames
        state.Noise = ((state.FrameIndex - 1) * state.Noise + power) / ...
            state.FrameIndex;
    else
        updateMask = state.UpdateProb < 0.5 | power < state.Noise;
        state.Noise(updateMask) = (1 - beta) * state.Noise(updateMask) + ...
            beta * power(updateMask);
    end
    totalNoise = max(state.Noise, eps);
    gamma = min(power ./ totalNoise, 100);
    state.Post = gamma - 1;
    if state.FrameIndex == 1
        state.OldPower = power;
    end
    updateGamma = 0.1 + 0.89 * ...
        (state.OldPower ./ max(state.OldPower + totalNoise, eps)).^2;
    state.Prior = updateGamma .* max(state.Post, 0) + ...
        (1 - updateGamma) .* state.OldPower ./ max(totalNoise, eps);
    state.Prior = min(max(state.Prior, 0), 100);

    state.Zeta = 0.7 * state.Zeta + 0.3 * state.Prior;
    state.Zeta(2:end-1) = 0.7 * state.Zeta(2:end-1) + ...
        0.15 * state.Prior(2:end-1) + ...
        0.075 * state.Prior(1:end-2) + 0.075 * state.Prior(3:end);
    bandZeta = filterbank_forward(bank, state.Zeta);
    qCurve = 1 ./ (1 + 0.15 ./ max(bandZeta, eps));
    framePresence = min(max(0.1 + 0.899 * mean(qCurve), 0.1), 1);

    bandPrior = filterbank_forward(bank, state.Prior);
    bandPost = filterbank_forward(bank, state.Post);
    bandPriorRatio = bandPrior ./ (1 + bandPrior);
    bandTheta = max(bandPriorRatio .* (1 + bandPost), 0);
    bandMMSE = speex_hypergeom_gain(bandTheta);
    bandGain = min(bandPriorRatio .* bandMMSE, 1);
    bandGainFloor = exp(0.2302585 * c.NoiseSuppressDb) * ones(M, 1);
    bandP = min(max(0.199 + 0.8 * qCurve, 0), 1);
    bandQ = min(max(1 - framePresence .* bandP, 0), 1 - eps);
    bandGain2 = 1 ./ (1 + (bandQ ./ max(1 - bandQ, eps)) .* ...
        (1 + bandPrior) .* exp(-bandTheta));
    interpolatedGain2 = filterbank_inverse(bank, bandGain2);
    interpolatedBandGain = filterbank_inverse(bank, bandGain);

    sourceGain = speex_source_gain(gamma, state.Prior, c);
    sourceGain = min(sourceGain, 3 * interpolatedBandGain);
    sourceGain = max(sourceGain, c.GainFloor);
    state.Gain = (interpolatedGain2 .* sqrt(sourceGain) + ...
        (1 - interpolatedGain2) .* sqrt(state.GainFloor)).^2;
    state.OldPower = 0.2 * state.OldPower + ...
        0.8 * (state.Gain.^2) .* power;
    state.Gain = min(max(state.Gain, c.GainFloor), 1);

    if c.UsePortableFFT
        packedGain = packed;
        packedGain(1) = state.Gain(1) * packed(1);
        for k = 1:N-1
            packedGain(2*k) = state.Gain(k+1) * packed(2*k);
            packedGain(2*k+1) = state.Gain(k+1) * packed(2*k+1);
        end
        packedGain(2*N) = state.Gain(N) * packed(2*N);
        frameOutput = speex_kiss_fft_inverse(packedGain, 2*N);
    else
        fullGain = [state.Gain; state.Gain(end:-1:1)];
        frameOutput = real(ifft(fullGain .* spectrum, 2*N));
    end
    frameOutput = frameOutput(1:c.AnalysisSize) .* window;
    endIndex = min(last, length(y));
    valid = first:endIndex;
    y(valid) = y(valid) + frameOutput(1:length(valid));
    windowPower(valid) = windowPower(valid) + window(1:length(valid)).^2;

    d.Gain(:, frame) = state.Gain;
    d.Gain2(:, frame) = interpolatedGain2;
    d.Noise(:, frame) = state.Noise;
    d.Presence(frame) = framePresence;
    d.BandPresence(:, frame) = bandP;
    d.APosterioriSNR(:, frame) = gamma;
    d.APrioriSNR(:, frame) = state.Prior;
end
y = y ./ max(windowPower, eps);
y = y(1:length(x));
end
