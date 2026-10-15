function plot_and_listen(clean,noise,noisy,source,enhanced,fs,playAudio)
%PLOT_AND_LISTEN Plot comparable spectrograms and optionally play signals.
signals = {clean, noise, noisy, source, enhanced};
names = {'Clean', 'Noise', 'Noisy', 'Source-faithful', 'Selected output'};
figure('Name','SpeexDSP ReproductionMode');
allDb = [];
spectra = cell(1,5);
times = cell(1,5);
frequencies = cell(1,5);
for k = 1:5
    [s,frequencies{k},times{k}] = spectrogram(signals{k},160,80,320,fs);
    spectra{k} = 10*log10(abs(s).^2 + 1e-12);
    allDb = [allDb; spectra{k}(:)]; %#ok<AGROW>
end
limits = [prctile(allDb,2), prctile(allDb,99)];
for k = 1:5
    subplot(5,1,k);
    imagesc(times{k},frequencies{k},spectra{k});
    axis xy;
    clim(limits);
    ylim([0 fs/2]);
    colorbar;
    title(names{k});
    ylabel('Hz');
end
if playAudio
    for k = 1:5
        fprintf('Playing %s...\n',lower(names{k}));
        soundsc(signals{k},fs);
        pause(length(signals{k})/fs + 0.2);
    end
end
end
