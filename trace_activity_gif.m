%Create a dynamic .gif of cortical activation
%
% INPUT: cortAct - [E x F] where E is the number of electrodes and F is the
% number of frames

% OUTPUT: .gif
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trace_activity_gif(filename,sliceActivity,tstart,tend,tdelt)
%filename='test';tstart=450;tend=750;tdelt=10;
  figure;plot(sliceActivity');hold on;set(gcf,'color','w');
  im=[];
for t=tstart:tdelt:tend 
  [ vertH ] = vert_line( t ,[],'k--',3);
  f = getframe(gcf); %take a snapshot
  if t==tstart;
    [im(:,:,1,(1)),map] = rgb2ind(f.cdata,256,'nodither'); %map?
  end
  [im(:,:,1,end+1),map] = rgb2ind(f.cdata,map,'nodither'); %save the color information from that snapshot
  delete(vertH);
end%time loop
if min(min(min(min(im))))==0;im=im+1;end
imwrite(im,map,[filename '.gif'],'DelayTime',0,'LoopCount',inf)
end%function end