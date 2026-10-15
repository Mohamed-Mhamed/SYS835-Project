function window = speex_source_window(fftLength, frameSize)
%SPEEX_SOURCE_WINDOW Reproduce preprocess.c's floating-point analysis window.
N3 = fftLength - frameSize;
window = ones(fftLength, 1);
for i = 0:2*N3-1
    x = 4 * i / (2*N3);
    if x < 1
        inverse = false;
    elseif x < 2
        x = 2 - x;
        inverse = true;
    elseif x < 3
        x = x - 2;
        inverse = true;
    else
        x = 4 - x;
        inverse = false;
    end
    x = 1.271903 * x;
    tmp = (0.5 - 0.5*cos(pi*x))^2;
    if inverse
        tmp = 1 - tmp;
    end
    window(i+1) = sqrt(tmp);
end
end
