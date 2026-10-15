function c = reproduction_config(backend)
%REPRODUCTION_CONFIG Fixed-size offline SpeexDSP reproduction configuration.
if nargin < 1
    backend = 'kiss_fft';
end
c.Fs = 8000;
c.FrameSize = 160;
c.HopSize = 160;
c.AnalysisSize = 320;
c.FFTSize = 160;
c.NumBands = 24;
c.NoiseSuppressDb = -15;
c.GainFloor = exp(0.2302585 * c.NoiseSuppressDb);
c.InitialNoiseFrames = 8;
c.TargetSNRdB = 10;
c.Backend = backend;
c.SourceFaithful = true;
c.QualityExponent = 1.0;
c.QualityMode = false;
end
