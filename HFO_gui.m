function [  ] = HFO_gui( varargin )
%GUI to view EEG data for scoring high frequency oscillations (HFO's)
%
% INPUT:
%
%   data - an array with dimensions [#Samples , #Channels]
%   param - string declaring the parameter 'fs','data'
% OUTPUT:
%
% 
%
%%%%%%%%%
% Initialize the figure
figure('Position',[100 100 1080 540],'Tag','HFO_GUI');hold on;
set(findobj('Tag','HFO_GUI'),'WindowScrollWheelFcn',{@scrollWheel}) %enable the scroll wheel
set(findobj('Tag','HFO_GUI'),'toolbar','figure') %enable the toolbar for the figure
%create the structure that will hold the gui information
handles=guidata(findobj('Tag','HFO_GUI'));
%%%% VARARGIN PARSING NEEDS WORK< USE CASE & SWITCH
if nargin>0
try    
    if ~isstruct(varargin{1})&strcmp(varargin(2),'data')
        handles.data=varargin{1};
    elseif isnumeric(varargin{1}) & strcmp(varargin{2},'fs')
        handles.fs=varargin{1};
    end
catch
    error('check variables input');
end
end
%%%%% ^^^^^^ NEEDS WORK ^^^^^
%%% Auto open browser for .mat file
% if nargin==0|~isfield(handles,'data');    
%     [fname pth] = uigetfile('*.mat','Choose .mat File');
%     waiting=1;
%     while waiting; pause(1); waiting=~exist('fname','var');end
%     dataFile = fullfile(pth,fname);
%     handles.data(:,1) = importdata(dataFile);   
% end
if nargin==0|~isfield(handles,'data');
    handles.data=zeros(2000,1);
end
if ~isfield(handles,'fs')|isempty(handles.fs);handles.fs=1000;end
%set default data params
handles.xval=0; %initial slider position 0%
handles.yval1=10; %initial y-slider for amplitude, put in middle
handles.window_size = 2; %the default size of the windows in seconds
handles.hf=80;
handles.bp=175;
% Get data parameters
    function handles=get_data_params(handles)
           
            handles.num_samples = size(handles.data,1); %number of samples, i.e. length of the data vector
            handles.chans=size(handles.data,2);
            %%% get sample rate from edit field
            %%% get window size
            handles.window_samples = handles.fs*handles.window_size; % the number of samples in the window
            handles.slider_step = [.10*handles.window_samples/handles.num_samples handles.window_samples/handles.num_samples]; 
            %ymin=min(quantile(data,.001));ymax=max(quantile(data,.999));
            handles.maxAmp = max(prctile(handles.data,95)); %maximum amplitude plotted
            if handles.maxAmp<=0;handles.maxAmp=max(handles.maxAmp);end
            if handles.maxAmp<=0;handles.maxAmp=1000;end
            guidata(findobj('Tag','HFO_GUI'),handles);
    end
handles=get_data_params(handles);
    function handles=filter_data(handles,chans2filt)
        if nargin<2;chans2filt=[1:handles.chans];end
        %handles.fs = sample frequency Hz
        for c=chans2filt;
            fprintf('\nFiltering Channel #%d\n',c)
        %High-pass filter
%         Fp=80; %passband (frequencies above which are unattenuated)
%         fprintf('\n - high-pass (%d Hz)\n',Fp)
%         Fst=79; %stopband (frequencies below which are attenuated)
%         Ap=0.001; %ripple allowed from pass band
%         Ast=80; %attenuation of the stop band
%         %d1 = fdesign.highpass('Fst,Fp,Ast,Ap,',Fst,Fp,Ast,Ap,handles.fs);
%         d1=fdesign.highpass('N,Fc',20,Fp,handles.fs);
%         Hd1 = design(d1,'butter');
%         handles.hpf_s1(:,c)=filter(Hd1,handles.data(:,c));
fprintf('\nHigh-Pass Filter #1\n')
cutoffs_filt = [handles.hf 499];order=90;
[b a] = fir1(order,cutoffs_filt/(handles.fs/2));
handles.hpf_s1=filtfilt(b,a,handles.data);
[~,amp]=gethilbert2(handles.data(:,c),0,cutoffs_filt,60,handles.fs);
handles.hpf_amp=squeeze(amp);
        %highpass filter 250 Hz
%         Fst1=79;
%         Fp1=80; %passband (frequencies above which are unattenuated)
%         Fp2=250; %passband (frequencies below which are unattenuated)
%         fprintf('\n - band-pass (%d - %d Hz)\n',Fp1,Fp2)
%         Fst2=251;
%         Ast1=80;
%         Ap=0.001;
%         Ast2=80; 
%         %d2 = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2);
%         %d2 = fdesign.bandpass('N,Fst1,Fp1,Fp2,Fst2,C',50,Fst1,Fp1,Fp2,Fst2,handles.fs);
%         %d2 = fdesign.bandpass('N,Fc1,Fc2',50,Fp1,Fp2,handles.fs);
%         d2=fdesign.highpass('N,Fc',20,Fp2,handles.fs);
%         Hd2 = design(d2,'butter');
fprintf('\nHigh-Pass Filter #2\n')
cutoffs_filt = [handles.bp 499];order=90;
[b a] = fir1(order,cutoffs_filt/(handles.fs/2));
handles.bpf_s1=filtfilt(b,a,handles.data(:,c));
[~,amp]=gethilbert2(handles.data(:,c),0,cutoffs_filt,60,handles.fs);
handles.bpf_amp=squeeze(amp);
        end%for channles=1
        guidata(findobj('Tag','HFO_GUI'),handles);
    end%subfunction filter
    handles=filter_data(handles);
%%%%%%%%%%%%%%
% BUTTONS
%%%%%%%%%%%%%%%
%
% Take a Signal Slice of the data (on cursor)
hImport = uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton','string',...
    'SLICE_N','Position',[10 350 70 30],'Callback',@pushSlice);
