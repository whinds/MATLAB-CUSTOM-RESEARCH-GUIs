function acorel_GUI(subject)
%
%
%%%%%%%
% GUI %
%%%%%%%
%
if ~exist('subject','var');subject='';end
%Initialize figure and gui data structure
h=figure;set(h,'Position',[100 100 500 550],'Tag','MAIN_GUI','Name','ACOREL');
g=figure;hold on;set(g,'Position',[800 100 600 600],'Tag','MAIN_GRAPH');
set(findobj('Tag','MAIN_GRAPH'),'Visible','off');
main_gui=guidata(findobj('Tag','MAIN_GUI')); %updates the GUI data variable
str=which('acorel.m');
main_gui.home_dir=str(1:end-8);
    
%retrieve path info
[ main_gui.pathstring,main_gui.listings ] = get_sub_dir();
main_gui.names=cell(1,length(main_gui.listings)-2);
main_gui.subs(1:length(main_gui.listings)-2)={main_gui.listings(3:end).name}; %the first two indices contain blank spaces
[main_gui.pop_string]=makePopMenu(main_gui.subs);
%make popupmenu string
function [pop_string]=makePopMenu(listings)
        %listings are the output of a file directory query on pathstring
        pop_string=' ';
        if ~isempty(listings)
        for s=1:length(listings)
            pop_string=[pop_string '|' listings{s}];
        end
        end
end
main_gui.coords=[];main_gui.names=[]; %for trode type
main_gui.strip_names={};main_gui.depth_names={};main_gui.grid_names={};
main_gui.notrodetype={};
function [main_gui]=makeTrodetypes(subject)
    main_gui=guidata(findobj('Tag','MAIN_GUI'));
    main_gui.subject=subject;main_gui.names={};main_gui.coords=[];main_gui.notrodetype={};main_gui.trodenames={};
        %make electrode type popup strings if the coordinates are available
        main_gui.fnames=acorel(subject,0);
    try
        [main_gui.coords,main_gui.names]=read_coords(main_gui.fnames.ras_master);
    end
  main_gui.strip_names={};main_gui.depth_names={};main_gui.grid_names={};guidata(findobj('Tag','MAIN_GUI'),main_gui);
    if isempty(main_gui.names);resetTypes(main_gui);return;end
        
        %seperate into just the trode family names
        just_letters={};
        for n=1:numel(main_gui.names)
        just_letters{n}=main_gui.names{n}(1:sum(isstrprop(main_gui.names{n}, 'alpha')));
        end
        [main_gui.trodenames,~,~]=unique(just_letters);
        try %see if trodetypes exists
            [main_gui.strip_names,main_gui.depth_names,main_gui.grid_names]=read_trodetypes(main_gui.fnames.trodetype);
        end
        
            main_gui.notrodetype=main_gui.trodenames(...
                ~ismember(main_gui.trodenames,[main_gui.strip_names,main_gui.depth_names,main_gui.grid_names]));
            
            guidata(findobj('Tag','MAIN_GUI'),main_gui);
            resetTypes(main_gui);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   GUI DESIGN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MESSAGE TEXT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
        'Position',[12 290 105 20],...
        'String','Message Display: ','FontWeight','bold')
%MESSAGE EDIT box
uicontrol(findobj('Tag','MAIN_GUI'),'Style','edit',...
        'String',[],'FontWeight','bold',...
        'Position',[12 220 476 70],...
        'Tag',['editMessage'],...
        'Callback',{},...
        'Visible','on')
 %DISPLAYS MESSAGES on GUI
function dispMsg(msgStr)
set(findobj(findobj('Tag','MAIN_GUI'),'Tag','editMessage'),'String',msgStr); %update a field on the gui
end %display message function   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%SUBJECT TEXT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
        'Position',[6 505 83 35],...
        'String','SUBJECT','FontWeight','bold','FontSize',13)
%SUBJECT popupmenu
uicontrol(findobj('Tag','MAIN_GUI'),'Style','popupmenu',...
        'String',main_gui.pop_string,'FontWeight','bold',...
        'Position',[9 485 99 20],...
        'Tag',['popupmenu_Subject'],...
        'Callback',{@popupmenu_Subject},...
        'Visible','on')
