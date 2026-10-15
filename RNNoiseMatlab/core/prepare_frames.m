function [signal, padding] = prepare_frames(signal, frameSize)
signal = double(signal(:));
padding = mod(-length(signal), frameSize);
signal = [signal; zeros(padding, 1)];
end
