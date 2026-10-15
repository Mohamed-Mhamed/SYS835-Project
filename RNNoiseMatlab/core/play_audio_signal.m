function play_audio_signal(signal, sampleRate, labelText)
%PLAY_AUDIO_SIGNAL Play one signal with playback-only normalization.
if nargin < 3
    labelText = 'audio';
end
signal = double(signal(:));
if isempty(signal) || any(~isfinite(signal))
    error('Cannot play empty or non-finite audio: %s', labelText);
end
peak = max(abs(signal));
if peak > 0
    signal = 0.95 * signal / peak;
end
fprintf('Playing %s\n', labelText);
sound(signal, sampleRate);
pause(length(signal) / sampleRate + 0.5);
end