function [main_gui]=popupmenu_Subject(hObj,eventdata)
val = get(hObj,'Value'); %update a field on the gui
pop_string = get(hObj,'String');
main_gui=guidata(findobj('Tag','MAIN_GUI'));
main_gui.subject=main_gui.subs{val-1};
main_gui.fnames=acorel(main_gui.subject,0);
main_gui=makeTrodetypes(main_gui.subject);
coordsCheck(main_gui);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
resetTypes(main_gui);
dispMsg(['Selected subject ' main_gui.subject]);
%%% coordinate info
end %subject popupmenu function  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%PLOT CT BUTTON
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'String',['PLOT CT ARTS'],'FontWeight','bold',...
        'Position',[12 420 100 30],...
        'Tag',['pushbuttonCTplot'],...
        'Callback',{@pushbuttonCTplot},...
        'Visible','on','ForegroundColor',[1 0 0])
% --- Executes on button press in pushbuttonNoise.
function [main_gui]=pushbuttonCTplot(hObj, eventdata)
 main_gui=guidata(findobj('Tag','MAIN_GUI'));
  if ~isfield(main_gui,'subject')|isempty(main_gui.subject)
        dispMsg('SELECT SUBJECT FIRST');return;
  end;
 try
    set(findobj('Tag','MAIN_GRAPH'),'Visible','on');
    figure(findobj('Tag','MAIN_GRAPH'));
 catch
     g=figure;set(g,'Position',[800 100 600 600],'Tag','MAIN_GRAPH');
 end
 hold on;
[main_gui.ct_ras]=ct2surf(main_gui.fnames.CT_nii,main_gui.fnames.xfm);
main_gui.ct_arts=plotE(main_gui.ct_ras,'k.',5);
hold off;
guidata(findobj('Tag','MAIN_GUI'),main_gui);
dispMsg(['Plotted CT artifacts ']);
end %plot CT button function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PLOT MRI BUTTON
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'String',['PLOT MRI ARTS'],'FontWeight','bold',...
        'Position',[12 380 100 30],...
        'Tag',['pushbuttonMRplot'],...
        'Callback',{@pushbuttonMRplot},...
        'Visible','on','ForegroundColor',[0 0 1])
% --- Executes on button press in pushbuttonNoise.
function [main_gui]=pushbuttonMRplot(hObj, eventdata)
 main_gui=guidata(findobj('Tag','MAIN_GUI'));
 try
    set(findobj('Tag','MAIN_GRAPH'),'Visible','on');
    figure(findobj('Tag','MAIN_GRAPH'));
 catch
     g=figure;set(g,'Position',[800 100 600 600],'Tag','MAIN_GRAPH');
 end
 hold on;
mri_neg=MRIread(main_gui.fnames.post); %freesurfer program to read the volume file
if isempty(mri_neg);error('POST-MRI ARIFACTS NOT FOUND!');end
mri_vox=mri_binarize(mri_neg,1); %use 1 because it is pre-binarized
main_gui.mri_points=vox2labelxyz(mri_vox,mri_neg.tkrvox2ras); %convert from vox -> RAS
%view it to see if there are any large artifacts. If so, go back to FS!
main_gui.mri_arts=plotE(main_gui.mri_points,'b.',6);
hold off;
guidata(findobj('Tag','MAIN_GUI'),main_gui);
dispMsg(['Plotted MRI artifacts ']);
end %plot MRI button function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%POST-PROC BUTTON
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'String',['LABEL-CONTACTS'],'FontWeight','bold',...
        'Position',[225 470 110 30],...
        'Tag',['pushbuttonPostproc'],...
        'Callback',{@pushbuttonPostproc},...
        'Visible','on','ForegroundColor',[.1 .75 .5])
% --- Executes on button press in pushbuttonNoise.
function pushbuttonPostproc(hObj, eventdata)
  dispMsg('POST-PROCESSING: LABEL THE CONTACTS WITH THE JACKSHEET NAMES');
    main_gui=guidata(findobj('Tag','MAIN_GUI'));
    if isfield(main_gui,'subject')&~isempty(main_gui.subject)
    postprocPOST(main_gui.subject)
    else
        dispMsg('SELECT SUBJECT FIRST');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%YANG BUTTON
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
          'String',['GRID'],'FontWeight','bold',...
          'Position',[350 470 70 30],...
          'Tag',['pushbuttonYang'],...
          'Callback',{@pushbuttonYang},...
          'Visible','on','ForegroundColor',[.1 .75 .5],'FontSize',10)
