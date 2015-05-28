function varargout = configCamera(varargin)
% CONFIGCAMERA MATLAB code for configCamera.fig
%      CONFIGCAMERA, by itself, creates a new CONFIGCAMERA or raises the existing
%      singleton*.
%
%      H = CONFIGCAMERA returns the handle to a new CONFIGCAMERA or the handle to
%      the existing singleton*.
%
%      CONFIGCAMERA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONFIGCAMERA.M with the given input arguments.
%
%      CONFIGCAMERA('Property','Value',...) creates a new CONFIGCAMERA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before configCamera_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to configCamera_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help configCamera

% Last Modified by GUIDE v2.5 01-Apr-2014 13:18:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @configCamera_OpeningFcn, ...
                   'gui_OutputFcn',  @configCamera_OutputFcn, ...
                   'gui_LayoutFcn',  @configCamera_LayoutFcn, ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before configCamera is made visible.
function configCamera_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to configCamera (see VARARGIN)

% Choose default command line output for configCamera
handles.output = hObject;

guidata(hObject,handles);

fpath = which('configCamera');
fpath = fpath(1:end-14);
handles.fpath = fpath;
nConfig = dir([fpath,'neuroPG.config']);
cConfig = dir([fpath,'camera*.config']);
if numel(nConfig) > 0
    handles.fname = 'neuroPG.config';
    settings = load([fpath,fname],'-mat');
    if numel(varargin) > 0 && varargin{1} == 1
        copyfile([fpath,'neuroPG.config'],[fpath,'neuroPG.config','.bak']);
    end
elseif numel(cConfig) > 0
    handles.fname = 'camera.config';
    resp = questdlg('Import Settings from current file?','CameraWindow config', ...
        'Yes','No','New Camera','Yes');
    if strcmp(resp,'Yes')
        if numel(cConfig) > 1
            numCam = numel(cConfig);
            list = {cConfig(:).name};
            [sel,ok] = listdlg('Name','CameraWindow config','PromptString', ...
                'Select a camera','ListString',list,'SelectionMode','single', ...
                'ListSize',[300,15*numCam]);
            if ok == 1
                handles.fname = cConfig(sel).name;
            end
        end
        settings = load([handles.fpath,handles.fname],'-mat');
    else
        settings = [];
        if strcmp(resp,'New Camera')
            handles.newCamera = 1;
        end
    end
    if numel(varargin) > 0 && varargin{1} == 1
        copyfile([fpath,'camera.config'],[fpath,'camera.config','.bak']);
    end
else
    settings = [];
    handles.fname = 'camera.config';
end

handles.settings = settings;

% Find and identify available cameras
resp = questdlg('Reset IMAQ to detect new cameras?','CameraWindow','No');
if isempty(resp) || strcmp('Cancel',resp)
    return;
elseif strcmp('Yes',resp)
    imaqreset;
end
hwinfo = imaqhwinfo;
for i = 1:numel(hwinfo.InstalledAdaptors)
    adaptors{i} = imaqhwinfo(hwinfo.InstalledAdaptors{i});  %#ok<*AGROW>
end
count = 0;
for i = 1:numel(adaptors)
    if ~isempty(adaptors{i}.DeviceIDs)
        for j = 1:numel(adaptors{i}.DeviceIDs)
            count = count + 1;
            available{count,1} = adaptors{i}.AdaptorName;
            available{count,2} = adaptors{i}.DeviceIDs{j};
            available{count,3} = imaqhwinfo(available{count,1},available{count,2});
        end
    end
end

if count == 0
    set(handles.CamerasBox,'String','No Cameras Detected');
else
    handles.available = available;
    for i = 1:count
        names{i} = available{i,3}.DeviceName; 
    end
    set(handles.CamerasBox,'String',names);
    % Change this section to display previous settings
    if isstruct(settings) && isfield(settings,'cameraName')
        if any(strcmp(settings.cameraName,names))
            ind = find(strcmp(settings.cameraName,names));
            camera = available(ind,:);
            set(handles.CamerasBox,'Value',ind);
            handles.camera = camera;
        else
            camera = available(1,:);
            handles.camera = camera;
        end
    else
        camera = available(1,:);
        handles.camera = camera;
    end
%     camera = available(1,:);
%     handles.camera = camera;
    set(handles.AdaptorText,'String',camera{1});
    handles.settings.adaptor = camera{1};
    set(handles.IDText,'String',num2str(camera{2}));
    handles.settings.deviceID = camera{2};
    set(handles.FormatsBox,'String',camera{3}.SupportedFormats,'Value',[]);
    if isfield(handles.settings,'format') && any(strcmp(settings.format, ...
            camera{3}.SupportedFormats))
        ind = find(strcmp(settings.format,camera{3}.SupportedFormats));
        set(handles.FormatsBox,'Value',ind);
        set(handles.FormatText,'String',settings.format)
        try
            vid = videoinput(camera{1},camera{2},settings.format);
        catch
            guidata(hObject,handles);
            warndlg('Camera intialization failed: disconnected or in use', ...
                'CameraWindow config Error');
            return;
        end
        handles.vid = vid;
        src = getselectedsource(vid);
        handles.src = src;
        properties = set(src);
        propnames = fieldnames(properties);
        set(handles.PropertiesBox,'Value',1,'String',propnames);
    end
    if isfield(handles.settings,'exposureProperty')
        set(handles.ExpT,'String',settings.exposureProperty);
        set(handles.FPT,'Enable','on');
        set(handles.FCT,'Enable','on');
    end
    if isfield(handles.settings,'fluorescentCapture')
        set(handles.FCT,'String',num2str(settings.fluorescentCapture));
    end
    if isfield(handles.settings,'fluorescentExposure')
        set(handles.FPT,'String',num2str(settings.fluorescentExposure));
    end
    if isfield(handles.settings,'autoExposureProperty')
        set(handles.AutoExpT,'String',settings.autoExposureProperty);
    end
    if isfield(handles.settings,'contrastProperty')
        set(handles.ConT,'String',settings.contrastProperty);
    end
    if isfield(handles.settings,'autoContrastProperty')
        set(handles.AutoConT,'String',settings.autoContrastProperty);
    end
    if isfield(handles.settings,'extProperty')
        set(handles.AdditionalBox,'String',settings.extProperty)
    end
end

