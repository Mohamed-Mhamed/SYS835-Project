function x=load_sigd(f)
d=load(f); if ~isfield(d,'sigd'),error('Missing sigd: %s',f);end
x=double(d.sigd(:)); if isempty(x)||any(~isfinite(x)),error('Invalid signal');end
end