% --- Executes on button press in pushbuttonYang.
function main_gui=pushbuttonYang(hObj, eventdata)
dispMsg('POST-PROCESSING: GRID INTERPOLATION W/ POST-IMPLANT MRI');
main_gui=guidata(findobj('Tag','MAIN_GUI'));
if ~isfield(main_gui,'subject');dispMsg('MUST SELECT A SUBJECT');return;end
yang_gui(main_gui.subject);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%AUTOLOC BUTTON
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'String',['1. AUTO-LOC'],'FontWeight','bold',...
        'Position',[112 470 100 50],...
        'Tag',['pushbuttonAutoloc'],...
        'Callback',{@pushbuttonAutoloc},...
        'Visible','on','ForegroundColor',[1 0 0])
% --- Executes on button press in pushbuttonNoise.
function [main_gui]=pushbuttonAutoloc(hObj, eventdata)
  dispMsg('BUSY: Auto-detecting... (may take up to a minute)...');
    main_gui=guidata(findobj('Tag','MAIN_GUI'));
acorel(main_gui.subject,1);
 
        %%%%%%%%
        dispMsg('Auto-detected new E-points');

    %end
end %Autoloc button function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%CHANGE SUBJECT DIR PUSHBUTTON
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'Position',[390 520 125 35],...
        'String','CHOOSE DIR.','FontWeight','bold',...
        'Tag','pushbutton_SubDir',...
        'Callback',{@pushbutton_SubDir},...
        'Visible','on');
function [main_gui]=pushbutton_SubDir(hObj,eventdata)
    
main_gui=guidata(findobj('Tag','MAIN_GUI'));
delete([main_gui.home_dir 'subjects_path.txt'])
[main_gui.pathstring,main_gui.listings]=get_sub_dir();
set(findobj('Tag','edit_SubjectDir'),'String',main_gui.pathstring);
main_gui.subs={main_gui.listings(3:end).name};
[main_gui.pop_string]=makePopMenu({main_gui.listings(3:end).name});
set(findobj('Tag','popupmenu_Subject'),'String',main_gui.pop_string);
dispMsg(['Selected NEW Subject Directory']);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
end %subject popupmenu function   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SUBJECT DIRECTORY EDIT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','edit',...
        'String',main_gui.pathstring,'FontWeight','bold',...
        'Position',[95 520 300 35],...
        'Tag',['edit_SubjectDir'],...
        'Callback',{@edit_SubjectDir},...
        'Visible','on')
function [main_gui]=edit_SubjectDir(hObj,eventdata)
main_gui.path_string = get(hObj,'String');
if ~exist(path_string,'dir');
    dispMsg([path_string ': Does not exist']);
    %call pushbutton function
    [ main_gui.pathstring,main_gui.listings ] = get_sub_dir();
end
main_gui.subs={main_gui.listings(3:end).name};
[main_gui.pop_string]=makePopMenu({main_gui.listings(3:end).name});
set(findobj('Tag','popupmenu_Subject'),'String',main_gui.pop_string);
main_gui=guidata(findobj('Tag','MAIN_GUI'));
end %subject directory function   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
%         'String','pre-process','FontWeight','bold',...
%         'Position',[5 0 90 15],'ForegroundColor',[1 1 0],...
%         'BackgroundColor',[1 0 0])
%MAKE SMOOTH BUTTON
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'String','SMOOTH','FontWeight','bold',...
        'Position',[5 450 60 28],...
        'Tag',['pushbuttonSmooth'],...
        'Callback',{@pushbuttonSmooth},...
        'Visible','on','ForegroundColor',[.8 .4 0])
function [main_gui]=pushbuttonSmooth(hObj, eventdata)
 main_gui=guidata(findobj('Tag','MAIN_GUI'));
 dispMsg(['MAKING FILLED HEMISPHERE SURFACES...']);
 try
make_outer_surface(main_gui.fnames.lh_pial_vol,15,main_gui.fnames.lh_filled_surf);
make_outer_surface(main_gui.fnames.rh_pial_vol,15,main_gui.fnames.rh_filled_surf);
    try
    make_outer_surface(main_gui.fnames.filled,15,main_gui.fnames.filled_surf);
    end
guidata(findobj('Tag','MAIN_GUI'),main_gui);
dispMsg(sprintf('MADE FILLED HEMISPHERE SURFACES; NOW RUN SMOOTH SCRIPT IN FREESURFER'));
 catch
     dispMsg(['filled hemispheres not found!!'])
 end
