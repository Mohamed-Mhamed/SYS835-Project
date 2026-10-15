function plot_and_listen(clean,noise,noisy,enhanced,fs,playAudio)
figure('Name','SpeexDSP reference mode');
signals={clean,noise,noisy,enhanced}; names={'Clean','Noise','Noisy','Denoised'};
spectra=cell(1,4); allDb=[];
for k=1:4
 [s,~,~]=spectrogram(signals{k},160,80,320,fs);
 spectra{k}=10*log10(abs(s).^2+1e-12);
 allDb=[allDb; spectra{k}(:)]; %#ok<AGROW>
end
limits=[prctile(allDb,2),prctile(allDb,99)];
for k=1:4
 [~,frequency,time]=spectrogram(signals{k},160,80,320,fs);
 subplot(4,1,k); imagesc(time,frequency,spectra{k}); axis xy;
 caxis(limits); ylim([0 fs/2]); colorbar;
 title(names{k}); ylabel('Hz');
end
if playAudio
 for k=1:4
  fprintf('Playing %s...\n',lower(names{k})); soundsc(signals{k},fs);
  pause(length(signals{k})/fs+.2);
 end
end
end
