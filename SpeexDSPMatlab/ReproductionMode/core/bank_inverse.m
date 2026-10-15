function spectrum = bank_inverse(bank, bands)
%BANK_INVERSE Fixed-size Bark-band to linear-bin interpolation.
spectrum = zeros(bank.NumBins,1);
for i = 1:bank.NumBins
    spectrum(i) = bank.LeftWeight(i)*bands(bank.Left(i)) + ...
        bank.RightWeight(i)*bands(bank.Right(i));
end
end