function pushSlice(hImport,eventdata)
    handles=guidata(findobj('Tag','HFO_GUI'));
    signalSliceN(handles.cursor_samp,handles.data(:,1),handles.fs);
end
%
%THRESHOLD SIGMA
uicontrol(findobj('Tag','HFO_GUI'),'Style','checkbox',...
        'String','THRESH',...
        'Position',[995 410 75 30],...
        'Tag',['checkThresh'],...
        'Callback',{@checkThresh},...
        'Visible','on','Value',0)
function checkThresh(hImport,eventdata)
    handles=guidata(findobj('Tag','HFO_GUI'));
    handles=plot_data(handles);
    guidata(findobj('Tag','HFO_GUI'),handles);
end
%SIGMA TEXT
uicontrol(findobj('Tag','HFO_GUI'),'Style','text',...
        'String','SIGMA',...
        'Position',[995 395 66 19],'Visible','on')
%SIGMA FIELD
uicontrol(findobj('Tag','HFO_GUI'),'Style','edit',...
        'String','3',...
        'Position',[995 360 75 30],...
        'Tag',['editSigma'],...
        'Callback',{@editSigma},...
        'Visible','on','Value',0)
function editSigma(hImport,eventdata)
    handles=guidata(findobj('Tag','HFO_GUI'));
    handles=plot_data(handles);
    guidata(findobj('Tag','HFO_GUI'),handles);
end
% GRID NAME AND DIM FOR BIPOLAR IMPORT
hGridT = uicontrol(findobj('Tag','HFO_GUI'),'Style','text','string',...
    'GRID_NAME','Position',[5 497 68 12]);
hGrid = uicontrol(findobj('Tag','HFO_GUI'),'Style','edit','string',...
    '','Position',[5 477 68 18],'Tag','hGrid');
