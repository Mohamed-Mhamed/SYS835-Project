function results = main_professor_mode()
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'professor_mode','core'));
c=default_config();
clean=load_sigd(fullfile(root,'data','Signal',c.CleanFile));
noise=load_sigd(fullfile(root,'data','Bruit',c.NoiseFile));
[clean,noise,noisy,info]=create_test_signal(clean,noise,c);
[enhanced,diagnostics,state]=process_signal(noisy,c);
idx=info.PrefixSamples+1:length(enhanced);
eIn=noisy(idx)-clean(idx); eOut=enhanced(idx)-clean(idx);
results.Config=c; results.Info=info; results.Clean=clean; results.Noise=noise;
results.Noisy=noisy; results.Enhanced=enhanced; results.Diagnostics=diagnostics;
results.Metrics.InputSNRdB=10*log10(sum(clean(idx).^2)/sum(eIn.^2));
results.Metrics.OutputSNRdB=10*log10(sum(clean(idx).^2)/sum(eOut.^2));
results.Metrics.ImprovementdB=results.Metrics.OutputSNRdB-results.Metrics.InputSNRdB;
out=fullfile(root,'generated'); if ~exist(out,'dir'),mkdir(out);end
save(fullfile(out,'professor_mode_results.mat'),'-struct','results');
fprintf('Professor mode: input %.3f dB, output %.3f dB, improvement %.3f dB\n', ...
 results.Metrics.InputSNRdB,results.Metrics.OutputSNRdB,results.Metrics.ImprovementdB);
if c.ShowPlots
    figure('Name','Professor mode waveforms'); subplot(3,1,1);plot(clean);title('Clean');
    subplot(3,1,2);plot(noisy);title('Noisy'); subplot(3,1,3);plot(enhanced);title('Denoised');
    figure('Name','Professor mode gain');imagesc(diagnostics.Gain);axis xy;colorbar;
end
if c.ShowPlots || c.PlayAudio
    plot_and_listen(clean(idx),noise(idx),noisy(idx),enhanced(idx),c.Fs,c.PlayAudio);
end
end
