function run_tests()
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'core'));
for backend={'kiss_fft','smallft'}
    c=reproduction_config(backend{1});
    x=sin(2*pi*440*(0:319)'/c.Fs)+0.2*cos(2*pi*900*(0:319)'/c.Fs);
    p=packed_real_fft(x,backend{1});
    assert(max(abs(packed_real_ifft(p,backend{1})-x))<1e-9);
    bank=design_bank(c);
    assert(bank.NumBins==160 && bank.NumBands==24);
    assert(all(bank.Left>=1) && all(bank.Right<=24));
    [y,d,s]=source_faithful_process(repmat(x,5,1),c);
    assert(length(y)==length(x)*5);
    assert(all(isfinite(y)) && all(isfinite(d.Gain(:))));
    assert(s.FrameIndex==10);
end
fprintf('ReproductionMode tests passed for Kiss FFT and SmallFT references.\n');
end
