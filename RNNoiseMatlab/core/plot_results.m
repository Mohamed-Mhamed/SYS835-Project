function plot_results(clean, noise, noisy, enhanced, fs, outputFolder, showPlots)
if ~showPlots
    return;
end
time = (0:length(clean)-1) / fs;
figure('Name', 'RNNoise waveforms');
subplot(4,1,1); plot(time, clean); title('Clean speech'); grid on;
subplot(4,1,2); plot(time, noise); title('Noise'); grid on;
subplot(4,1,3); plot(time, noisy); title('Noisy speech'); grid on;
subplot(4,1,4); plot(time, enhanced); title('RNNoise enhanced'); grid on;
xlabel('Time (s)');
saveas(gcf, fullfile(outputFolder, 'waveforms.png'));
figure('Name', 'RNNoise spectrograms');
subplot(3,1,1); simple_spectrogram(clean, fs); title('Clean');
subplot(3,1,2); simple_spectrogram(noisy, fs); title('Noisy');
subplot(3,1,3); simple_spectrogram(enhanced, fs); title('Enhanced');
saveas(gcf, fullfile(outputFolder, 'spectrograms.png'));
end

function simple_spectrogram(signal, fs)
windowLength = 960;
hop = 480;
nfft = 1024;
window = 0.54 - 0.46 * cos(2*pi*(0:windowLength-1)'/(windowLength-1));
count = max(1, floor((length(signal)-windowLength)/hop)+1);
values = zeros(nfft/2+1, count);
for frame = 1:count
    index = (frame-1)*hop+1;
    block = signal(index:min(index+windowLength-1,length(signal)));
    block(end+1:windowLength) = 0;
    spectrum = fft(block .* window, nfft);
    values(:,frame) = 20*log10(max(abs(spectrum(1:nfft/2+1)), 1e-8));
end
imagesc((0:count-1)*hop/fs, (0:nfft/2)*fs/nfft, values);
axis xy; xlabel('Time (s)'); ylabel('Frequency (Hz)'); colorbar;
end
