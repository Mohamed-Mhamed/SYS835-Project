function [y,diagnostics,state] = source_faithful_process(x,c)
%SOURCE_FAITHFUL_PROCESS Offline fixed-size SpeexDSP-style reproduction.
x = x(:);
N = c.FFTSize; A = c.AnalysisSize; H = c.HopSize; M = c.NumBands;
frames = ceil(length(x)/H);
total = frames*H;
input = zeros(total+A,1);
input(1:length(x)) = x;
w = source_window(c.FrameSize,A);
bank = design_bank(c);
y = zeros(total,1); norm = zeros(total,1);
state.S=zeros(N,1); state.Smin=zeros(N,1); state.Stmp=zeros(N,1);
state.Noise=eps*ones(N,1); state.OldPower=zeros(N,1);
state.Prior=ones(N,1); state.Post=zeros(N,1); state.Zeta=zeros(N,1);
state.Gain=ones(N,1); state.GainFloor=c.GainFloor*ones(N,1);
state.UpdateProb=ones(N,1); state.FrameIndex=0; state.MinCount=0;
state.NbAdapt=0;
diagnostics.Gain=zeros(N,frames); diagnostics.Gain2=zeros(N,frames);
diagnostics.Noise=zeros(N,frames); diagnostics.Presence=zeros(1,frames);
diagnostics.BandPresence=zeros(M,frames);
diagnostics.APosterioriSNR=zeros(N,frames);
diagnostics.APrioriSNR=zeros(N,frames);
for f = 1:frames
    first=(f-1)*H+1; last=first+A-1;
    frame=input(first:last).*w;
    packed=packed_real_fft(frame,c.Backend);
    positive=zeros(N,1); positive(1)=packed(1);
    for k=1:N-1
        positive(k+1)=packed(2*k)+1i*packed(2*k+1);
    end
    power=abs(positive).^2;
    state.FrameIndex=state.FrameIndex+1; state.MinCount=state.MinCount+1;
    state.NbAdapt=min(state.NbAdapt+1,20000);
    state.S=0.8*state.S;
    state.S(1)=state.S(1)+0.2*power(1);
    state.S(N)=state.S(N)+0.2*power(N);
    for i=2:N-1
        state.S(i)=state.S(i)+0.05*power(i-1)+0.1*power(i)+0.05*power(i+1);
    end
    if state.FrameIndex==1
        state.Smin(:)=0; state.Stmp(:)=0;
    end
    if state.MinCount>15
        state.Smin=min(state.Stmp,state.S); state.Stmp=state.S; state.MinCount=0;
    else
        state.Smin=min(state.Smin,state.S); state.Stmp=min(state.Stmp,state.S);
    end
    state.UpdateProb=double(0.4*state.S>state.Smin);
    beta=max(0.03,1/state.NbAdapt);
    if state.FrameIndex<=c.InitialNoiseFrames
        state.Noise=((state.FrameIndex-1)*state.Noise+power)/state.FrameIndex;
    else
        for i=1:N
            if state.UpdateProb(i)<0.5 || power(i)<state.Noise(i)
                state.Noise(i)=(1-beta)*state.Noise(i)+beta*power(i);
            end
        end
    end
    totalNoise=max(state.Noise,eps);
    gamma=min(power./totalNoise,100); state.Post=gamma-1;
    if state.FrameIndex==1, state.OldPower=power; end
    u=0.1+0.89*(state.OldPower./max(state.OldPower+totalNoise,eps)).^2;
    state.Prior=min(max(u.*max(state.Post,0)+(1-u).* ...
        state.OldPower./max(totalNoise,eps),0),100);
    state.Zeta=0.7*state.Zeta+0.3*state.Prior;
    for i=2:N-1
        state.Zeta(i)=0.7*state.Zeta(i)+0.15*state.Prior(i)+ ...
            0.075*state.Prior(i-1)+0.075*state.Prior(i+1);
    end
    bz=bank_forward(bank,state.Zeta);
    qcurve=1./(1+0.15./max(bz,eps));
    meanBandZeta=mean(bz);
    frameQcurve=1./(1+0.15/max(meanBandZeta,eps));
    presence=min(max(0.1+0.899*frameQcurve,0.1),1);
    bp=min(max(0.199+0.8*qcurve,0),1);
    priorBand=bank_forward(bank,state.Prior);
    postBand=bank_forward(bank,state.Post);
    ratio=priorBand./(1+priorBand);
    theta=max(ratio.*(1+postBand),0);
    bandGain=min(ratio.*hypergeom_gain(theta),1);
    noiseBand=bank_forward(bank,state.Noise);
    noiseFloor=exp(0.2302585*c.NoiseSuppressDb);
    bandFloor=sqrt(noiseFloor*noiseBand./max(1+noiseBand,eps));
    linearFloor=bank_inverse(bank,bandFloor);
    q=min(max(1-presence.*bp,0),1-eps);
    bandGain2=1./(1+(q./max(1-q,eps)).*(1+priorBand).*exp(-theta));
    gain2=bank_inverse(bank,bandGain2);
    linearPriorRatio=state.Prior./max(1+state.Prior,eps);
    linearTheta=max(linearPriorRatio.*(1+state.Post),0);
    linearGain=min(linearPriorRatio.*hypergeom_gain(linearTheta),1);
    bandLinearGain=bank_inverse(bank,bandGain);
    gain=min(max(linearGain, linearFloor),1);
    gain=min(gain,3*max(bandLinearGain,linearFloor));
    state.Gain=(gain2.*sqrt(gain)+(1-gain2).*sqrt(max(linearFloor,eps))).^2;
    if c.QualityMode
        state.Gain = state.Gain.^c.QualityExponent;
    end
    state.Gain=min(max(state.Gain,c.GainFloor),1);
    state.OldPower=0.2*state.OldPower+0.8*(state.Gain.^2).*power;
    packedOut=packed;
    packedOut(1)=state.Gain(1)*packed(1);
    for k=1:N-1
        packedOut(2*k)=state.Gain(k+1)*packed(2*k);
        packedOut(2*k+1)=state.Gain(k+1)*packed(2*k+1);
    end
    packedOut(2*N)=state.Gain(N)*packed(2*N);
    output=packed_real_ifft(packedOut,c.Backend).*w;
    stop=min(last,total); valid=first:stop;
    y(valid)=y(valid)+output(1:length(valid));
    norm(valid)=norm(valid)+w(1:length(valid)).^2;
    diagnostics.Gain(:,f)=state.Gain; diagnostics.Gain2(:,f)=gain2;
    diagnostics.Noise(:,f)=state.Noise; diagnostics.Presence(f)=presence;
    diagnostics.BandPresence(:,f)=bp;
    diagnostics.APosterioriSNR(:,f)=gamma;
    diagnostics.APrioriSNR(:,f)=state.Prior;
end
y=y./max(norm,eps); y=y(1:length(x));
end