hDimT = uicontrol(findobj('Tag','HFO_GUI'),'Style','text','string',...
    'GRID_DIM','Position',[5 465 68 12]);
hDim = uicontrol(findobj('Tag','HFO_GUI'),'Style','edit','string',...
    '','Position',[5 447 68 18],'Tag','hDim');
% IMPORT data
hImport = uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton','string',...
    '.EEG->.MAT','Position',[5 509 70 30],'Callback',@openImport);
function openImport(hImport,eventdata)
    grid_name=get(findobj('Tag','hGrid'),'String');grid_dim=get(findobj('Tag','hDim'),'String');
[fname pth] = uigetfile('*.eeg','Choose .eeg File');
%dataFile = fullfile(pth,fname);
%subj=pth(end-4:end-1); %the subject name is the same as the folder containing the file
if ~isempty(pth)&pth~=0
Clinical2DDT_WH([],pth,grid_name,grid_dim)
else
    disp('.eeg ->.mat canceled')
end
end
% Text to display the file being analyzed
uicontrol(findobj('Tag','HFO_GUI'),'Style','text','string','','Position',[995 88 80 30],'Tag','fileana');
%buttons for selecting data
% channel1 data
hButtonOpen = uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton','string','IMPORT .mat','Position',[5 405 80 30],'Callback',@openCh1Callback);
function openCh1Callback(hButtonOpen,eventdata)
    handles=guidata(findobj('Tag','HFO_GUI'));
    handles.fs=str2num(get(findobj('Tag','FS'),'String'));
[fname pth] = uigetfile('*.mat','Choose .mat File');
if pth==0;return;end
dataFile = fullfile(pth,fname);
set(findobj('Tag','fileana'),'string',fname);
handles.data = importdata(dataFile);
%update gui with data
handles=get_data_params(handles);
handles=filter_data(handles,1);
handles=plot_data(handles);
set(findobj('Tag','scrollbarX'),'SliderStep',handles.slider_step);
set(findobj('Tag','scrollbarY1'),'Value',handles.yval1);
guidata(findobj('Tag','HFO_GUI'),handles);
end
%% SAMPLE RATE FIELD
hButtonOpen = uicontrol(findobj('Tag','HFO_GUI'),'Style','edit','String','1000','Position',[5 385 70 20],'Tag','FS','Callback',@editFS);
    function editFS(hObj,eventdata,handles)
         handles=guidata(findobj('Tag','HFO_GUI'));
    handles.fs=str2num(get(findobj('Tag','FS'),'String'));
    guidata(findobj('Tag','HFO_GUI'),handles);
    end
%samplerate text
fst = uicontrol(findobj('Tag','HFO_GUI'),'Style','text','String','Fs','Position',[77 385 30 20]);
%field for choosing window size
uicontrol(findobj('Tag','HFO_GUI'),'Style','edit',...
        'String',num2str(handles.window_size),'FontWeight','bold',...
        'Position',[1000 5 30 20],...
        'Tag',['editWindow'],...
        'Callback',{@editWindow},...
        'Visible','on')
function editWindow(hObj,eventdata,handles)
handles=guidata(findobj('Tag','HFO_GUI'));
handles.window_size=str2double(get(hObj,'String'));
if handles.window_size>handles.num_samples/(handles.fs)
    %if the user puts in more minutes than are in the file
    handles.window_size=handles.num_samples/(handles.fs);
    handles.xval=0;
elseif handles.window_size>handles.xlimit(2)-handles.xlimit(1)/(handles.fs)
    %if the minutes chosen go further than the space left
    handles.xval=0;  
elseif isempty(handles.window_size)|isnan(handles.window_size)|~isa(handles.window_size,'double');
    handles.window_size=2;
    set(hObj,'String',num2str(handles.window_size))