end %plot MRI button function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%AUTOREG BUTTON
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'String','2. AUTO-REG-ICP','FontWeight','bold',...
        'Position',[315 375 115 40],...
        'Tag',['pushbuttonREG'],...
        'Callback',{@pushbuttonREG},...
        'Visible','on','ForegroundColor',[0 0 1],'FontSize',8)
function [main_gui]=pushbuttonREG(hObj, eventdata)
 main_gui=guidata(findobj('Tag','MAIN_GUI'));
 dispMsg(['AUTO-REGISTRATION CORRECTION...']);
 try
autoreg_icp(main_gui.subject,main_gui.Rtoler,main_gui.Ltoler);
%guidata(findobj('Tag','MAIN_GUI'),main_gui);
dispMsg(['AUTOMATICALLY CORRECTED REGISTRATION!']);
 catch
     dispMsg(['ERROR: AUTO-REG FAILED!!'])
 end
end %autoreg button function
main_gui.Rtoler=.1; %default tolerance
uicontrol(findobj('Tag','MAIN_GUI'),'Style','edit',...
        'String',num2str(main_gui.Rtoler),'FontWeight','bold',...
        'Position',[435 372 35 30],...
        'Tag',['editRToler'],...
        'Callback',{@editRToler},...
        'Visible','on','ForegroundColor',[0 0 1],'FontSize',8)
function [main_gui]=editRToler(hObj, eventdata)
 main_gui=guidata(findobj('Tag','MAIN_GUI'));
  main_gui.Rtoler=str2double(get(findobj('Tag','editRToler'),'String'));
  guidata(findobj('Tag','MAIN_GUI'),main_gui);
 dispMsg(['Changed right hemi minimum tolerance for auto-reg...']);
end %autoreg button function
main_gui.Ltoler=.1; %default tolerance
uicontrol(findobj('Tag','MAIN_GUI'),'Style','edit',...
        'String',num2str(main_gui.Ltoler),'FontWeight','bold',...
        'Position',[435 403 35 30],...
        'Tag',['editLToler'],...
        'Callback',{@editLToler},...
        'Visible','on','ForegroundColor',[1 0 0],'FontSize',8)
function [main_gui]=editLToler(hObj, eventdata)
 main_gui=guidata(findobj('Tag','MAIN_GUI'));
  main_gui.Ltoler=str2double(get(findobj('Tag','editLToler'),'String'));
  guidata(findobj('Tag','MAIN_GUI'),main_gui);
 dispMsg(['Changed left hemi minimum tolerance for auto-reg...']);
end %autoreg button function
% ADD TEXT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text','String','L','FontWeight','bold','Position',[471 403 12 25],'Visible','on','FontSize',8)
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text','String','R','FontWeight','bold','Position',[471 372 12 25],'Visible','on','FontSize',8)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%STRIPS LISTBOX
%STRPS TEXT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
        'Position',[122 180 90 25],...
        'String','STRIPS','FontWeight','bold')
%STRPS TEXT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
        'Position',[122 15 90 140],'Tag','editStrips',...
        'String',main_gui.strip_names,'FontWeight','bold')
%STRIPS popupmenu
uicontrol(findobj('Tag','MAIN_GUI'),'Style','popupmenu',...
        'String',makePopMenu(main_gui.notrodetype),'FontWeight','bold',...
        'Position',[122 160 90 25],...
        'Tag',['popupmenu_Strips'],...
        'Callback',{@popupmenu_STRIPS},...
        'Visible','on')
function [main_gui]=popupmenu_STRIPS(hObj,eventdata)
val = get(hObj,'Value'); %update a field on the gui
if val==1;return;end
pop_string = get(hObj,'String');

main_gui=guidata(findobj('Tag','MAIN_GUI'));
main_gui.strip_names(end+1)=main_gui.notrodetype(val-1);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
write_trodetypes(main_gui.fnames.trodetype,main_gui.strip_names,...
    main_gui.depth_names,main_gui.grid_names);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
main_gui=makeTrodetypes(main_gui.subject);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
resetTypes(main_gui);
dispMsg(['LABELED ' main_gui.strip_names{end} ' -> STRIP']);
end %strips popupmenu function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%DEPTHS LISTBOX
%STRPS TEXT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
        'Position',[222 180 90 25],...
        'String','DEPTHS','FontWeight','bold')
