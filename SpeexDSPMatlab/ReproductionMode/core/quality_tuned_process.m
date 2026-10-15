function [y,diagnostics,state] = quality_tuned_process(x,c)
%QUALITY_TUNED_PROCESS Source-equation quality configuration.
% The stronger suppression value is the source API's noise_suppress control;
% no unrelated spectral post-filter is applied here.
c.QualityMode = true;
c.NoiseSuppressDb = -35;
c.GainFloor = exp(0.2302585 * c.NoiseSuppressDb);
c.QualityExponent = 1.0;
[y,diagnostics,state] = source_faithful_process(x,c);
end