end
handles=get_data_params(handles);guidata(findobj('Tag','HFO_GUI'),handles);
handles=plot_data(handles);
set(findobj('Tag','scrollbarX'),'Value',handles.xval); %update the slider
guidata(findobj('Tag','HFO_GUI'),handles);
end 
%PLAYBUTTON
uicontrol(findobj('Tag','HFO_GUI'),'Style','radiobutton',...
        'String','PLAY','FontWeight','bold',...
        'Position',[1000 30 80 20],...
        'Tag',['pushPlay'],...
        'Callback',{@pushPlay},...
        'Visible','on')
function pushPlay(hObj,eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
handles.speed=.25;
handles.play=1;set(findobj('Tag','pushStop'),'Value',0)
set(findobj('Tag','HFO_GUI'),'WindowButtonDownFcn',@pushStop);
set(findobj('Tag','HFO_GUI'), 'WindowKeyPressFcn', {@pushStop});
while handles.play==1 & handles.xval+handles.slider_step(1)<1;
handles.xval=handles.xval+handles.slider_step(1);
        guidata(findobj('Tag','HFO_GUI'),handles)
        handles=plot_data(handles);
        set(findobj('Tag','scrollbarX'),'Value',handles.xval); %update the slider
        pause(handles.speed);
        guidata(findobj('Tag','HFO_GUI'),handles)
end
end
%STOPBUTTON
uicontrol(findobj('Tag','HFO_GUI'),'Style','radiobutton',...
        'String','STOP','FontWeight','bold',...
        'Position',[1000 55 75 20],...
        'Tag',['pushStop'],...
        'Callback',{@pushStop},...
        'Visible','on','Value',1)
function pushStop(hObj,eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
handles.play=0;set(findobj('Tag','pushPlay'),'Value',0);
set(findobj('Tag','pushStop'),'Value',1)
set(findobj('Tag','HFO_GUI'), 'WindowButtonDownFcn', {});
set(findobj('Tag','HFO_GUI'), 'WindowKeyPressFcn', {});
    if   get(findobj('Tag','pushScore'),'Value')==1
        set(findobj('Tag','HFO_GUI'),'WindowButtonDownFcn',@clickA2DPoint);
        set(findobj('Tag','HFO_GUI'), 'WindowKeyPressFcn', {@scoreStore});
    elseif get(findobj('Tag','radioCursor'),'Value')==1
         set(findobj('Tag','HFO_GUI'),'WindowButtonDownFcn',@clickA2DPoint);
    end
guidata(findobj('Tag','HFO_GUI'),handles)
end
%SCOREBUTTON
uicontrol(findobj('Tag','HFO_GUI'),'Style','radiobutton',...
        'String','SCORE','FontWeight','bold',...
        'Position',[1000 510 75 20],...
        'Tag',['pushScore'],...
        'Callback',{@pushScore},...
        'Visible','on','Value',0)
function pushScore(hObj,eventdata)
% handles=guidata(findobj('Tag','HFO_GUI'));
% handles.score=1;set(findobj('Tag','pushScore'),'Value',1);
% guidata(findobj('Tag','HFO_GUI'),handles)
if get(hObj,'Value')
set(findobj('Tag','HFO_GUI'), 'WindowKeyPressFcn', {@scoreStore});
elseif ~(get(hObj,'Value'))
 set(findobj('Tag','HFO_GUI'), 'WindowKeyPressFcn', {});   
end
end
%NEW_SCOREBUTTON
uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton',...
        'String','NEW','FontWeight','bold',...
        'Position',[1000 480 75 20],...
        'Tag',['pushNewscore'],...
        'Callback',{@pushNewscore},...
        'Visible','on')
function pushNewscore(hObj,eventdata)
SCORE_gui(0);
set(findobj('Tag','HFO_GUI'),'WindowButtonDownFcn',@clickA2DPoint);
set(findobj('Tag','HFO_GUI'), 'WindowKeyPressFcn', {@scoreStore});
set(findobj('Tag','pushScore'),'Value',1)
set(findobj('Tag','radioCursor'),'Value',1)
end
%LOAD_SCOREBUTTON
uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton',...
        'String','LOAD','FontWeight','bold',...
        'Position',[1000 450 75 20],...
        'Tag',['pushLoadscore'],...
        'Callback',{@pushLoadscore},...
        'Visible','on')