%STRPS TEXT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
        'Position',[222 15 90 140],'Tag','editDepths',...
        'String',main_gui.depth_names,'FontWeight','bold')
%DEPTHS popupmenu
uicontrol(findobj('Tag','MAIN_GUI'),'Style','popupmenu',...
        'String',makePopMenu(main_gui.notrodetype),'FontWeight','bold',...
        'Position',[222 160 90 25],...
        'Tag',['popupmenu_Depths'],...
        'Callback',{@popupmenu_DEPTHS},...
        'Visible','on')
function [main_gui]=popupmenu_DEPTHS(hObj,eventdata)
val = get(hObj,'Value'); %update a field on the gui
pop_string = get(hObj,'String');
if val==1;return;end
main_gui=guidata(findobj('Tag','MAIN_GUI'));
main_gui.depth_names(end+1)=main_gui.notrodetype(val-1);
write_trodetypes(main_gui.fnames.trodetype,main_gui.strip_names,...
    main_gui.depth_names,main_gui.grid_names);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
main_gui=makeTrodetypes(main_gui.subject);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
resetTypes(main_gui);
dispMsg(['LABELED ' main_gui.depth_names{end} ' -> DEPTH']);
end %depth popupmenu function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%gridS LISTBOX
%STRPS TEXT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
        'Position',[322 180 90 25],...
        'String','GRIDS','FontWeight','bold')
%STRPS TEXT
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
        'Position',[322 15 90 140],'Tag','editGrids',...
        'String',main_gui.grid_names,'FontWeight','bold')
%DEPTHS popupmenu
uicontrol(findobj('Tag','MAIN_GUI'),'Style','popupmenu',...
        'String',makePopMenu(main_gui.notrodetype),'FontWeight','bold',...
        'Position',[322 160 90 25],...
        'Tag',['popupmenu_Grids'],...
        'Callback',{@popupmenu_GRIDS},...
        'Visible','on')
function [main_gui]=popupmenu_GRIDS(hObj,eventdata)
val = get(hObj,'Value'); %update a field on the gui
pop_string = get(hObj,'String');
if val==1;return;end
main_gui=guidata(findobj('Tag','MAIN_GUI'));
main_gui.grid_names(end+1)=main_gui.notrodetype(val-1);
write_trodetypes(main_gui.fnames.trodetype,main_gui.strip_names,...
    main_gui.depth_names,main_gui.grid_names);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
main_gui=makeTrodetypes(main_gui.subject);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
resetTypes(main_gui);
dispMsg(['LABELED ' main_gui.grid_names{end} ' -> GRID']);
end %depth popupmenu function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol(findobj('Tag','MAIN_GUI'),'Style','text',...
        'String','3. Electrode Type ->','FontWeight','bold',...
        'Position',[1 182 120 30],'fontsize',10)
%clear trode types
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'String','CLEAR TYPES','FontWeight','bold',...
        'Position',[5 140 85 25],...
        'Tag',['clearTypes'],...
        'Callback',{@clearTypes},...
        'Visible','on')
function [main_gui]=clearTypes(hObj,eventdata)
    main_gui=guidata(findobj('Tag','MAIN_GUI'));
    if ~isfield(main_gui,'subject');return;end
fclose('all');delete(main_gui.fnames.trodetype);

    main_gui=makeTrodetypes(main_gui.subject);
guidata(findobj('Tag','MAIN_GUI'),main_gui);
resetTypes(main_gui);
dispMsg(['CLEARED TRODE TYPES']);
end
    function resetTypes(main_gui)
        set(findobj('Tag','editStrips'),'String',main_gui.strip_names);
        set(findobj('Tag','popupmenu_Strips'),'String',makePopMenu(main_gui.notrodetype),'Val',1);
        set(findobj('Tag','editDepths'),'String',main_gui.depth_names);
        set(findobj('Tag','popupmenu_Depths'),'String',makePopMenu(main_gui.notrodetype),'Val',1);
        set(findobj('Tag','editGrids'),'String',main_gui.grid_names);
        set(findobj('Tag','popupmenu_Grids'),'String',makePopMenu(main_gui.notrodetype),'Val',1);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Surface Projection
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'String','4. SURF PROJECT','FontWeight','bold',...
        'Position',[12 320 105 40],...
        'Tag',['surfProj'],...
        'Callback',{@surfProj},...
        'Visible','on','ForegroundColor',[1 0 0],...
        'BackgroundColor',[1 1 .8])
