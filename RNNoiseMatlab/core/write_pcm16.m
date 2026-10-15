function write_pcm16(fileName, signal)
signal = double(signal(:));
peak = max(abs(signal));
if peak > 1
    signal = 0.99 * signal / peak;
end
file = fopen(fileName, 'w', 'ieee-le');
if file < 0
    error('Cannot open PCM output: %s', fileName);
end
count = fwrite(file, round(max(-1, min(1, signal)) * 32767), 'int16');
fclose(file);
if count ~= length(signal)
    error('Incomplete PCM write: %s', fileName);
end
end