uicontrol(handles.output,'Style','Push','Tag','ResetPropsB','Units','characters', ...
    'Position',[96,22,20,1.6923],'String','Reset','Callback',{@ResetProps,handles});

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes configCamera wait for user response (see UIRESUME)
% uiwait(handles.configCamera);


% --- Outputs from this function are returned to the command line.
function varargout = configCamera_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in CamerasBox.
function CamerasBox_Callback(hObject, ~, handles) %#ok<*DEFNU>
val = get(hObject,'Value');
camera = handles.available(val,:);
handles.camera = camera;
set(handles.AdaptorText,'String',camera{1});
handles.settings.adaptor = camera{1};
set(handles.IDText,'String',num2str(camera{2}));
handles.settings.deviceID = camera{2};
set(handles.FormatsBox,'String',camera{3}.SupportedFormats,'Value',[]);
set(handles.PropertiesBox,'String','Properties List','Value',1);
set(handles.FormatText,'String','');
set(handles.RangeT,'String','');
set(handles.TypeT,'String','');
set(handles.ExpT,'String','');
set(handles.AutoExpT,'String','');
set(handles.ConT,'String','');
set(handles.AutoConT,'String','');
set(handles.AdditionalBox,'String','','Value',1);
fields = [];
if isfield(handles.settings,'format')
    fields{end+1} = 'format';
end
if isfield(handles.settings,'exposureProperty')
    fields{end+1} = 'exposureProperty';
end
if isfield(handles.settings,'exposurePropertyRange')
    fields{end+1} = 'exposurePropertyRange';
end
if isfield(handles.settings,'autoExposureProperty')
    fields{end+1} = 'autoExposureProperty';
end
if isfield(handles.settings,'autoExposurePropertyRange')
    fields{end+1} = 'autoExposurePropertyRange';
end
if isfield(handles.settings,'contrastProperty')
    fields{end+1} = 'contrastProperty';
end
if isfield(handles.settings,'contrastPropertyRange')
    fields{end+1} = 'contrastPropertyRange';
end
if isfield(handles.settings,'autoContrastProperty')
    fields{end+1} = 'autoContrastProperty';
end
if isfield(handles.settings,'autoContrastPropertyRange')
    fields{end+1} = 'autoContrastPropertyRange';
end
if isfield(handles.settings,'extProperty')
    fields{end+1} = 'extProperty';
end
if isfield(handles.settings,'extPropertyRange')
    fields{end+1} = 'extPropertyRange';
end
if ~isempty(fields)
    handles.settings = rmfield(handles.settings,fields);
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function CamerasBox_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FormatsBox.
function FormatsBox_Callback(hObject, ~, h)
if ~isfield(h,'camera')
    return;
end
val = get(hObject,'Value');
UD = get(hObject,'UserData');
if isempty(UD) || numel(val) == 1
    set(hObject,'UserData',val)
elseif numel(val) > 1
    val = val(val ~= UD);
    UD = val;
    set(hObject,'Value',val,'UserData',UD)
end
if isfield(h,'vid') && isa(h.vid,'videoinput') && isvalid(h.vid)
    delete(h.vid);
end
format = h.camera{3}.SupportedFormats{val};
h.settings.format = format;
try
    vid = videoinput(h.camera{1},h.camera{2},format);
catch
    warndlg('Camera intialization failed: disconnected or in use', ...
        'CameraWindow config Error');
    return;
end
h.vid = vid;
src = getselectedsource(vid);
h.src = src;
h.settings.resolution = get(vid,'VideoResolution');

properties = set(src);
propnames = fieldnames(properties);
set(h.PropertiesBox,'Value',1,'String',propnames);
set(h.FormatText,'String',format);
set(h.RangeT,'String','Range');
set(h.TypeT,'String','Type');
guidata(hObject,h);


% --- Executes during object creation, after setting all properties.
function FormatsBox_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in PropertiesBox.
function PropertiesBox_Callback(hObject, ~, handles)
val = get(hObject,'Value');
names = get(hObject,'String');
if ischar(names) && strcmp(names,'Properties List')
    return;
end
info = propinfo(handles.src,names{val});
range = info.ConstraintValue;
type = info.Constraint;
type2 = info.Type;
if strcmp(type,'enum')
    ranges = range{1};
    for i = 2:numel(range)
        ranges = [ranges,' ',range{i}];
    end
    set(handles.RangeT,'String',ranges)
else
    set(handles.RangeT,'String',['[',num2str(range),']']);
end
set(handles.TypeT,'String',[type,' ',type2]);


% --- Executes during object creation, after setting all properties.
function PropertiesBox_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ExposureButton.
function ExposureButton_Callback(hObject, ~, handles)
names = get(handles.PropertiesBox,'String');
if ischar(names) && strcmp(names,'Properties List')
    return;
end
val = get(handles.PropertiesBox,'Value');
info = propinfo(handles.src,names{val});
type = info.Constraint;
type2 = info.Type;
range = info.ConstraintValue;
if ~strcmp(type,'enum')
    set(handles.src,names{val},range(1)+.1);
    resp = get(handles.src,names{val});
    if resp == int32(resp)
        range = int32(range(1):range(2));
    end
end
if any(isnan(range)) || any(isinf(range))
    resp = inputdlg({['Min range (reptorted: ',num2str(range(1)),')'], ...
        ['Max range (reptorted: ',num2str(range(2)),')']}, ...
        'CameraWindow range error',[1,50;1,50]);
    if isempty(resp)
        return;
    end
    range = str2double(resp)';
    if any(isnan(range)) || any(isinf(range))
        warning('CameraWindow property range values invalid');
        return;
    end
end
handles.settings.exposureProperty = names{val};
handles.settings.exposurePropertyRange = range;
guidata(hObject,handles);
set(handles.ExpT,'String',names{val});
set([handles.FPT,handles.FCT],'Enable','on');


% --- Executes on button press in AutoExpButton.
function AutoExpButton_Callback(hObject, ~, handles)
names = get(handles.PropertiesBox,'String');
if ischar(names) && strcmp(names,'Properties List')
    return;
end
val = get(handles.PropertiesBox,'Value');
info = propinfo(handles.src,names{val});
type = info.Constraint;
type2 = info.Type;
range = info.ConstraintValue;
if ~strcmp(type,'enum')
    set(handles.src,names{val},range(1)+.1);
    resp = get(handles.src,names{val});
    if resp == int32(resp)
        range = int32(range(1):range(2));
    end