function [main_gui]=surfProj(hObj,eventdata)
    main_gui=guidata(findobj('Tag','MAIN_GUI'));
    if ~isfield(main_gui,'subject');return;end
    try %first with the post-mri corrected coordinates if available
[ all_surf_coords,orig_coords,orig_names ] = subTrode_projection( main_gui.subject,'post');
disp('using post-corrected coordinates');
    catch %then use the 
        try
        [ all_surf_coords,orig_coords,orig_names ] = subTrode_projection( main_gui.subject,'gras');
        disp('using SPM coregistered CT-MR coordinates (non-POST-corrected)');
        catch
        [ all_surf_coords,orig_coords,orig_names ] = subTrode_projection( main_gui.subject,'pre');
        disp('using pre-existing CT-MR coordinates (non-corrected)');
        end
    end


guidata(findobj('Tag','MAIN_GUI'),main_gui);
dispMsg(['SURFACE PROJECTION CALCULATED']);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%COORDS CHECK
uicontrol(findobj('Tag','MAIN_GUI'),'Style','radiobutton','Enable','off',...
        'String','A. CT2MRI','FontWeight','bold',...
        'Position',[120 430 90 30],'Tag',['ct2mrbut'],'Visible','on','Value',0)
uicontrol(findobj('Tag','MAIN_GUI'),'Style','radiobutton','Enable','off',...
        'String','B. RAS','FontWeight','bold',...
        'Position',[240 430 80 30],'Tag',['rasbut'],'Visible','on','Value',0)
    uicontrol(findobj('Tag','MAIN_GUI'),'Style','radiobutton','Enable','off',...
        'String','C. PRE2POST','FontWeight','bold',...
        'Position',[120 385 90 30],'Tag',['p2pbut'],'Visible','on','Value',0)
    uicontrol(findobj('Tag','MAIN_GUI'),'Style','radiobutton','Enable','off',...
        'String','D. POST','FontWeight','bold',...
        'Position',[240 385 75 30],'Tag',['postbut'],'Visible','on','Value',0)
uicontrol(findobj('Tag','MAIN_GUI'),'Style','radiobutton','Enable','off',...
        'String','E. SURF','FontWeight','bold',...
        'Position',[122 330 90 30],'Tag',['surfbut'],'Visible','on','Value',0)
uicontrol(findobj('Tag','MAIN_GUI'),'Style','radiobutton','Enable','off',...
        'String','F. MNI','FontWeight','bold',...
        'Position',[240 330 80 30],'Tag',['mnibut'],'Visible','on','Value',0)
    uicontrol(findobj('Tag','MAIN_GUI'),'Style','radiobutton','Enable','off',...
        'String','','FontWeight','bold',...
        'Position',[70 450 25 30],'Tag',['smoothbut'],'Visible','on','Value',0) %smooth
    uicontrol(findobj('Tag','MAIN_GUI'),'Style','radiobutton','Enable','off',...
        'String','Yang','FontWeight','bold',...
        'Position',[430 466 80 30],'Tag',['yangbut'],'Visible','on','Value',0)
uicontrol(findobj('Tag','MAIN_GUI'),'Style','radiobutton','Enable','off',...
        'String','F. S-MNI','FontWeight','bold',...
        'Position',[330 330 80 30],'Tag',['smnibut'],'Visible','on','Value',0)
