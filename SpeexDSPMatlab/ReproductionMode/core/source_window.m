function w = source_window(frameSize, analysisSize)
%SOURCE_WINDOW Floating-point conj_window from SpeexDSP preprocess.c.
w = ones(analysisSize, 1);
N3 = analysisSize - frameSize;
for i = 0:2*N3-1
    x = 4*i/(2*N3);
    inverse = false;
    if x < 1
    elseif x < 2
        x = 2-x; inverse = true;
    elseif x < 3
        x = x-2; inverse = true;
    else
        x = 4-x;
    end
    x = 1.271903*x;
    value = (0.5 - 0.5*cos(pi*x))^2;
    if inverse
        value = 1-value;
    end
    w(i+1) = sqrt(value);
end
end
