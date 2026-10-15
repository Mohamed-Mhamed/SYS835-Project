function signal = load_sigd(fileName)
data = load(fileName);
if ~isfield(data, 'sigd')
    error('File does not contain variable sigd: %s', fileName);
end
signal = double(data.sigd(:));
if isempty(signal) || any(~isfinite(signal))
    error('Signal is empty or contains non-finite values: %s', fileName);
end
end
