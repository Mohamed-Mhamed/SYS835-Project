function run_tests()
%RUN_TESTS Focused validation for the portable RNNoise preparation code.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'core'));
[coefficients, info] = design_fir_resampler(97);
assert(size(coefficients, 1) == 6 && size(coefficients, 2) == 97);
report = validate_fir_resampler(sin(2*pi*(0:1999)'/53), coefficients);
assert(~isempty(report.Status));
constant = ones(1000, 1);
resampled = resample_fir_8k_to_48k(constant, coefficients);
interior = resampled(289:5712);
assert(max(abs(interior - 1)) < 1e-8);
signal = sin(2*pi*(0:999)'/37);
[framed, padding] = prepare_frames(signal, 480);
assert(mod(length(framed), 480) == 0 && padding >= 0);
testPcm = fullfile(root, 'generated', 'pcm', 'test_pcm.pcm');
write_pcm16(testPcm, signal / max(abs(signal)));
decoded = read_pcm16(testPcm);
assert(length(decoded) == length(signal));
metrics = calculate_metrics(signal, signal, signal);
assert(isfinite(metrics.InputSNRdB) && metrics.ImprovementdB == 0);
assert(info.OutputRate == 48000);
fprintf('FIR validation: %s\n', report.Status);
if report.ReferenceAvailable
    fprintf(['FIR versus MATLAB resample: RMS %.6g (relative %.6g), ' ...
        'max %.6g, delay %d samples\n'], report.RMSError, ...
        report.RelativeRMSError, report.MaxError, report.DelaySamples);
end
fprintf('All RNNoiseMatlab tests passed.\n');
end