function pushLoadscore(hObj,eventdata)
SCORE_gui(1);
set(findobj('Tag','HFO_GUI'),'WindowButtonDownFcn',@clickA2DPoint);
set(findobj('Tag','HFO_GUI'), 'WindowKeyPressFcn', {@scoreStore});
set(findobj('Tag','pushScore'),'Value',1)
set(findobj('Tag','radioCursor'),'Value',1)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scoreStore(hObj,eventData)
    if isempty(findobj('Tag','SCORE_GUI'));return;end
scores=guidata(findobj('Tag','SCORE_GUI'));
handles=guidata(findobj('Tag','HFO_GUI'));
switch eventData.Key
        case {'return','space'}
            %store the point
            if ~isempty(scores.dex)&scores.dex(2)~=3
                scores.hfos{scores.dex(1),scores.dex(2)}=handles.cursor_samp;
                if ~isempty(scores.tag)
                   scores.hfos{scores.dex(1),3}=scores.tag; 
                end
            end
            if isempty(scores.dex)               
                    
                if ~isempty(scores.hfos)&isempty(scores.hfos{end,2})&~isempty(scores.hfos{end,1})
                    scores.hfos{end,2}=handles.cursor_samp;
                else
                    scores.hfos{end+1,1}=handles.cursor_samp;
                end
                if ~isempty(scores.tag)
                   scores.hfos{end,3}=scores.tag; 
                end
                set(findobj('Tag','editRow'),'String',num2str(size(scores.hfos,1)));
            end
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
        case {'backspace','delete'}
            %delete the point
            
end
scores.dex=[];
set(findobj('Tag','score_table'),'Data',scores.hfos);
guidata(findobj('Tag','SCORE_GUI'),scores)
guidata(findobj('Tag','HFO_GUI'),handles)
end
% plot the data   
        handles=guidata(findobj('Tag','HFO_GUI'));
        handles=plot_data(handles);
        guidata(findobj('Tag','HFO_GUI'),handles);
  
   
% Scroll buttons
% X-Axis SLIDER
uicontrol(findobj('Tag','HFO_GUI'),'Style','slider',...
        'Min',0,'Max',1,'Value',handles.xval,...
        'SliderStep',handles.slider_step,...
        'Position',[100 5 880 20],...
        'Tag',['scrollbarX'],...
        'Callback',@scrollBarX,...
        'Visible','on', 'BusyAction','cancel')
    
    function scrollBarX(hObj, eventdata)
        handles=guidata(findobj('Tag','HFO_GUI'));
        handles.xval = get(hObj,'Value');
        guidata(findobj('Tag','HFO_GUI'),handles)
        figure(findobj('Tag','HFO_GUI'));hold on;
        handles=plot_data(handles);
        guidata(findobj('Tag','HFO_GUI'),handles)
    end %scrollbar function
    % FOR scroll wheel
    function scrollWheel(hObj, eventdata)
        handles=guidata(findobj('Tag','HFO_GUI'));
        handles.xval = get(findobj('Tag','scrollbarX'),'Value');
        %make sure it doesnt go below zero or above one
        if handles.xval<0 | handles.xval>1;return;end
        figure(findobj('Tag','HFO_GUI'));hold on;
        guidata(findobj('Tag','HFO_GUI'),handles)
        handles=plot_data(handles);
        set(findobj('Tag','scrollbarX'),'Value',handles.xval); %update the slider
        guidata(findobj('Tag','HFO_GUI'),handles)
    end %scrollbar function
