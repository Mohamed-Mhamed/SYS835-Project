function signal = read_pcm16(fileName)
file = fopen(fileName, 'r', 'ieee-le');
if file < 0
    error('Cannot open PCM input: %s', fileName);
end
signal = double(fread(file, inf, 'int16')) / 32768;
fclose(file);
signal = signal(:);
if isempty(signal)
    error('PCM output is empty: %s', fileName);
end
end