end
handles.settings.autoExposureProperty = names{val};
handles.settings.autoExposurePropertyRange = range;
guidata(hObject,handles);
set(handles.AutoExpT,'String',names{val});


% --- Executes on button press in ContrastButton.
function ContrastButton_Callback(hObject, ~, handles)
names = get(handles.PropertiesBox,'String');
if ischar(names) && strcmp(names,'Properties List')
    return;
end
val = get(handles.PropertiesBox,'Value');
info = propinfo(handles.src,names{val});
type = info.Constraint;
type2 = info.Type;
range = info.ConstraintValue;
if ~strcmp(type,'enum')
    set(handles.src,names{val},range(1)+.1);
    resp = get(handles.src,names{val});
    if resp == int32(resp)
        range = int32(range(1):range(2));
    end
end
handles.settings.contrastProperty = names{val};
handles.settings.contrastPropertyRange = range;
guidata(hObject,handles);
set(handles.ConT,'String',names{val});


% --- Executes on button press in AutoConButton.
function AutoConButton_Callback(hObject, ~, handles)
names = get(handles.PropertiesBox,'String');
if ischar(names) && strcmp(names,'Properties List')
    return;
end
val = get(handles.PropertiesBox,'Value');
info = propinfo(handles.src,names{val});
type = info.Constraint;
type2 = info.Type;
range = info.ConstraintValue;
if ~strcmp(type,'enum')
    set(handles.src,names{val},range(1)+.1);
    resp = get(handles.src,names{val});
    if resp == int32(resp)
        range = int32(range(1):range(2));
    end
end
handles.settings.autoContrastProperty = names{val};
handles.settings.autoContrastPropertyRange = range;
guidata(hObject,handles);
set(handles.AutoConT,'String',names{val});


function ResetProps(obj,~,h)
fields = {'exposureProperty','exposurePropertyRange','autoExposureProperty', ...
    'autoExposurePropertyRange','contrastProperty','contrastPropertyRange', ...
    'autoContrastProperty','autoContrastPropertyRange'};
if ~isfield(h.settings,'autoContrastProperty')
    fields(7:8) = [];
end
if ~isfield(h.settings,'contrastProperty')
    fields(5:6) = [];
end
if ~isfield(h.settings,'autoExposureProperty')
    fields(3:4) = [];
end
if ~isfield(h.settings,'exposureProperty')
    fields(1:2) = [];
end
if ~isempty(fields)
    h.settings = rmfield(h.settings,fields);
end
set(h.ExpT,'String',[]);
set([h.FPT,h.FCT],'Enable','off');
set(h.AutoExpT,'String',[]);
set(h.ConT,'String',[]);
set(h.AutoConT,'String',[]);
guidata(obj,h);


% --- Executes on button press in AddPropButton.
function AddPropButton_Callback(hObject, ~, handles)
names = get(handles.PropertiesBox,'String');
if ischar(names) && strcmp(names,'Properties List')
    return;
end
val = get(handles.PropertiesBox,'Value');
info = propinfo(handles.src,names{val});
type = info.Constraint;
type2 = info.Type;
range = info.ConstraintValue;
if ~strcmp(type,'enum')
    set(handles.src,names{val},range(1)+.1);
    resp = get(handles.src,names{val});
    if resp == int32(resp)
        range = int32(range(1):range(2));
    end
end
list = get(handles.AdditionalBox,'String');
if isempty(list)
    count = 1;
    list = names(val);
elseif ischar(list)
    count = 2;
    list = {list,names{val}};
else
    count = numel(list) + 1;
    list{end+1} = names{val};
end
handles.settings.extProperty{count} = names{val};
handles.settings.extPropertyRange{count} = range;
guidata(hObject,handles);
set(handles.AdditionalBox,'String',list);


% --- Executes on selection change in AdditionalBox.
function AdditionalBox_Callback(~, ~, ~)


% --- Executes during object creation, after setting all properties.
function AdditionalBox_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in RemoveButton.
function RemoveButton_Callback(hObject, ~, handles)
list = get(handles.AdditionalBox,'String');
if ~isempty(list)
    if ischar(list) || numel(list) == 1
        handles.settings = rmfield(handles.settings,{'extProperty', ...
            'extPropertyRange'});
        list = '';
    else
        val = get(handles.AdditionalBox,'Value');
        handles.settings.extProperty(val) = [];
        handles.settings.extPropertyRange(val) = [];
        list(val) = [];
        if val > numel(list)
            set(handles.AdditionalBox,'Value',numel(list));
        end
    end
    set(handles.AdditionalBox,'String',list);
    guidata(hObject,handles);
end



% --- Executes on button press in DoneB.
function DoneB_Callback(hObject, ~, handles)
count = 4;
a = isfield(handles.settings,'exposureProperty');
b = isempty(get(handles.ExpT,'String'));
if b
    count = count - 1;
end
if a && b
    handles.settings = rmfield(handles.settings,'exposureProperty');
    handles.settings = rmfield(handles.settings,'exposurePropertyRange');
end
a = isfield(handles.settings,'autoExposureProperty');
b = isempty(get(handles.AutoExpT,'String'));
if b
    count = count - 1;
end
if a && b
    handles.settings = rmfield(handles.settings,'autoExposureProperty');
    handles.settings = rmfield(handles.settings,'autoExposurePropertyRange');
end
a = isfield(handles.settings,'contrastProperty');
b = isempty(get(handles.ConT,'String'));
if b
    count = count - 1;
end
if a && b
    handles.settings = rmfield(handles.settings,'contrastProperty');
    handles.settings = rmfield(handles.settings,'contrastPropertyRange');
end
a = isfield(handles.settings,'autoContrastProperty');
b = isempty(get(handles.AutoConT,'String'));
if b
    count = count - 1;
end
if a && b
    handles.settings = rmfield(handles.settings,'autoContrastProperty');
    handles.settings = rmfield(handles.settings,'autoContrastPropertyRange');
end
a = isfield(handles.settings,'extProperty');
b = isempty(get(handles.AdditionalBox,'String'));
if ~b
    list = get(handles.AdditionalBox,'String');
    if ischar(list)
        count = count + 1;
    else
        count = count + numel(list);
    end
end
handles.settings.numCameraProperties = max(count,1);
if a && b
    handles.settings = rmfield(handles.settings,'extProperty');
    handles.settings = rmfield(handles.settings,'extPropertyRange');
