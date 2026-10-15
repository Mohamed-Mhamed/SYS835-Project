function c = portable_config()
%PORTABLE_CONFIG Fixed-size MATLAB configuration for later CCS translation.
c = default_config();
c.Fs = 8000;
c.FrameSize = 160;
c.HopSize = 160;
c.AnalysisSize = 320;
c.FFTSize = 160;
c.NumBands = 24;
c.UsePortableFFT = true;
c.UseSourceWindow = true;
c.ShowPlots = false;
c.PlayAudio = false;
end
