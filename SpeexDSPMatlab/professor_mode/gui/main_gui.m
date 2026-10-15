function main_gui()
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'professor_mode','core')); c=default_config();
f=figure('Name','SpeexDSP Professor Mode','Position',[300 300 700 420]);
uicontrol(f,'Style','pushbutton','String','Run','Position',[20 370 80 30],'Callback',@run);
for k=1:4
 uicontrol(f,'Style','pushbutton','String',['Play ',num2str(k)],'Position',[110+90*k 370 80 30], ...
 'Callback',{@play,k});
end
ax=axes(f,'Position',[.08 .12 .86 .58]); r=[];
 function run(~,~)
  cl=load_sigd(fullfile(root,'data','Signal',c.CleanFile)); no=load_sigd(fullfile(root,'data','Bruit',c.NoiseFile));
  [cl,no,ny,info]=create_test_signal(cl,no,c); [en,d]=process_signal(ny,c);
  r=struct('clean',cl,'noise',no,'noisy',ny,'enhanced',en,'info',info);
  plot(ax,en);grid(ax,'on');title(ax,'Denoised output');
 end
 function play(~,~,k)
  if isempty(r),warning('Run first');return;end
  names={'clean','noise','noisy','enhanced'}; s=r.(names{k});
  s=s(r.info.PrefixSamples+1:end); soundsc(s,c.Fs);
 end
end