end
a = isfield(handles.settings,'fluorescentCapture');
b = isempty(get(handles.FCT,'String'));
if a && b
    handles.settings = rmfield(handles.settings,'fluorescentCapture');
end
a = isfield(handles.settings,'fluorescentExposure');
b = isempty(get(handles.FCT,'String'));
if a && b
    handles.settings = rmfield(handles.settings,'fluorescentExposure');
end

handles.settings.cameraName = handles.camera{1,3}.DeviceName;

settings = handles.settings;
if numel(settings.resolution) ~= 2
    resp = inputdlg('Please enter the selected resolution.         ex. 1920,1080', ...
        'CameraWindow config',[1,40]);
    if isempty(resp) || isempty(resp{1})
        resp2 = questdlg('No resolution entered, configuration will not be saved.',...
            'CameraWindow config','Quit','Return','Return');
        if strcmp(resp2,'Quit')
            close(get(hObject,'Parent'));
        end
        return;
    end
    comma = find(resp{1} == ',');
    if ~isempty(comma) && comma > 1 && comma < numel(resp{1})
        settings.resolution = [str2double(resp{1}(1:comma-1)), ...
            str2double(resp{1}(comma+1:end))];
    else
        resp2 = questdlg('No resolution entered, configuration will not be saved.',...
            'CameraWindow config','Quit','Return','Return');
        if strcmp(resp2,'Quit')
            close(get(hObject,'Parent'));
        end
        return;
    end
end

resp = questdlg('Set window positions?','CameraWindow config','Yes','No','Yes');
if strcmp(resp,'Yes')
    monitors = get(0,'Monitor');
    c = [.9,.9,.8];
    pos = get(get(hObject,'Parent'),'Position');
    screen = find(pos(1) >= monitors(:,1) & pos(1) <= monitors(:,3) & ...
        pos(2) >= monitors(:,2) & pos(2) <= monitors(:,4));
    
    win(1) = figure('Visible','off','Color',c,'Units','Pixels','MenuBar', ...
        'None','IntegerHandle','off','Name','Camera Window','NumberTitle', ...
        'off','CloseRequestFcn',@winCRF);
    if isfield(settings,'CameraWindowPosition')
        pos = settings.CameraWindowPosition;
    else
        pos = get(win(1),'Position');
        pos(3:4) = settings.resolution;
        if (pos(2) + pos(4) > monitors(screen,4) - 20)
            pos(2) = monitors(screen,4) - 20 - pos(4);
        end
    end
    set(win(1),'Position',pos,'Visible','on','ResizeFcn', ...
        {@winRES,settings.resolution},'UserData',pos);
    uicontrol(win(1),'Style','Text','String','Camera Window','Units','normalized', ...
        'Position',[.01,.4,.98,.2],'FontSize',24,'ForegroundColor','b', ...
        'HorizontalAlignment','center','BackgroundColor',c);
    
    win(2) = figure('Visible','off','Color',c,'Units','Pixels','MenuBar', ...
        'None','IntegerHandle','off','Name','Camera Controls Window','Resize','off', ...
        'NumberTitle','off','CloseRequestFcn',@winCRF);
    if isfield(settings,'CameraControlsWindowPosition')
        pos = settings.CameraControlsWindowPosition;
    else
        pos = get(win(2),'Position');
        pos(3:4) = [300,480];
        if (pos(2) + pos(4) > monitors(screen,4) - 20)
            pos(2) = monitors(screen,4) - 20 - pos(4);
        end
    end
    set(win(2),'Position',pos,'Visible','on');
    uicontrol(win(2),'Style','Text','Units','normalized','String', ...
        'Camera Controls Window','Position',[.01,.4,.98,.2],'FontSize',24, ...
        'ForegroundColor','b','HorizontalAlignment','center','BackgroundColor',c);
    win(3) = figure('Color',c,'MenuBar','none','NumberTitle','off','Name', ...
        'Window Manager','CloseRequestFcn',@winCRF);
    uicontrol(win(3),'Style','Push','Units','normalized','String', ...
        'Reset Window Positions','Position',[0.1,.4,.8,.2],'Callback', ...
        {@winRESET,win(1:2)});
    waitfor(hObject,'UserData')
    settings.CameraWindowPosition = get(win(1),'Position');
    settings.CameraControlsWindowPosition = get(win(2),'Position');
    delete(win);
end

resp = questdlg('Set default path and filename?','CameraWindow config', ...
    'Yes','No','Yes');
if strcmp(resp,'Yes')
    str1 = sprintf(['Enter path or leave blank to clear:\n', ...
        '  Start with "current" to reference the PWD (current\\pics)\n', ...
        '  Start with "tag" to specify the Tag of a textbox with the desired path']);
    str2 = 'Enter filename or leave blank to clear';
    resp = inputdlg({str1,str2},'CameraWindow config',[1,75;1,50]);
    if numel(resp) ~= 0
        if ~isempty(resp{1})
            settings.snapshotSavePath = resp{1};
        end
        if ~isempty(resp{2})
            settings.fileName = resp{2};
        end
    end
end

if isfield(handles,'newCamera')
    cConfig = dir([handles.fpath,'camera*.config']);
    if numel(cConfig) > 0
        list = {cConfig(:).name};
        if ~any(strcmp(list,'camera.config'))
            handles.fname = 'camera.config';
        else
            for ii = 1:numel(cConfig)
                camNums(ii) = str2double(list{ii}(7:end-6));
            end
            camNums(isnan(camNums)) = 1;
            cVect = 1:numel(cConfig);
            camInd = find(camNums ~= cVect,1,'first');
            if isempty(camInd)
                handles.fname = ['camera',num2str(numel(cConfig)+1),'.config'];
            else
                handles.fname = ['camera',num2str(camInd),'.config'];
            end
        end
    end
    
end

save([handles.fpath,handles.fname],'-struct','settings','-mat');
close(get(hObject,'Parent'))


function winCRF(~,~)
clear winRES
bh = findall(0,'Tag','DoneB');
set(bh,'UserData',1);


function winRES(obj,~,res)
% Hold aspect ratio, monitor sizes, and screen maxed and halfed positions
% persistently in function
persistent r mon maxed maxedSet halfed halfedSet
if isempty(r)
    r =res(2) / res(1); % aspect ratio y/x
