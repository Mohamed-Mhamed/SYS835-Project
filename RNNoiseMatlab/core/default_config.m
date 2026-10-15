function config = default_config()
%DEFAULT_CONFIG Explicit experiment parameters for the RNNoise reference.
config.FsInput = 8000;
config.FsRNNoise = 48000;
config.FrameSize = 480;
config.TargetSNRdB = 10;
config.CleanFile = '1z88153a8.mat';
config.NoiseFile = 'white8.mat';
config.AddNoiseOnlyPrefix = true;
config.NoiseOnlyPrefixSeconds = 0.25;
config.PlayAudio = true;
config.ShowPlots = true;
config.FirTaps = 97;
config.FirCutoffInputCycles = 0.5;
config.RNNoiseExecutable = '';
end
