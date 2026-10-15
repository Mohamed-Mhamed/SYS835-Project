function x = load_sigd(fileName)
%LOAD_SIGD Experiment-layer MAT loader; not used by the processing core.
d = load(fileName);
if ~isfield(d,'sigd')
    error('load_sigd:MissingSignal','Missing sigd variable: %s',fileName);
end
x = double(d.sigd(:));
if isempty(x) || any(~isfinite(x))
    error('load_sigd:InvalidSignal','Invalid signal data: %s',fileName);
end
end