end
if isempty(mon)
    mon = get(0,'Monitor');
end
if isempty(maxed)
    maxed = mon;
    main = maxed(:,1) == 1 & maxed(:,2) == 1;
    maxed(main,2) = 41; % Take into acount the menu bar
    maxed(main,4) = maxed(main,4) - (41+75); % Reduce Height by menu and window top
    maxed(~main,4) = maxed(~main,4) - 75; % Reduce Height by window top
    % Calculate corresponding ratio locked positions
    
end
if isempty(halfed)
    halfed = [mon,mon];
end

% The following code is an attempt to make resizing more stable in Windows
% if ~libisloaded('user32') % Windows library gives access to mouse button state
%     loadlibrary('user32.dll','user32.h');
% end
% m = calllib('user32','GetAsyncKeyState',int32(1)); % Read left mouse button state
% if  m ~= -32767 % Left mouse button not clicked
    
    p = get(obj,'Position');
    disp(p)
    pO = get(obj,'UserData');
    
    y = p(2) + p(4); % pixel position of top of figure
    
    a = p(3) == pO(3);
    b = p(4) == pO(4);
    
    newX = round(p(4)/r); % New width if using current height
    newY = round(p(3)*r); % New height if using current width
    
    if ~(a && b) % if width or height changed
        if p(1) == 1 && p(2) == 41 && r < 1 % Check for Maximized and manually reshape
            p(3) = newX;
        elseif p(1) == 1 && p(2) == 41 && r > 1
            p(4) = newY;
        elseif a % Resizing by dragging the bottom border
            if newX + p(1) > mon(:,3) % Check right side of figure will be on a screen
                p(3) = max(mon(:,3)) - p(1); % Find max width
                p(4) = round(p(3)*r); % Recalculate new height
            else
                p(3) = newX;
            end
        elseif b % Resizing by dragging the right border
            p(4) = newY;
        else % Resizing by draggind corner or Win+<arrow key> commands
            difX = p(3) - pO(3); % Find whether width or height changed more
            difY = p(4) - pO(4);
            if abs(difX) > abs(difY) % Greater change in width, scale height
                p(4) = newY;
            else % Greater change in height, scale width
                if newX + p(1) > mon(:,3) % Check right side of resized figure
                    p(3) = max(mon(:,3)) - p(1); % Find max width if off screen
                    p(4) = round(p(3)*r); % Recalculate height
                else
                    p(3) = newX;
                end
            end
        end
    else
        % Currently, do nothing
    end
    
    p(2) = y - p(4); % modify y position to maintain top of figure pixel position
    
    set(obj,'Position',p,'UserData',p) % Resize figure and save position
% else
%     % Currently, do nothing
% end
return;


function winRESET(~,~,win)
monitor = get(0,'Monitor');
pos = get(win(1),'Position');
pos(1) = 10;
pos(2) = monitor(1,4) - 50 - pos(4);
set(win(1),'Position',pos);
set(win(2),'Position',[10,50,300,480]);


% --- Executes when user attempts to close configCamera.
function configCamera_CloseRequestFcn(hObject, ~, handles)
if isfield(handles,'vid') && isa(handles.vid,'videoinput') && isvalid(handles.vid)
    delete(handles.vid);
end
delete(hObject);



function FPT_Callback(hObject, ~, handles)
val = str2double(get(hObject,'String'));
prop = get(handles.ExpT,'String');
if ~isempty(prop)
    info = propinfo(handles.src,prop);
    range = info.ConstraintValue;
    if val < range(1)
        val = range(1);
    elseif val > range(2)
        val = range(2);
    end
    set(handles.src,prop,val);
    val = get(handles.src,prop);
    set(hObject,'String',num2str(val));
    handles.settings.fluorescentExposure = val;
    guidata(hObject,handles);
end


% --- Executes during object creation, after setting all properties.
function FPT_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FCT_Callback(hObject, ~, handles)
val = str2double(get(hObject,'String'));
prop = get(handles.ExpT,'String');
if ~isempty(prop)
    info = propinfo(handles.src,prop);
    range = info.ConstraintValue;
    if val < range(1)
        val = range(1);
    elseif val > range(2)
        val = range(2);
    end
    set(handles.src,prop,val);
    val = get(handles.src,prop);
    set(hObject,'String',num2str(val));
    handles.settings.fluorescentCapture = val;
    guidata(hObject,handles);
end


% --- Executes during object creation, after setting all properties.
function FCT_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in InitialB.
function InitialB_Callback(hObject, ~, handles)
hs = handles.settings;
if isfield(hs,'initialCommands')
    cmds = hs.initialCommands;
    if ischar(cmds)
        cmds = {cmds};
    end
else
    cmds = {''};
end
st1 = sprintf(['Enter any camera initialization commands.\n', ...
    'ex. UD.video.ReturnedColorspace = ''grayscale'';\n', ...
    '      UD.source.ExposreMode = ''manual'';']);
resp = inputdlg(st1,'Initial Commands',[10,50],cmds);
handles.settings.initialCommands = resp;
guidata(hObject,handles)


% --- Creates and returns a handle to the GUI figure. 
function h1 = configCamera_LayoutFcn(policy)
% policy - create a new figure or use a singleton. 'new' or 'reuse'.

persistent hsingleton;
if strcmpi(policy, 'reuse') & ishandle(hsingleton)
    h1 = hsingleton;
    return;
end

appdata = [];
appdata.GUIDEOptions = struct(...
    'active_h', [], ...
    'taginfo', struct(...
    'figure', 2, ...
    'listbox', 6, ...
    'text', 18, ...
    'pushbutton', 9, ...
    'edit', 3), ...
    'override', 0, ...
    'release', 13, ...
    'resize', 'none', ...
    'accessibility', 'callback', ...
    'mfile', 1, ...
    'callbacks', 1, ...
    'singleton', 1, ...
    'syscolorfig', 1, ...
    'blocking', 0, ...
    'lastSavedFile', 'V:\RobinsonLab Code\MATLAB Code\neuroPG\configCamera.m', ...
    'lastFilename', 'V:\RobinsonLab Code\MATLAB Code\neuroPG\configCameraTestFig.fig');
appdata.lastValidTag = 'configCamera';
appdata.GUIDELayoutEditor = [];
appdata.initTags = struct(...
    'handle', [], ...
    'tag', 'configCamera');

