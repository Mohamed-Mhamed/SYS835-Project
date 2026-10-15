function c = default_config()
c.Fs=8000; c.FrameSize=160; c.HopSize=160; c.AnalysisSize=320; c.FFTSize=160;
c.TargetSNRdB=10; c.InitialNoiseFrames=8; c.NoiseHistoryFrames=16;
c.GainFloor=.03; c.DecisionDirectedAlpha=.98; c.GainSmoothing=.50;
c.NoiseSuppressDb=-15; c.PresenceSmoothing=.70;
c.GainExponent=1.80;
c.NumBands=24;
c.UsePortableFFT=false;
c.UseSourceWindow=false;
c.CleanFile='1z88153a8.mat'; c.NoiseFile='white8.mat';
c.ShowPlots=true; c.PlayAudio=true;
end