% Y-Axis editer
uicontrol(findobj('Tag','HFO_GUI'),'Style','edit',...
        'String',num2str(handles.maxAmp),...
        'Position',[40 230 50 40],...
        'Tag',['editYlim'],...
        'Callback',@editYlim,...
        'Visible','on', 'BusyAction','cancel')   
    function editYlim(hObj, eventdata)
        handles=guidata(findobj('Tag','HFO_GUI'));
        handles.maxAmp =str2double(get(hObj,'String')) ;
        guidata(findobj('Tag','HFO_GUI'),handles)
        figure(findobj('Tag','HFO_GUI'))
        handles=plot_data(handles);
    end
% Y-Axis SLIDER
uicontrol(findobj('Tag','HFO_GUI'),'Style','slider',...
        'Min',0.01,'Max',40,'Value',handles.yval1,...
        'SliderStep',[.01 .1],...
        'Position',[20 210 20 100],...
        'Tag',['scrollbarY1'],...
        'Callback',@scrollBarY1,...
        'Visible','on', 'BusyAction','cancel')   
    function scrollBarY1(hObj, eventdata)
        handles=guidata(findobj('Tag','HFO_GUI'));
        handles.yval1 = get(hObj,'Value');
        guidata(findobj('Tag','HFO_GUI'),handles)
        figure(findobj('Tag','HFO_GUI'))
        handles=plot_data(handles);       
    end %scrollbar function
%Jump-To pushbutton
uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton',...
        'String',['Jump-To '],...
        'Position',[12 20 60 30],...
        'Tag',['checkboxcursor'],...
        'Callback',{@pushGOTO},...
        'Visible','on')
