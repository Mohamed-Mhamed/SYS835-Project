function signal = load_sigd(fileName)
data = load(fileName);
if ~isfield(data, 'sigd'), error('Missing sigd: %s', fileName); end
signal = double(data.sigd(:));
if isempty(signal) || any(~isfinite(signal)), error('Invalid signal: %s', fileName); end
end
