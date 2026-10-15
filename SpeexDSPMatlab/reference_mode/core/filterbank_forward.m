function bands = filterbank_forward(bank, spectrum)
%FILTERBANK_FORWARD SpeexDSP filterbank_compute_bank equivalent.
bands = zeros(bank.NumBands, 1);
for bin = 1:bank.NumBins
    bands(bank.Left(bin)) = bands(bank.Left(bin)) + ...
        bank.LeftWeight(bin) * spectrum(bin);
    bands(bank.Right(bin)) = bands(bank.Right(bin)) + ...
        bank.RightWeight(bin) * spectrum(bin);
end
end