h1 = figure(...
'Units','characters',...
'CloseRequestFcn',@(hObject,eventdata)configCamera('configCamera_CloseRequestFcn',hObject,eventdata,guidata(hObject)),...
'Color',[0.941176470588235 0.941176470588235 0.941176470588235],...
'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
'IntegerHandle','off',...
'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
'MenuBar','none',...
'Name','configCameraTestFig',...
'NumberTitle','off',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'Position',[103.8 37.3846153846154 120.4 24.4615384615385],...
'Resize','off',...
'HandleVisibility','callback',...
'UserData',[],...
'Tag','configCamera',...
'Visible','on',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'CamerasBox';

h2 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',@(hObject,eventdata)configCamera('CamerasBox_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[2.2 17.6153846153846 35.2 5.07692307692308],...
'String','Camera List',...
'Style','listbox',...
'Value',1,...
'CreateFcn', {@local_CreateFcn, @(hObject,eventdata)configCamera('CamerasBox_CreateFcn',hObject,eventdata,guidata(hObject)), appdata} ,...
'Tag','CamerasBox');

appdata = [];
appdata.lastValidTag = 'FormatsBox';

h3 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',@(hObject,eventdata)configCamera('FormatsBox_Callback',hObject,eventdata,guidata(hObject)),...
'Max',2,...
'Position',[2.2 1.07692307692308 35.2 15],...
'String','Formats List',...
'Style','listbox',...
'Value',1,...
'CreateFcn', {@local_CreateFcn, @(hObject,eventdata)configCamera('FormatsBox_CreateFcn',hObject,eventdata,guidata(hObject)), appdata} ,...
'UserData',1,...
'Tag','FormatsBox');

appdata = [];
appdata.lastValidTag = 'text1';

h4 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[2.2 22.8461538461538 13.4 1.07692307692308],...
'String','Cameras',...
'Style','text',...
'Tag','text1',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'text2';

h5 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[2.2 16.2307692307692 13.4 1.07692307692308],...
'String','Formats',...
'Style','text',...
'Tag','text2',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'AdaptorText';

h6 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ForegroundColor',[0 0 1],...
'Position',[17 22.8461538461538 10.4 1.07692307692308],...
'String','Adaptor',...
'Style','text',...
'Tag','AdaptorText',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'IDText';

h7 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ForegroundColor',[0 0 1],...
'Position',[28.2 22.8461538461538 5.2 1.07692307692308],...
'String','ID',...
'Style','text',...
'Tag','IDText',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'FormatText';

h8 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ForegroundColor',[0 0 1],...
'HorizontalAlignment','right',...
'Position',[14.4 16.1538461538462 19.2 1.07692307692308],...
'String','Format',...
'Style','text',...
'Tag','FormatText',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'PropertiesBox';

h9 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',@(hObject,eventdata)configCamera('PropertiesBox_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[40.4 7.69230769230769 26.8 15],...
'String','Properties List',...
'Style','listbox',...
'Value',1,...
'CreateFcn', {@local_CreateFcn, @(hObject,eventdata)configCamera('PropertiesBox_CreateFcn',hObject,eventdata,guidata(hObject)), appdata} ,...
'Tag','PropertiesBox');

appdata = [];
appdata.lastValidTag = 'text8';

h10 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[40.4 22.8461538461538 13.4 1.07692307692308],...
'String','Properties',...
'Style','text',...
'Tag','text8',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'ExposureButton';

h11 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',@(hObject,eventdata)configCamera('ExposureButton_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[70 19.9230769230769 25.4 1.69230769230769],...
'String','Set Exposure Property',...
'Tag','ExposureButton',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'AutoExpButton';

h12 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',@(hObject,eventdata)configCamera('AutoExpButton_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[70 17.9230769230769 25.4 1.69230769230769],...
'String','Set Auto Exposure Prop',...
'Tag','AutoExpButton',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'ContrastButton';

h13 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',@(hObject,eventdata)configCamera('ContrastButton_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[70 15.9230769230769 25.4 1.69230769230769],...
'String','Set Contrast Property',...
'Tag','ContrastButton',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'AutoConButton';

h14 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',@(hObject,eventdata)configCamera('AutoConButton_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[70 13.9230769230769 25.4 1.69230769230769],...
'String','Set Auto Contrast Prop',...
'Tag','AutoConButton',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'AddPropButton';

h15 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',@(hObject,eventdata)configCamera('AddPropButton_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[70 11.7692307692308 25.4 1.69230769230769],...
'String','Add Additional Property',...
'Tag','AddPropButton',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'AdditionalBox';

h16 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',@(hObject,eventdata)configCamera('AdditionalBox_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[70 2.53846153846154 25.2 8.76923076923077],...
'String',blanks(0),...
'Style','listbox',...
'Value',1,...
'CreateFcn', {@local_CreateFcn, @(hObject,eventdata)configCamera('AdditionalBox_CreateFcn',hObject,eventdata,guidata(hObject)), appdata} ,...
'Tag','AdditionalBox');

appdata = [];
appdata.lastValidTag = 'RemoveButton';

h17 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',@(hObject,eventdata)configCamera('RemoveButton_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[70 0.846153846153846 13.8 1.69230769230769],...
'String','Remove',...
'Tag','RemoveButton',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'RangeT';

h18 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ForegroundColor',[0 0 1],...
'Position',[40.4 6.07692307692308 23.4 1.07692307692308],...
'String','Range',...
'Style','text',...
'Tag','RangeT',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'TypeT';

h19 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ForegroundColor',[0 0 1],...
'Position',[40.2 4.92307692307692 23.4 1.07692307692308],...
'String','Type',...
'Style','text',...
'Tag','TypeT',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'ExpT';

h20 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ForegroundColor',[0 0 1],...
'HorizontalAlignment','left',...
'Position',[96 20.2307692307692 23.4 1.07692307692308],...
'String',blanks(0),...
'Style','text',...
'Tag','ExpT',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'AutoExpT';

h21 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ForegroundColor',[0 0 1],...
'HorizontalAlignment','left',...
'Position',[96 18.2307692307692 23.4 1.07692307692308],...
'String',blanks(0),...
'Style','text',...
'Tag','AutoExpT',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'ConT';

h22 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ForegroundColor',[0 0 1],...
'HorizontalAlignment','left',...
'Position',[96 16.2307692307692 23.4 1.07692307692308],...
'String',blanks(0),...
'Style','text',...
'Tag','ConT',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'AutoConT';