% --- Executes on button press in pushGOTO.
function [handles]=pushGOTO(hObj, eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
handles.samp=str2double(get(findobj('Tag','editXpoint'),'String'));
handles.xval=(handles.samp-1)/handles.num_samples;
set(findobj('Tag','scrollbarX'),'Value',handles.xval);
guidata(findobj('Tag','HFO_GUI'),handles)
handles=plot_data(handles);
end %noise checkbox function
%Xpointedit
uicontrol(findobj('Tag','HFO_GUI'),'Style','edit',...
        'String',[''],...
        'Position',[12 55 75 30],...
        'Tag',['editXpoint'],...
        'Callback',{},...
        'Visible','on')
%CURSOR
uicontrol(findobj('Tag','HFO_GUI'),'Style','checkbox',...
        'String','CURSOR',...
        'Position',[12 90 75 30],...
        'Tag',['radioCursor'],...
        'Callback',{@onCursor},...
        'Visible','on','Value',0)
 % --- Executes on button press in pushGOTO.
function onCursor(hObj, eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
    if get(hObj,'Value')==1
    set(findobj('Tag','HFO_GUI'),'WindowButtonDownFcn',@clickA2DPoint); 
    elseif get(hObj,'Value')==0
    set(findobj('Tag','HFO_GUI'),'WindowButtonDownFcn',{});
        try %try to delete any existsing cursor
        delete(handles.lines)
        end
    end
end %cursor checkbox function
uicontrol(findobj('Tag','HFO_GUI'),'Style','edit',...
        'String',[''],...
        'Position',[12 130 75 30],...
        'Tag',['editCursor'],...
        'Callback',{},...
        'Visible','on')
%%%%%%
%PLOT FREQ
uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton',...
        'String',['T-F PLOT'],...
        'Position',[12 170 75 30],...
        'Tag',['pushTF'],...
        'Callback',{@pushTF},...
        'Visible','on')
function pushTF(hObj, eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
    HFO_EX(handles.data(:,1),handles.cursor_samp,handles.fs);
end %cursor checkbox function
%%%%%%
%PLOT PSD
uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton',...
        'String',['PSD'],...
        'Position',[45 320 35 30],...
        'Tag',['pushPSD'],...
        'Callback',{@pushPSD},...
        'Visible','on')
function pushPSD(hObj, eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
PSD=get_psd(handles.data(:,1),handles.cursor_samp,0,handles.fs/2);
    figure;plot_burnos_psd(PSD);
end %cursor checkbox function
%%%%%%
%PLOT PSDn
uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton',...
        'String',['PSDn'],...
        'Position',[45 285 40 30],...
        'Tag',['pushPSDn'],...
        'Callback',{@pushPSDn},...
        'Visible','on')
function pushPSDn(hObj, eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
PSD=get_psd(handles.data(:,1),handles.cursor_samp,1,handles.fs/2);
   figure; plot_burnos_psd(PSD,'Normalized Power Spectral Density');
end %cursor checkbox function
%%%%%%
% HIGH FILTER EDIT
uicontrol(findobj('Tag','HFO_GUI'),'Style','edit',...
        'String',[num2str(handles.hf)],...
        'Position',[995 285 40 30],...
        'Tag',['editHF'],...
        'Callback',{@editHF},...
        'Visible','on')
function editHF(hObj, eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
handles.hf=str2double(get(hObj,'String'));
handles=filter_data(handles,1);
handles=plot_data(handles);
guidata(findobj('Tag','HFO_GUI'),handles)
end %edit High pass filter
%%%%%%
% BAND PASS FILTER EDIT (LOW)
uicontrol(findobj('Tag','HFO_GUI'),'Style','edit',...
        'String',[num2str(handles.bp)],...
        'Position',[995 145 40 30],...
        'Tag',['editBP'],...
        'Callback',{@editBP},...
        'Visible','on')
function editBP(hObj, eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
handles.bp=str2double(get(hObj,'String'));
handles=filter_data(handles,1);
handles=plot_data(handles);
guidata(findobj('Tag','HFO_GUI'),handles)
end %edit High pass filter
% %  set(findobj('Tag','HFO_GUI'), 'WindowButtonDownFcn', {@clickA2DPoint});
% 
% else
% %     dispMsg('un-checked A');
%     set(findobj('Tag','HFO_GUI'), 'WindowButtonDownFcn', {});
%      set(findobj('Tag','checkboxA'),'BackgroundColor',[0.9412    0.9412    0.9412]);
% end
%%%%%%
% ANN test
uicontrol(findobj('Tag','HFO_GUI'),'Style','pushbutton',...
        'String',['ANN'],...
        'Position',[995 220 45 30],...
        'Tag',['pushANN'],...
        'Callback',{@pushANN},...
        'Visible','on')
function pushANN(hObj, eventdata)
handles=guidata(findobj('Tag','HFO_GUI'));
    %X=HFO_EX(handles.data(:,1),handles.cursor_samp,handles.fs);
    
    hx=handles.data(handles.cursor_samp-handles.fs/2:handles.cursor_samp+handles.fs/2-1)';
    [X,~]=featex_hybrid([round(numel(hx)/2) round(numel(hx)/2)], hx', [250 499], handles.fs);
    load([fileparts(which('SVNN')) filesep 'ANN_weights.mat'],'W1','W2','b1','b2','allX','y','todosX','todosY','features'); %loads the last saved SVNN (W1,W2,b1,b2)
    todosX(end+1,:)=X(1,1:size(todosX,2));
    redX=todosX(:,features);
    [stdX]=standardize_features(redX,3,1);
    [acc,estimated]=sim_NN(W1,W2,b1,b2,stdX(end,:)',1);
    disp(num2str(estimated));
    set(findobj('Tag','editANN'),'String',num2str(estimated));
guidata(findobj('Tag','HFO_GUI'),handles)
end %edit High pass filter
%%
% ANN edit field display
uicontrol(findobj('Tag','HFO_GUI'),'Style','edit',...
        'String',[],...
        'Position',[995 185 55 30],...
        'Tag',['editANN'],...
        'Callback',{},...
        'Visible','on')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
guidata(findobj('Tag','HFO_GUI'),handles)


end

