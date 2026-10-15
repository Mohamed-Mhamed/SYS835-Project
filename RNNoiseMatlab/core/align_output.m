function [reference, output, delay] = align_output(reference, signal, maxDelay)
reference = reference(:);
signal = signal(:);
best = -inf;
delay = 0;
for candidate = -maxDelay:maxDelay
    if candidate >= 0
        count = min(length(reference), length(signal) - candidate);
        a = reference(1:count);
        b = signal(candidate + 1:candidate + count);
    else
        shift = -candidate;
        count = min(length(reference) - shift, length(signal));
        a = reference(shift + 1:shift + count);
        b = signal(1:count);
    end
    a = a - mean(a);
    b = b - mean(b);
    score = abs(sum(a .* b)) / max(sqrt(sum(a.^2) * sum(b.^2)), eps);
    if score > best
        best = score;
        delay = candidate;
    end
end
if delay >= 0
    count = min(length(reference), length(signal) - delay);
    reference = reference(1:count);
    output = signal(delay + 1:delay + count);
else
    shift = -delay;
    count = min(length(reference) - shift, length(signal));
    reference = reference(shift + 1:shift + count);
    output = signal(1:count);
end
end
