function results = main_reproduction_mode(cleanFile,noiseFile,backend,qualityMode,showPlots,playAudio)
%MAIN_REPRODUCTION_MODE Run source-faithful and optional quality outputs.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'core'));
if nargin<1 || isempty(cleanFile), cleanFile='1z88153a8.mat'; end
if nargin<2 || isempty(noiseFile), noiseFile='white8.mat'; end
if nargin<3 || isempty(backend), backend='kiss_fft'; end
if nargin<4, qualityMode=false; end
if nargin<5, showPlots=false; end
if nargin<6, playAudio=false; end
c=reproduction_config(backend);
cleanSpeech=load_sigd(fullfile(root,'..','data','Signal',cleanFile));
noiseBase=load_sigd(fullfile(root,'..','data','Bruit',noiseFile));
prefix=c.InitialNoiseFrames*c.HopSize+c.AnalysisSize;
noise=repmat(noiseBase,ceil((length(cleanSpeech)+prefix)/length(noiseBase)),1);
noise=noise(1:length(cleanSpeech)+prefix); noise=noise-mean(noise);
noise=noise*sqrt(sum(cleanSpeech.^2)/(10^(c.TargetSNRdB/10)* ...
    sum(noise(prefix+1:end).^2)));
clean=[zeros(prefix,1);cleanSpeech]; noisy=clean+noise;
[source,sd,ss]=source_faithful_process(noisy,c);
if qualityMode
    [enhanced,qd,qs]=quality_tuned_process(noisy,c);
else
    enhanced=source; qd=sd; qs=ss;
end
idx=prefix+1:length(clean);
results.Config=c; results.Clean=clean; results.Noise=noise;
results.Noisy=noisy; results.SourceFaithful=source; results.Enhanced=enhanced;
results.SourceDiagnostics=sd; results.Diagnostics=qd;
results.SourceState=ss; results.State=qs;
results.Metrics.InputSNRdB=10*log10(sum(clean(idx).^2)/sum((noisy(idx)-clean(idx)).^2));
results.Metrics.SourceOutputSNRdB=10*log10(sum(clean(idx).^2)/sum((source(idx)-clean(idx)).^2));
results.Metrics.OutputSNRdB=10*log10(sum(clean(idx).^2)/sum((enhanced(idx)-clean(idx)).^2));
results.Metrics.SourceImprovementdB=results.Metrics.SourceOutputSNRdB-results.Metrics.InputSNRdB;
results.Metrics.ImprovementdB=results.Metrics.OutputSNRdB-results.Metrics.InputSNRdB;
out=fullfile(root,'..','generated'); if ~exist(out,'dir'), mkdir(out); end
save(fullfile(out,'reproduction_mode_results.mat'),'-struct','results');
fprintf('Backend %s: input %.3f dB, source %.3f dB, selected %.3f dB\n', ...
    backend,results.Metrics.InputSNRdB,results.Metrics.SourceOutputSNRdB,results.Metrics.OutputSNRdB);
if showPlots || playAudio
    plot_and_listen(clean,noise,noisy,source,enhanced,c.Fs,playAudio);
end
end
