function results=main_reference_mode(cleanFile, noiseFile, showPlots, playAudio)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(fullfile(root,'reference_mode','core'));
 c=default_config();cleanSpeech=load_sigd(fullfile(root,'data','Signal',c.CleanFile));noiseBase=load_sigd(fullfile(root,'data','Bruit',c.NoiseFile));
 if nargin >= 1 && ~isempty(cleanFile), c.CleanFile=cleanFile; cleanSpeech=load_sigd(fullfile(root,'data','Signal',c.CleanFile)); end
 if nargin >= 2 && ~isempty(noiseFile), c.NoiseFile=noiseFile; noiseBase=load_sigd(fullfile(root,'data','Bruit',c.NoiseFile)); end
 if nargin >= 3, c.ShowPlots=showPlots; end
 if nargin >= 4, c.PlayAudio=playAudio; end
 prefix=c.InitialNoiseFrames*c.HopSize+c.AnalysisSize; noise=repmat(noiseBase,ceil((length(cleanSpeech)+prefix)/length(noiseBase)),1);
 noise=noise(1:length(cleanSpeech)+prefix);noise=noise-mean(noise);
 noise=noise*sqrt(sum(cleanSpeech.^2)/(10^(c.TargetSNRdB/10)*sum(noise(prefix+1:end).^2)));
 clean=[zeros(prefix,1);cleanSpeech];noisy=clean+noise;
 [enhanced,d,state]=process_signal(noisy,c);idx=prefix+1:length(enhanced);e=noisy(idx)-clean(idx);eo=enhanced(idx)-clean(idx);
results.Clean=clean;results.Noise=noise;results.Noisy=noisy;results.Enhanced=enhanced;results.Diagnostics=d;results.State=state;
results.Metrics.InputSNRdB=10*log10(sum(clean(idx).^2)/sum(e.^2));results.Metrics.OutputSNRdB=10*log10(sum(clean(idx).^2)/sum(eo.^2));
results.Metrics.ImprovementdB=results.Metrics.OutputSNRdB-results.Metrics.InputSNRdB;
out=fullfile(root,'generated');if ~exist(out,'dir'),mkdir(out);end;save(fullfile(out,'reference_mode_results.mat'),'-struct','results');
fprintf('Reference mode: input %.3f dB, output %.3f dB, improvement %.3f dB\n',results.Metrics.InputSNRdB,results.Metrics.OutputSNRdB,results.Metrics.ImprovementdB);
if c.ShowPlots
 figure('Name','SpeexDSP reference waveforms');subplot(3,1,1);plot(clean);title('Clean');
 subplot(3,1,2);plot(noisy);title('Noisy');subplot(3,1,3);plot(enhanced);title('Denoised');
end
if c.ShowPlots || c.PlayAudio
    plot_and_listen(clean,noise,noisy,enhanced,c.Fs,c.PlayAudio);
end
end