h23 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'ForegroundColor',[0 0 1],...
'HorizontalAlignment','left',...
'Position',[96 14.2307692307692 23.4 1.07692307692308],...
'String',blanks(0),...
'Style','text',...
'Tag','AutoConT',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'DoneB';

h24 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',@(hObject,eventdata)configCamera('DoneB_Callback',hObject,eventdata,guidata(hObject)),...
'FontSize',10,...
'Position',[103.8 0.923076923076923 13.8 2.15384615384615],...
'String','Done',...
'Tag','DoneB',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'text16';

h25 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'CData',[],...
'Position',[97.4 9.23076923076923 21.4 2.15384615384615],...
'String','Fluorescent Preview Exposure Setting:',...
'Style','text',...
'UserData',[],...
'Tag','text16',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'text17';

h26 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'CData',[],...
'Position',[97.4 5.15384615384615 21.4 2.15384615384615],...
'String','Fluorescent Capture Exposure Setting:',...
'Style','text',...
'UserData',[],...
'Tag','text17',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'FPT';

h27 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',@(hObject,eventdata)configCamera('FPT_Callback',hObject,eventdata,guidata(hObject)),...
'Enable','off',...
'Position',[103 7.30769230769231 10.2 1.69230769230769],...
'String',blanks(0),...
'Style','edit',...
'CreateFcn', {@local_CreateFcn, @(hObject,eventdata)configCamera('FPT_CreateFcn',hObject,eventdata,guidata(hObject)), appdata} ,...
'Tag','FPT');

appdata = [];
appdata.lastValidTag = 'FCT';

h28 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',@(hObject,eventdata)configCamera('FCT_Callback',hObject,eventdata,guidata(hObject)),...
'Enable','off',...
'Position',[103 3.46153846153846 10.2 1.69230769230769],...
'String',blanks(0),...
'Style','edit',...
'CreateFcn', {@local_CreateFcn, @(hObject,eventdata)configCamera('FCT_CreateFcn',hObject,eventdata,guidata(hObject)), appdata} ,...
'Tag','FCT');

appdata = [];
appdata.lastValidTag = 'InitialB';

h29 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',@(hObject,eventdata)configCamera('InitialB_Callback',hObject,eventdata,guidata(hObject)),...
'Position',[96.4 11.7692307692308 23.2 1.69230769230769],...
'String','Edit Initial Commands',...
'Tag','InitialB',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );


hsingleton = h1;


% --- Set application data first then calling the CreateFcn. 
function local_CreateFcn(hObject, eventdata, createfcn, appdata)

if ~isempty(appdata)
   names = fieldnames(appdata);
   for i=1:length(names)
       name = char(names(i));
       setappdata(hObject, name, getfield(appdata,name));
   end
end

if ~isempty(createfcn)
   if isa(createfcn,'function_handle')
       createfcn(hObject, eventdata);
   else
       eval(createfcn);
   end
end


% --- Handles default GUIDE GUI creation and callback dispatch
function varargout = gui_mainfcn(gui_State, varargin)

gui_StateFields =  {'gui_Name'
    'gui_Singleton'
    'gui_OpeningFcn'
    'gui_OutputFcn'
    'gui_LayoutFcn'
    'gui_Callback'};
gui_Mfile = '';
for i=1:length(gui_StateFields)
    if ~isfield(gui_State, gui_StateFields{i})
        error(message('MATLAB:guide:StateFieldNotFound', gui_StateFields{ i }, gui_Mfile));
    elseif isequal(gui_StateFields{i}, 'gui_Name')
        gui_Mfile = [gui_State.(gui_StateFields{i}), '.m'];
    end
end

numargin = length(varargin);

if numargin == 0
    % CONFIGCAMERA
    % create the GUI only if we are not in the process of loading it
    % already
    gui_Create = true;
elseif local_isInvokeActiveXCallback(gui_State, varargin{:})
    % CONFIGCAMERA(ACTIVEX,...)
    vin{1} = gui_State.gui_Name;
    vin{2} = [get(varargin{1}.Peer, 'Tag'), '_', varargin{end}];
    vin{3} = varargin{1};
    vin{4} = varargin{end-1};
    vin{5} = guidata(varargin{1}.Peer);
    feval(vin{:});
    return;
elseif local_isInvokeHGCallback(gui_State, varargin{:})
    % CONFIGCAMERA('CALLBACK',hObject,eventData,handles,...)
    gui_Create = false;
else
    % CONFIGCAMERA(...)
    % create the GUI and hand varargin to the openingfcn
    gui_Create = true;
end

if ~gui_Create
    % In design time, we need to mark all components possibly created in
    % the coming callback evaluation as non-serializable. This way, they
    % will not be brought into GUIDE and not be saved in the figure file
    % when running/saving the GUI from GUIDE.
    designEval = false;
    if (numargin>1 && ishghandle(varargin{2}))
        fig = varargin{2};
        while ~isempty(fig) && ~ishghandle(fig,'figure')
            fig = get(fig,'parent');
        end
        
        designEval = isappdata(0,'CreatingGUIDEFigure') || isprop(fig,'__GUIDEFigure');
    end
        
    if designEval
        beforeChildren = findall(fig);
    end
    
    % evaluate the callback now
    varargin{1} = gui_State.gui_Callback;
    if nargout
        [varargout{1:nargout}] = feval(varargin{:});
    else       
        feval(varargin{:});
    end
    
    % Set serializable of objects created in the above callback to off in
    % design time. Need to check whether figure handle is still valid in
    % case the figure is deleted during the callback dispatching.
    if designEval && ishghandle(fig)
        set(setdiff(findall(fig),beforeChildren), 'Serializable','off');
    end