function [main_gui]=coordsCheck(main_gui)
    main_gui=guidata(findobj('Tag','MAIN_GUI'));
    if ~isfield(main_gui,'subject');return;end
    %%%%%%%
    %
    set(findobj('Tag','ct2mrbut'),'Value',0);if exist(main_gui.fnames.xfm);set(findobj('Tag','ct2mrbut'),'Value',1);end
    set(findobj('Tag','rasbut'),'Value',0); if exist(main_gui.fnames.ras_master);set(findobj('Tag','rasbut'),'Value',1);end
    set(findobj('Tag','p2pbut'),'Value',0);if exist(main_gui.fnames.Preg)|exist(main_gui.fnames.Preg);set(findobj('Tag','p2pbut'),'Value',1);end
    set(findobj('Tag','postbut'),'Value',0);if exist(main_gui.fnames.post_master);set(findobj('Tag','postbut'),'Value',1);end
    set(findobj('Tag','surfbut'),'Value',0);if exist(main_gui.fnames.surf_master);set(findobj('Tag','surfbut'),'Value',1);end
    set(findobj('Tag','mnibut'),'Value',0);if exist(main_gui.fnames.mni_master);set(findobj('Tag','mnibut'),'Value',1);end
    set(findobj('Tag','smoothbut'),'Value',0);if exist(main_gui.fnames.filled_smooth);set(findobj('Tag','smoothbut'),'Value',1);end
    set(findobj('Tag','yangbut'),'Value',0);if exist(main_gui.fnames.yang);set(findobj('Tag','yangbut'),'Value',1);end
    set(findobj('Tag','smnibut'),'Value',0);if exist(main_gui.fnames.smni);set(findobj('Tag','smnibut'),'Value',1);end
guidata(findobj('Tag','MAIN_GUI'),main_gui);
%dispMsg(['']);
end
coordsCheck(main_gui);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MNI Volume
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton','String','5. MNI Affine','FontWeight','bold',...
        'Position',[215 300 115 35],'Tag',['mniNorm'],'Callback',{@mniNorm},...
        'Visible','on','ForegroundColor',[.5 .5 .5],'BackgroundColor',[1 1 .8])
function [main_gui]=mniNorm(hObj,eventdata)
    main_gui=guidata(findobj('Tag','MAIN_GUI'));
    if ~isfield(main_gui,'subject');return;end
   %CALCULATE MNI COORDS AND SAVE THEM
   try
       [coords,names]=read_coords(main_gui.fnames.surf_master);
        [mni_coords]=ras2mni(coords,main_gui.subject);
        write_coords(mni_coords,names,main_gui.fnames.mni_master)
        dispMsg(['MNI coords CALCULATED']);
   catch
       disp('no surface coords')
       dispMsg(['error']);
   end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MNI Surface
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton','String','6. MNI Surface','FontWeight','bold',...
        'Position',[330 300 115 35],'Tag',['mniSurf'],'Callback',{@mniSurf},...
        'Visible','on','ForegroundColor',[.5 .5 .5],'BackgroundColor',[1 1 .8])
function [main_gui]=mniSurf(hObj,eventdata)
    main_gui=guidata(findobj('Tag','MAIN_GUI'));
    if ~isfield(main_gui,'subject');return;end
   %CALCULATE MNI COORDS AND SAVE THEM
   try
       [reg_coords,reg_names]=mni_surf_reg(main_gui.subject);
        write_coords(reg_coords,reg_names,main_gui.fnames.smni)
        dispMsg(['MNI coords CALCULATED']);
   catch
       disp('no surface coords or missing fsaverage')
       dispMsg(['error']);
   end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
        'String','PLOT GUI','FontWeight','bold',...
        'Position',[5 5 80 40],...
        'Tag',['plotGUI'],...
        'Callback',{@pushplotGUI},...
        'Visible','on','ForegroundColor',[1 1 .8],...
        'BackgroundColor',[1 0 0])
function pushplotGUI(hObj, eventdata)
  dispMsg('PLOT GUI started');
    main_gui=guidata(findobj('Tag','MAIN_GUI'));
    if isfield(main_gui,'subject')&~isempty(main_gui.subject)
        plotGUI(main_gui.subject);
    else
        dispMsg('SELECT SUBJECT FIRST');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% uicontrol(findobj('Tag','MAIN_GUI'),'Style','pushbutton',...
%         'String','TRODE GUI','FontWeight','bold',...
%         'Position',[5 45 80 40],...
%         'Tag',['trodeGUI'],...
%         'Callback',{@pushtrodeGUI},...
%         'Visible','on','ForegroundColor',[1 1 .8],...
%         'BackgroundColor',[0 0 1])
% function pushtrodeGUI(hObj, eventdata)
%   dispMsg('TRODE GUI started');
%     main_gui=guidata(findobj('Tag','MAIN_GUI'));
%     if isfield(main_gui,'subject')&~isempty(main_gui.subject)
%         trodeGUI(main_gui.subject);
%     else
%         dispMsg('SELECT SUBJECT FIRST');
%     end
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
guidata(findobj('Tag','MAIN_GUI'),main_gui);
end%main postproc function