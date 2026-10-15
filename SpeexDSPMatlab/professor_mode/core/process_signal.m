function [y,d,state] = process_signal(x,c)
n=ceil(length(x)/c.HopSize); y=zeros(n*c.HopSize,1); z=zeros(n*c.HopSize,1);
z(1:length(x))=x;
state.NoisePower=zeros(c.FFTSize,1); state.PreviousXi=zeros(c.FFTSize,1);
state.PreviousGain=c.GainFloor*ones(c.FFTSize,1); state.Presence=zeros(c.FFTSize,1);
state.NoiseHistory=zeros(c.FFTSize,c.NoiseHistoryFrames); state.HistoryIndex=1; state.FrameIndex=0;
d.Gain=zeros(c.FFTSize,n); d.NoisePower=zeros(c.FFTSize,n); d.Presence=zeros(1,n);
for k=1:n
    a=(k-1)*c.HopSize+1; b=a+c.BlockSize-1;
    [y(a:b),state,q]=process_frame(z(a:b),state,c);
    d.Gain(:,k)=q.Gain; d.NoisePower(:,k)=q.NoisePower; d.Presence(k)=q.Presence;
end
y=y(1:length(x));
end
