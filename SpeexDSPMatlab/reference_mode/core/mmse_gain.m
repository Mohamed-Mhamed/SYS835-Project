function g=mmse_gain(gamma,xi,c)
v=min(max(xi.*gamma./max(1+xi,eps),eps),1e4); z=v/2;
i0=besseli(0,z,1).*exp(abs(z)); i1=besseli(1,z,1).*exp(abs(z));
g=sqrt(pi).*sqrt(v)./(2*sqrt(max(gamma,eps))).*exp(-v/2+abs(z)).*((1+v).*i0+v.*i1);
g(~isfinite(g))=c.GainFloor; g=min(max(g,c.GainFloor),1);
end
