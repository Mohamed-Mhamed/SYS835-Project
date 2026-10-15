function plot_and_listen(clean,noise,noisy,enhanced,fs,playAudio)
figure('Name','SpeexDSP professor mode');
signals={clean,noise,noisy,enhanced}; names={'Clean','Noise','Noisy','Denoised'};
for k=1:4
 subplot(4,1,k); spectrogram(signals{k},256,0,256,fs,'yaxis');
 title(names{k}); colorbar;
end
if playAudio
 for k=1:4
  fprintf('Playing %s...\n',lower(names{k})); soundsc(signals{k},fs);
  pause(length(signals{k})/fs+.2);
 end
end
end