else
    if gui_State.gui_Singleton
        gui_SingletonOpt = 'reuse';
    else
        gui_SingletonOpt = 'new';
    end

    % Check user passing 'visible' P/V pair first so that its value can be
    % used by oepnfig to prevent flickering
    gui_Visible = 'auto';
    gui_VisibleInput = '';
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        % Recognize 'visible' P/V pair
        len1 = min(length('visible'),length(varargin{index}));
        len2 = min(length('off'),length(varargin{index+1}));
        if ischar(varargin{index+1}) && strncmpi(varargin{index},'visible',len1) && len2 > 1
            if strncmpi(varargin{index+1},'off',len2)
                gui_Visible = 'invisible';
                gui_VisibleInput = 'off';
            elseif strncmpi(varargin{index+1},'on',len2)
                gui_Visible = 'visible';
                gui_VisibleInput = 'on';
            end
        end
    end
    
    % Open fig file with stored settings.  Note: This executes all component
    % specific CreateFunctions with an empty HANDLES structure.

    
    % Do feval on layout code in m-file if it exists
    gui_Exported = ~isempty(gui_State.gui_LayoutFcn);
    % this application data is used to indicate the running mode of a GUIDE
    % GUI to distinguish it from the design mode of the GUI in GUIDE. it is
    % only used by actxproxy at this time.   
    setappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]),1);
    if gui_Exported
        gui_hFigure = feval(gui_State.gui_LayoutFcn, gui_SingletonOpt);

        % make figure invisible here so that the visibility of figure is
        % consistent in OpeningFcn in the exported GUI case
        if isempty(gui_VisibleInput)
            gui_VisibleInput = get(gui_hFigure,'Visible');
        end
        set(gui_hFigure,'Visible','off')

        % openfig (called by local_openfig below) does this for guis without
        % the LayoutFcn. Be sure to do it here so guis show up on screen.
        movegui(gui_hFigure,'onscreen');
    else
        gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        % If the figure has InGUIInitialization it was not completely created
        % on the last pass.  Delete this handle and try again.
        if isappdata(gui_hFigure, 'InGUIInitialization')
            delete(gui_hFigure);
            gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        end
    end
    if isappdata(0, genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]))
        rmappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]));
    end

    % Set flag to indicate starting GUI initialization
    setappdata(gui_hFigure,'InGUIInitialization',1);

    % Fetch GUIDE Application options
    gui_Options = getappdata(gui_hFigure,'GUIDEOptions');
    % Singleton setting in the GUI M-file takes priority if different
    gui_Options.singleton = gui_State.gui_Singleton;

    if ~isappdata(gui_hFigure,'GUIOnScreen')
        % Adjust background color
        if gui_Options.syscolorfig
            set(gui_hFigure,'Color', get(0,'DefaultUicontrolBackgroundColor'));
        end

        % Generate HANDLES structure and store with GUIDATA. If there is
        % user set GUI data already, keep that also.
        data = guidata(gui_hFigure);
        handles = guihandles(gui_hFigure);
        if ~isempty(handles)
            if isempty(data)
                data = handles;
            else
                names = fieldnames(handles);
                for k=1:length(names)
                    data.(char(names(k)))=handles.(char(names(k)));
                end
            end
        end
        guidata(gui_hFigure, data);
    end

    % Apply input P/V pairs other than 'visible'
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        len1 = min(length('visible'),length(varargin{index}));
        if ~strncmpi(varargin{index},'visible',len1)
            try set(gui_hFigure, varargin{index}, varargin{index+1}), catch break, end
        end
    end

    % If handle visibility is set to 'callback', turn it on until finished
    % with OpeningFcn
    gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
    if strcmp(gui_HandleVisibility, 'callback')
        set(gui_hFigure,'HandleVisibility', 'on');
    end

    feval(gui_State.gui_OpeningFcn, gui_hFigure, [], guidata(gui_hFigure), varargin{:});

    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        % Handle the default callbacks of predefined toolbar tools in this
        % GUI, if any
        guidemfile('restoreToolbarToolPredefinedCallback',gui_hFigure); 
        
        % Update handle visibility
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);

        % Call openfig again to pick up the saved visibility or apply the
        % one passed in from the P/V pairs
        if ~gui_Exported
            gui_hFigure = local_openfig(gui_State.gui_Name, 'reuse',gui_Visible);
        elseif ~isempty(gui_VisibleInput)
            set(gui_hFigure,'Visible',gui_VisibleInput);
        end
        if strcmpi(get(gui_hFigure, 'Visible'), 'on')
            figure(gui_hFigure);
            
            if gui_Options.singleton
                setappdata(gui_hFigure,'GUIOnScreen', 1);
            end
        end

        % Done with GUI initialization
        if isappdata(gui_hFigure,'InGUIInitialization')
            rmappdata(gui_hFigure,'InGUIInitialization');
        end

        % If handle visibility is set to 'callback', turn it on until
        % finished with OutputFcn
        gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
        if strcmp(gui_HandleVisibility, 'callback')
            set(gui_hFigure,'HandleVisibility', 'on');
        end
        gui_Handles = guidata(gui_hFigure);
    else
        gui_Handles = [];
    end

    if nargout
        [varargout{1:nargout}] = feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    else
        feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    end

    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
    end
end

function gui_hFigure = local_openfig(name, singleton, visible)

% openfig with three arguments was new from R13. Try to call that first, if
% failed, try the old openfig.
if nargin('openfig') == 2
    % OPENFIG did not accept 3rd input argument until R13,
    % toggle default figure visible to prevent the figure
    % from showing up too soon.
    gui_OldDefaultVisible = get(0,'defaultFigureVisible');
    set(0,'defaultFigureVisible','off');
    gui_hFigure = openfig(name, singleton);
    set(0,'defaultFigureVisible',gui_OldDefaultVisible);
else
    gui_hFigure = openfig(name, singleton, visible);  
    %workaround for CreateFcn not called to create ActiveX
    if feature('HGUsingMATLABClasses')
        peers=findobj(findall(allchild(gui_hFigure)),'type','uicontrol','style','text');    
        for i=1:length(peers)
            if isappdata(peers(i),'Control')
                actxproxy(peers(i));
            end            
        end
    end
end

function result = local_isInvokeActiveXCallback(~, varargin)

try
    result = ispc && iscom(varargin{1}) ...
             && isequal(varargin{1},gcbo);
catch
    result = false;
end

function result = local_isInvokeHGCallback(gui_State, varargin)

try
    fhandle = functions(gui_State.gui_Callback);
    result = ~isempty(findstr(gui_State.gui_Name,fhandle.file)) || ...
             (ischar(varargin{1}) ...
             && isequal(ishghandle(varargin{2}), 1) ...
             && (~isempty(strfind(varargin{1},[get(varargin{2}, 'Tag'), '_'])) || ...
                ~isempty(strfind(varargin{1}, '_CreateFcn'))) );
catch
    result = false;
end


