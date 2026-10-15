function write_float32(fileName, signal)
file = fopen(fileName, 'w', 'ieee-le');
if file < 0
    error('Cannot open float32 output: %s', fileName);
end
count = fwrite(file, single(signal(:)), 'float32');
fclose(file);
if count ~= numel(signal)
    error('Incomplete float32 write: %s', fileName);
end
end
