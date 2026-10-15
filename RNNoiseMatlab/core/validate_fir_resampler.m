function report = validate_fir_resampler(input, coefficients)
%VALIDATE_FIR_RESAMPLER Compare the local FIR with MATLAB resample when present.
input = double(input(:));
local = resample_fir_8k_to_48k(input, coefficients);
report = struct();
report.LocalLength = length(local);
report.ReferenceAvailable = exist('resample', 'file') == 2;
report.ReferenceName = 'MATLAB resample, if Signal Processing Toolbox is installed';
if ~report.ReferenceAvailable
    report.Status = 'Reference unavailable in this MATLAB installation';
    report.Message = ['No MATLAB resample function was found. The local FIR ' ...
        'was validated with deterministic DC and tone tests instead.'];
    report.ReferenceLength = NaN;
    report.DelaySamples = NaN;
    report.RMSError = NaN;
    report.MaxError = NaN;
    return;
end

reference = resample(input, 6, 1);
report.ReferenceLength = length(reference);
[localAligned, referenceAligned, delay] = align_for_validation(local, ...
    reference, 6 * 97);
report.DelaySamples = delay;
count = min(length(localAligned), length(referenceAligned));
errorSignal = localAligned(1:count) - referenceAligned(1:count);
report.RMSError = sqrt(mean(errorSignal.^2));
report.MaxError = max(abs(errorSignal));
report.ReferenceRMS = sqrt(mean(referenceAligned(1:count).^2));
report.RelativeRMSError = report.RMSError / max(report.ReferenceRMS, eps);
report.RelativeMaxError = report.MaxError / max(max(abs(referenceAligned(1:count))), eps);
report.Status = 'Compared with MATLAB resample';
report.Message = 'Comparison completed after bounded delay alignment.';
end

function [aOut, bOut, bestDelay] = align_for_validation(a, b, maxDelay)
bestScore = -inf;
bestDelay = 0;
for candidate = -maxDelay:maxDelay
    if candidate >= 0
        count = min(length(a), length(b) - candidate);
        x = a(1:count);
        y = b(candidate + 1:candidate + count);
    else
        shift = -candidate;
        count = min(length(a) - shift, length(b));
        x = a(shift + 1:shift + count);
        y = b(1:count);
    end
    x = x - mean(x);
    y = y - mean(y);
    score = abs(sum(x .* y)) / max(sqrt(sum(x.^2) * sum(y.^2)), eps);
    if score > bestScore
        bestScore = score;
        bestDelay = candidate;
    end
end
if bestDelay >= 0
    count = min(length(a), length(b) - bestDelay);
    aOut = a(1:count);
    bOut = b(bestDelay + 1:bestDelay + count);
else
    shift = -bestDelay;
    count = min(length(a) - shift, length(b));
    aOut = a(shift + 1:shift + count);
    bOut = b(1:count);
end
end
