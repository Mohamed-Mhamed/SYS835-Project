function spectrum = filterbank_inverse(bank, bands)
%FILTERBANK_INVERSE SpeexDSP filterbank_compute_psd equivalent.
spectrum = zeros(bank.NumBins, 1);
for bin = 1:bank.NumBins
    spectrum(bin) = bands(bank.Left(bin)) * bank.LeftWeight(bin) + ...
        bands(bank.Right(bin)) * bank.RightWeight(bin);
end
end
