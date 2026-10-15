function output = resample_fir_8k_to_48k(input, coefficients)
%RESAMPLE_FIR_8K_TO_48K Direct polyphase FIR; no MATLAB resample dependency.
input = double(input(:));
[phaseCount, tapCount] = size(coefficients);
if phaseCount ~= 6
    error('Expected six interpolation phases.');
end
center = floor(tapCount / 2);
output = zeros(length(input) * phaseCount, 1);
for m = 0:length(output)-1
    sourcePosition = m / phaseCount;
    sourceIndex = floor(sourcePosition);
    phase = mod(m, phaseCount) + 1;
    first = sourceIndex - center + 1;
    last = first + tapCount - 1;
    indices = first:last;
    valid = indices >= 1 & indices <= length(input);
    block = zeros(1, tapCount);
    block(valid) = input(indices(valid));
    output(m + 1) = sum(block .* coefficients(phase, :));
end
end
