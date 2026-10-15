function metrics = calculate_metrics(clean, noisy, enhanced)
count = min([length(clean), length(noisy), length(enhanced)]);
clean = clean(1:count);
noisy = noisy(1:count);
enhanced = enhanced(1:count);
inputError = noisy - clean;
outputError = enhanced - clean;
cleanEnergy = max(sum(clean.^2), eps);
metrics.InputSNRdB = 10 * log10(cleanEnergy / max(sum(inputError.^2), eps));
metrics.OutputSNRdB = 10 * log10(cleanEnergy / max(sum(outputError.^2), eps));
metrics.ImprovementdB = metrics.OutputSNRdB - metrics.InputSNRdB;
metrics.InputMSE = mean(inputError.^2);
metrics.OutputMSE = mean(outputError.^2);
metrics.InputRMSError = sqrt(metrics.InputMSE);
metrics.OutputRMSError = sqrt(metrics.OutputMSE);
metrics.SampleCount = count;
end
