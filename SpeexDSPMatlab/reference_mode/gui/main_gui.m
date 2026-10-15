function main_gui()
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'reference_mode','core')); c=default_config();
f=figure('Name','SpeexDSP Reference Mode','Position',[300 300 700 420]);
uicontrol(f,'Style','pushbutton','String','Run','Position',[20 370 80 30],'Callback',@run);
for k=1:4
 uicontrol(f,'Style','pushbutton','String',['Play ',num2str(k)],'Position',[110+90*k 370 80 30], ...
 'Callback',{@play,k});
end
ax=axes(f,'Position',[.08 .12 .86 .58]); r=[];
 function run(~,~)
  cl=load_sigd(fullfile(root,'data','Signal',c.CleanFile)); no=load_sigd(fullfile(root,'data','Bruit',c.NoiseFile));
  no=repmat(no,ceil(length(cl)/length(no)),1);no=no(1:length(cl));no=no-mean(no);
  no=no*sqrt(sum(cl.^2)/(10^(c.TargetSNRdB/10)*sum(no.^2)));ny=cl+no;[en,d]=process_signal(ny,c);
  r=struct('clean',cl,'noise',no,'noisy',ny,'enhanced',en);plot(ax,en);grid(ax,'on');title(ax,'Denoised output');
 end
 function play(~,~,k)
  if isempty(r),warning('Run first');return;end
  names={'clean','noise','noisy','enhanced'};soundsc(r.(names{k}),c.Fs);
 end
end
