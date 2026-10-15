function gain = speex_source_gain(gamma, prior, c)
%SPEEX_SOURCE_GAIN Floating-point gain path from SpeexDSP preprocess.c.
% This replaces the Bessel-function MMSE helper for the portable path.
priorRatio = prior ./ max(1 + prior, eps);
theta = max(priorRatio .* (1 + gamma - 1), 0);
mm = speex_hypergeom_gain(theta);
gain = min(priorRatio .* mm, 1);
gain(~isfinite(gain)) = c.GainFloor;
end
