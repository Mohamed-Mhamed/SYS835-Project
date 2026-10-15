function gain = mmse_gain(gamma, xi, config)
v = max(xi,0).*max(gamma,0)./max(1+xi,eps);
v = min(max(v,eps),1e4);
z = v/2;
i0 = besseli(0,z,1).*exp(abs(z));
i1 = besseli(1,z,1).*exp(abs(z));
gain = sqrt(pi).*sqrt(v)./(2*sqrt(max(gamma,eps))).* ...
    exp(-v/2+abs(z)).*((1+v).*i0+v.*i1);
gain(~isfinite(gain)) = config.GainFloor;
gain = min(max(gain,config.GainFloor),1);
end
