function bands = bank_forward(bank, spectrum)
%BANK_FORWARD Fixed-size linear-bin to Bark-band accumulation.
bands = zeros(bank.NumBands,1);
for i = 1:bank.NumBins
    bands(bank.Left(i)) = bands(bank.Left(i)) + ...
        bank.LeftWeight(i)*spectrum(i);
    bands(bank.Right(i)) = bands(bank.Right(i)) + ...
        bank.RightWeight(i)*spectrum(i);
end
end
