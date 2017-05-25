function [  ] = SCORE_gui( new_load )
%GUI to score the EEG data for high frequency oscillations (HFO's)
%
% INPUT:
%
%   data - an array with dimensions [#Samples , #Channels]
%
% OUTPUT:
%
% 
%
%%%%%%%%%
%delete previous figure
delete(findobj('Tag','SCORE_GUI'));
% Initialize the figure
figure('Position',[1180 100 330 480],'Tag','SCORE_GUI');hold on;
set(findobj('Tag','SCORE_GUI'),'KeyPressFcn',@keypressCallback);
set(gca,'Visible','off')
set(findobj('Tag','SCORE_GUI'),'toolbar','figure') %enable the toolbar for the figure
%create the structure that will hold the gui information
scores=guidata(findobj('Tag','SCORE_GUI'));
if new_load==0; %new scoring file
    scores.hfos=cell(0,3);
    scores.fname='....file-path...';
elseif new_load==1;
    [fname pth] = uigetfile('*.txt','Choose .txt File');
    waiting=1;
    while waiting; pause(1); waiting=~exist('fname','var');end
    dataFile = fullfile(pth,fname);if pth==0;return;end
    scores.hfos = read_score(dataFile); %import the scored file
    scores.fname=dataFile;
end

%set default data params
scores.dex=[]; %hfo index
scores.onoff=0; %onset or offset
scores.tag=''; % tag of the event
scores.lines=0; %don't plot the lines
%%%%%%%%%
% TABLE %
%%%%%%%%%
 tableH=uitable(findobj('Tag','SCORE_GUI'),'Tag','score_table','Data', scores.hfos, ...
   'RowName', '', ...
   'ColumnName', {'ONSET', 'OFFSET','TAG'}, ...
   'ColumnEditable',logical([0 0 1]),...
   'ColumnWidth', {90,90,90},...
   'Enable','on');
set(tableH,'CellEditCallback',@celleditCallback);
%set(tableH,'ButtonDownFcn',@tableCallback);
set(tableH,'CellSelectionCallback',@selectCallback);
set(tableH,'KeyPressFcn',@keypressCallback);
guidata(findobj('Tag','SCORE_GUI'),scores);
% function [hfotab]=tableCallback(tableH,eventData)
% disp('push')
% end
function [scores]=selectCallback(tableH,eventData)
    scores=guidata(findobj('Tag','SCORE_GUI'));
scores.dex=eventData.Indices;
guidata(findobj('Tag','SCORE_GUI'),scores); %update guidata with dex
% First check if the cell is empty
if isempty(scores.dex)|... 
        isempty(scores.hfos{scores.dex(1),scores.dex(2)})|...
        scores.dex(2)==3;
        return;
end
%return if empty, or 3rd column (tag)
%if scores.dex(2)<3 %only the onset/offset fields make plot jump
    
    %plot
    handles=guidata(findobj('Tag','HFO_GUI'));
    handles.samp=scores.hfos{scores.dex(1),scores.dex(2)};
    handles.xval=(handles.samp-handles.window_samples/2)/handles.num_samples;
    set(findobj('Tag','scrollbarX'),'Value',handles.xval);
    guidata(findobj('Tag','HFO_GUI'),handles)
    figure(findobj('Tag','HFO_GUI'));
    handles=plot_data(handles);
    guidata(findobj('Tag','HFO_GUI'),handles)
    figure(findobj('Tag','SCORE_GUI'));
%end
set(findobj('Tag','editRow'),'String',num2str(scores.dex(1)));
guidata(findobj('Tag','SCORE_GUI'),scores);
end
function [scores]=celleditCallback(tableH,eventData)
    scores=guidata(findobj('Tag','SCORE_GUI'));
    if eventData.Indices(2)==3
        scores.hfos{eventData.Indices(1),3}=eventData.EditData;
        set(findobj('Tag','score_table'),'Data',scores.hfos);
        %unselect
        scores.dex=[];
        set(findobj('Tag','editRow'),'String','');
        %save scores structure
        guidata(findobj('Tag','SCORE_GUI'),scores);
    end
end
function [scores]=keypressCallback(tableH,eventData)
    %important note about keypress
    %keyboard;
scores=guidata(findobj('Tag','SCORE_GUI'));
if isempty(scores.dex);return;end
switch eventData.Key
        case {'return','space'}
            %if strcmp(eventData.Key,'return');scores.dex(1)=scores.dex(1)-1;end %return causes select to jump
            if scores.dex(2)<3 & ~isempty(scores.tag)
                scores.hfos{scores.dex(1),3}=scores.tag;
            end
            guidata(findobj('Tag','SCORE_GUI'),scores)
            set(findobj('Tag','score_table'),'Data',scores.hfos);
            eventData.Indices=[scores.dex(1)+1 scores.dex(2)];
            if eventData.Indices(1)>size(scores.hfos,1);eventData.Indices(1)=size(scores.hfos,1);end
            [scores]=selectCallback(tableH,eventData);
        case {'backspace','delete'}
            %delete the point
            %y = x(~ismember(1:size(x,1), [3,9]), :);
            scores.hfos=scores.hfos(~ismember(1:size(scores.hfos,1),[scores.dex(1)]),:);
            guidata(findobj('Tag','SCORE_GUI'),scores)
            scores=pushSORT(tableH,eventData); 
            scores.dex=[];
            set(findobj('Tag','editRow'),'String','');
            guidata(findobj('Tag','SCORE_GUI'),scores)
            return
        case '1'
            %mixed HFO      
            if ~isempty(scores.dex)&scores.dex(2)~=3
                scores.hfos{scores.dex(1),3}='1'; %store in third column as ripple
%                 if ~isempty(scores.tag)
%                    scores.hfos{scores.dex(1),3}=scores.tag; 
%                 end
            end
        case '2'
            %Artifact     
            if ~isempty(scores.dex)&scores.dex(2)~=3
                scores.hfos{scores.dex(1),3}='2'; %store in third column as Artifact
%                 if ~isempty(scores.tag)
%                    scores.hfos{scores.dex(1),3}=scores.tag; 
%                 end
            end
        case '3'
            %Fast-Ripple     
            if ~isempty(scores.dex)&scores.dex(2)~=3
                scores.hfos{scores.dex(1),3}='3'; %store in third column as Fast-ripple
%                 if ~isempty(scores.tag)
%                    scores.hfos{scores.dex(1),3}=scores.tag; 
%                 end

            end
        case '4'
            %slow ripple     
            if ~isempty(scores.dex)&scores.dex(2)~=3
                scores.hfos{scores.dex(1),3}='4'; %store in third column as slow ripple
%                 if ~isempty(scores.tag)
%                    scores.hfos{scores.dex(1),3}=scores.tag; 
%                 end
            end
            
end
guidata(findobj('Tag','SCORE_GUI'),scores)
set(findobj('Tag','editRow'),'String',num2str(scores.dex(1)));
set(findobj('Tag','score_table'),'Data',scores.hfos);
end
%%%%%%%%%%%%%%
% BUTTONS
%%%%%%%%%%%%%%%
%
hImport = uicontrol(findobj('Tag','SCORE_GUI'),'Style','pushbutton',...
'string','SAVE','Position',[10 420 50 30],'Callback',@saveScore);
function saveScore(hImport,eventdata)
scores=guidata(findobj('Tag','SCORE_GUI'));
write_score(scores.fname,scores.hfos);
end
%field for choosing window size
uicontrol(findobj('Tag','SCORE_GUI'),'Style','edit',...
        'String',scores.fname,'FontWeight','bold',...
        'Position',[10 450 310 25],...
        'Tag',['editFname'],...
        'Callback',{@editFname},...
        'Visible','on')
function editFname(hObj,eventdata)
scores=guidata(findobj('Tag','SCORE_GUI'));
scores.fname=get(hObj,'String');
guidata(findobj('Tag','SCORE_GUI'),scores);
end

%NOISE CHECKBOX
uicontrol(findobj('Tag','SCORE_GUI'),'Style','checkbox',...
        'String','noise','FontWeight','bold',...
        'Position',[210 330 65 20],...
        'Tag',['checkNoise'],...
        'Callback',{@checkNoise},...
        'Visible','on')
    %set(findobj('Tag','checkNoise'),'KeyPressFcn',@keypressCallback);
function scores=checkNoise(hObj,eventdata)
    scores=guidata(findobj('Tag','SCORE_GUI'));
if get(hObj,'Value')
scores.tag='noise';
set(findobj('Tag','checkHFO'),'Value',0)
elseif ~get(hObj,'Value')
scores.tag='';
end
    guidata(findobj('Tag','SCORE_GUI'),scores);
end
%HFO CHECKBOX
uicontrol(findobj('Tag','SCORE_GUI'),'Style','checkbox',...
        'String','HFO','FontWeight','bold',...
        'Position',[210 360 50 20],...
        'Tag',['checkHFO'],...
        'Callback',{@checkHFO},...
        'Visible','on')
    %set(findobj('Tag','checkHFO'),'KeyPressFcn',@keypressCallback);
function [scores]=checkHFO(hObj,eventdata)
    scores=guidata(findobj('Tag','SCORE_GUI'));
if get(hObj,'Value')
scores.tag='hfo';
set(findobj('Tag','checkNoise'),'Value',0)
elseif ~get(hObj,'Value')
scores.tag='';
end
    guidata(findobj('Tag','SCORE_GUI'),scores);
end
%ROW FIELD
uicontrol(findobj('Tag','SCORE_GUI'),'Style','edit',...
        'String','','FontWeight','bold',...
        'Position',[10 330 80 20],...
        'Tag',['editRow'],...
        'Callback',{},...
        'Visible','on')
%UNSELECT Button
uicontrol(findobj('Tag','SCORE_GUI'),'Style','pushbutton',...
        'String','UNSELECT','FontWeight','bold',...
        'Position',[10 360 80 20],...
        'Tag',['pushUNSELECT'],...
        'Callback',{@pushUNSELECT},...
        'Visible','on')
    %set(findobj('Tag','checkHFO'),'KeyPressFcn',@keypressCallback);
function [scores]=pushUNSELECT(hObj,eventdata)
    scores=guidata(findobj('Tag','SCORE_GUI'));
scores.dex=[];
set(findobj('Tag','editRow'),'String','');
%you can now add more events because the keypress fun in the HFO_gui will
%auto add for empty dexes
    guidata(findobj('Tag','SCORE_GUI'),scores);
end
%SORT Button
uicontrol(findobj('Tag','SCORE_GUI'),'Style','pushbutton',...
        'String','SORT','FontWeight','bold',...
        'Position',[100 360 40 20],...
        'Tag',['pushSORT'],...
        'Callback',{@pushSORT},...
        'Visible','on')
    %set(findobj('Tag','checkHFO'),'KeyPressFcn',@keypressCallback);
function [scores]=pushSORT(hObj,eventdata)
    scores=guidata(findobj('Tag','SCORE_GUI'));
[~,i]=sort([scores.hfos{:,1}]);
scores.hfos=scores.hfos(i,:);
set(findobj('Tag','score_table'),'Data',scores.hfos);
%you can now add more events because the keypress fun in the HFO_gui will
%auto add for empty dexes

    guidata(findobj('Tag','SCORE_GUI'),scores);
end
%LINES BOX
uicontrol(findobj('Tag','SCORE_GUI'),'Style','checkbox',...
        'String','PLOT','FontWeight','bold',...
        'Position',[100 330 70 20],...
        'Tag',['checkPLOT'],...
        'Callback',{@checkPLOT},...
        'Visible','on','Value',scores.lines)
    %set(findobj('Tag','checkHFO'),'KeyPressFcn',@keypressCallback);
function [scores]=checkPLOT(hObj,eventdata)
    scores=guidata(findobj('Tag','SCORE_GUI'));
scores.lines=get(hObj,'Value');
if ~scores.lines
    try
        delete(findall(findobj('Tag','HFO_GUI'),'Tag','scoreline'));
    end
end
%you can now add more events because the keypress fun in the HFO_gui will
%auto add for empty dexes
    guidata(findobj('Tag','SCORE_GUI'),scores);
end
%NEW CHECKBOX
% uicontrol(findobj('Tag','SCORE_GUI'),'Style','checkbox',...
%         'String','NEW','FontWeight','bold',...
%         'Position',[10 360 50 20],...
%         'Tag',['checkNEW'],...
%         'Callback',{@checkNEW},...
%         'Visible','on')
% function [scores]=checkNEW(hObj,eventdata)
%     scores=guidata(findobj('Tag','SCORE_GUI'));
% if get(hObj,'Value')
% scores.tag='hfo';
% set(findobj('Tag','checkNoise'),'Value',0)
% elseif ~get(hObj,'Value')
% scores.tag='';
% end
%     guidata(findobj('Tag','SCORE_GUI'),scores);
% end
% %STOPBUTTON
% uicontrol(findobj('Tag','HFO_GUI'),'Style','radiobutton',...
%         'String','STOP','FontWeight','bold',...
%         'Position',[1000 55 75 20],...
%         'Tag',['pushStop'],...
%         'Callback',{@pushStop},...
%         'Visible','on','Value',1)
% function pushStop(hObj,eventdata)
% handles=guidata(findobj('Tag','HFO_GUI'));
% handles.play=0;set(findobj('Tag','pushPlay'),'Value',0);
% set(findobj('Tag','pushStop'),'Value',1)
% guidata(findobj('Tag','HFO_GUI'),handles)
% end
% %SCOREBUTTON
% uicontrol(findobj('Tag','HFO_GUI'),'Style','radiobutton',...
%         'String','SCORE','FontWeight','bold',...
%         'Position',[1000 450 75 20],...
%         'Tag',['pushScore'],...
%         'Callback',{@pushScore},...
%         'Visible','on','Value',0)
% function pushScore(hObj,eventdata)
% handles=guidata(findobj('Tag','HFO_GUI'));
% handles.score=1;set(findobj('Tag','pushScore'),'Value',1);
% guidata(findobj('Tag','HFO_GUI'),handles)
% 
% end
% 
% % Scroll buttons
% % X-Axis SLIDER
% uicontrol(findobj('Tag','HFO_GUI'),'Style','slider',...
%         'Min',0,'Max',1,'Value',handles.xval,...
%         'SliderStep',handles.slider_step,...
%         'Position',[100 5 880 20],...
%         'Tag',['scrollbarX'],...
%         'Callback',@scrollBarX,...
%         'Visible','on', 'BusyAction','cancel')
%     
%     function scrollBarX(hObj, eventdata)
%         handles=guidata(findobj('Tag','HFO_GUI'));
%         handles.xval = get(hObj,'Value');
%         guidata(findobj('Tag','HFO_GUI'),handles)
%         figure(findobj('Tag','HFO_GUI'));hold on;
%         plot_data();
%         guidata(findobj('Tag','HFO_GUI'),handles)
%     end %scrollbar function
%     % FOR scroll wheel
%     function scrollWheel(hObj, eventdata)
%         handles=guidata(findobj('Tag','HFO_GUI'));
%         handles.xval = get(findobj('Tag','scrollbarX'),'Value');
%         %make sure it doesnt go below zero or above one
%         if handles.xval<0 | handles.xval>1;return;end
%         figure(findobj('Tag','HFO_GUI'));hold on;
%         guidata(findobj('Tag','HFO_GUI'),handles)
%         plot_data();
%         set(findobj('Tag','scrollbarX'),'Value',handles.xval); %update the slider
%         guidata(findobj('Tag','HFO_GUI'),handles)
%     end %scrollbar function
% 
% % Y-Axis SLIDER
% uicontrol(findobj('Tag','HFO_GUI'),'Style','slider',...
%         'Min',0.01,'Max',40,'Value',handles.yval1,...
%         'SliderStep',[.01 .1],...
%         'Position',[20 200 20 100],...
%         'Tag',['scrollbarY1'],...
%         'Callback',@scrollBarY1,...
%         'Visible','on', 'BusyAction','cancel')   
%     function scrollBarY1(hObj, eventdata)
%         handles=guidata(findobj('Tag','HFO_GUI'));
%         handles.yval1 = get(hObj,'Value');
%         guidata(findobj('Tag','HFO_GUI'),handles)
%         figure(findobj('Tag','HFO_GUI'))
%         plot_data();
%         
%     end %scrollbar function
% %Jump-To pushbutton
% uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton',...
%         'String',['Jump-To '],...
%         'Position',[12 20 60 30],...
%         'Tag',['checkboxcursor'],...
%         'Callback',{@pushGOTO},...
%         'Visible','on')
% % --- Executes on button press in pushGOTO.
% function [handles]=pushGOTO(hObj, eventdata)
% handles=guidata(findobj('Tag','HFO_GUI'));
% handles.samp=str2double(get(findobj('Tag','editXpoint'),'String'));
% handles.xval=(handles.samp-1)/handles.num_samples;
% set(findobj('Tag','scrollbarX'),'Value',handles.xval);
% guidata(findobj('Tag','HFO_GUI'),handles)
% plot_data()
% end %noise checkbox function
% 
% 
% 
% guidata(findobj('Tag','HFO_GUI'),handles)
% 
% 
end
% 
