function [y,state,d] = process_frame(x,state,c)
if length(x) ~= c.BlockSize, error('Frame must be 256 samples.'); end
X = fft(double(x(:)),c.FFTSize); P = abs(X).^2;
if state.FrameIndex < c.InitialNoiseFrames
    state.NoisePower = (state.NoisePower*state.FrameIndex+P)/(state.FrameIndex+1);
else
    gamma = P./max(state.NoisePower,eps);
    presence = min(max((gamma-1)/max(c.PresenceThreshold-1,eps),0),1);
    state.Presence = c.PresenceSmoothing*state.Presence + ...
        (1-c.PresenceSmoothing)*presence;
    mask = state.Presence < .35;
    state.NoisePower(mask) = .96*state.NoisePower(mask)+.04*P(mask);
end
state.NoiseHistory(:,state.HistoryIndex)=P;
state.HistoryIndex=state.HistoryIndex+1;
if state.HistoryIndex>c.NoiseHistoryFrames, state.HistoryIndex=1; end
gamma=min(P./max(state.NoisePower,eps),1e4);
xi=c.DecisionDirectedAlpha*state.PreviousXi + ...
    (1-c.DecisionDirectedAlpha)*max(gamma-1,0);
g=mmse_gain(gamma,xi,c);
g=c.GainSmoothing*state.PreviousGain+(1-c.GainSmoothing)*g;
g=min(max(g,c.GainFloor),1);
y=real(ifft(g.*X,c.FFTSize));
state.PreviousXi=g.^2.*gamma; state.PreviousGain=g;
state.FrameIndex=state.FrameIndex+1;
d.NoisePower=state.NoisePower; d.Presence=mean(state.Presence);
d.APosterioriSNR=gamma; d.APrioriSNR=xi; d.Gain=g;
end
