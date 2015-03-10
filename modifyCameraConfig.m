function modifyCameraConfig
[myFile,myPath] = uigetfile('*.config','CameraWindow: Modify Config File');
if isa(myFile,'double')
    return;
end
settings = load([myPath,myFile],'-mat');
fh = figure('IntegerHandle','off','MenuBar','none','Name','CameraConfig', ...
    'NumberTitle','off','Tag','CameraConfig','Units','normalized', ...
    'Close',@CloseFCN);
h.app = fh;
setappdata(h.app,'settings',settings);
setappdata(h.app,'file',[myPath,myFile]);

uicontrol(fh,'Style','Text','Units','normalized','Position',[.5,.9,.2,.05], ...
    'Background',[.8,.8,.8],'String','Property Type');
h.type = uicontrol(fh,'Style','Text','Tag','propertyTypeText','Units', ...
    'normalized','Position',[.5,.85,.2,.05],'FontSize',13);
uicontrol(fh,'Style','Text','Units','normalized','Position',[.75,.9,.1,.05], ...
    'Background',[.8,.8,.8],'String','Size');
h.size = uicontrol(fh,'Style','Text','Tag','propertySizeText','Units', ...
    'normalized','Position',[.75,.85,.1,.05],'FontSize',13);

h.list = uicontrol(fh,'Style','listbox','Tag','propertyList','Units','normalized', ...
    'Position',[.5,.1,.2,.7]);
h.addButton1 = uicontrol(fh,'Style','PushButton','Units','normalized','Position', ...
    [.6,.05,.1,.05],'String','Add Value','Enable','off');

h.list2 = uicontrol(fh,'Style','listbox','Tag','pList2','Units','normalized', ...
    'Position',[.75,.5,.2,.3]);
h.addButton2 = uicontrol(fh,'Style','PushButton','Units','normalized','Position', ...
    [.85,.45,.1,.05],'String','Add Value','Enable','off');

h.fields = uicontrol(fh,'Style','listbox','Tag','Settings List','String', ...
    fieldnames(settings),'Units','normalized','Position',[.05,.05,.4,.9]);

h.saveButton = uicontrol(fh,'Style','PushButton','Units','normalized','Position', ...
    [.8,.05,.15,.1],'String','Save');

set(h.fields,'Callback',{@FieldCallback,h});
set(h.list,'Callback',{@ListCallback,h});
set(h.addButton1,'Callback',{@AddButton1Callback,h});
set(h.list2,'Callback',{@List2Callback,h});
set(h.addButton2,'Callback',{@AddButton2Callback,h});
set(h.saveButton,'Callback',{@SaveButtonCallback,h});


function FieldCallback(obj,~,h)
settings = getappdata(h.app,'settings');
index = get(obj,'Value');
names = get(obj,'String');
field = names{index};
set(h.list2,'String','');
set(h.addButton1,'Enable','off');
set(h.addButton2,'Enable','off');
if strcmp(field,'extPropertyRange')
    set(h.list,'String',settings.extProperty);
    value = settings.(field);
    set(h.type,'String',class(value{1}));
    set(h.size,'String',num2str(numel(value{1})));
else
    value = settings.(field);
    set(h.type,'String',class(value));
    set(h.size,'String',num2str(numel(value)));
    set(h.list,'String',value);
    if ~isa(value,'char') && numel(value) > 1
        set(h.addButton1,'Enable','on');
    end
end


function ListCallback(obj,~,h)
props = get(obj,'String');
if isempty(props)
    return;
end
if ischar(props) && size(props,1) == 1
    props = {props};
end
fieldInd = get(h.fields,'Value');
fields = get(h.fields,'String');
field = fields{fieldInd};
settings = getappdata(h.app,'settings');
index = get(obj,'Value');
if strcmp(field,'extPropertyRange')
    value = settings.extPropertyRange;
    set(h.type,'String',class(value{index}));
    set(h.size,'String',num2str(numel(value{index})));
    set(h.list2,'String',value{index});
    if ~isa(value{index},'char') && numel(value{index}) > 1
        set(h.addButton2,'Enable','on');
    else
        set(h.addButton2,'Enable','off');
    end
else
    resp = questdlg('Choose operation:','CameraConfig','Modify','Delete','Cancel', ...
        'Modify');
    if isempty(resp) || strcmp(resp,'Cancel')
        return;
    elseif strcmp(resp,'Modify')
        switch get(h.type,'String')
            case 'char'
                new = inputdlg('Enter new value','ConfigCamera',[1,50],props(index));
                if numel(new) == 0
                    return;
                end
                settings.(field) = new{1};
            case 'cell'
                new = inputdlg('Enter new value','ConfigCamera',[1,50],props(index));
                if numel(new) == 0
                    return;
                end
                values = settings.(field);
                values(index) = new;
                settings.(field) = values;
            case 'double'
                new = inputdlg('Enter new value','ConfigCamera',[1,50], ...
                    {props(index,:)});
                if numel(new) == 0
                    return;
                end
                values = settings.(field);
                values(index) = str2double(new{1});
                settings.(field) = values;
            case 'int32'
                new = inputdlg('Enter new value','ConfigCamera',[1,50], ...
                    {props(index,:)});
                if numel(new) == 0
                    return;
                end
                values = settings.(field);
                values(index) = int32(str2double(new));
                settings.(field) = values;
            otherwise
                
        end
        setappdata(h.app,'settings',settings);
        FieldCallback(h.fields,[],h);
    else
        
    end
end


function List2Callback(obj,~,h)
props = get(obj,'String');
if isempty(props)
    return;
end
if ischar(props) && size(props,1) == 1
    props = {props};
end
% Property name and index from base list
fieldInd = get(h.fields,'Value');
fields = get(h.fields,'String');
field = fields{fieldInd};
% Property index from secondary list
fieldInd2 = get(h.list,'Value');
settings = getappdata(h.app,'settings');
index = get(obj,'Value');
resp = questdlg('Choose operation:','CameraConfig','Modify','Delete','Cancel', ...
    'Modify');
if isempty(resp) || strcmp(resp,'Cancel')
    return;
elseif strcmp(resp,'Modify')
    switch get(h.type,'String')
        case 'char'
            new = inputdlg('Enter new value','ConfigCamera',[1,50],props(index));
            if numel(new) == 0
                return;
            end
            settings.(field){fieldInd2} = new{1};
        case 'cell'
            new = inputdlg('Enter new value','ConfigCamera',[1,50],props(index));
            if numel(new) == 0
                return;
            end
            values = settings.(field){fieldInd2};
            values(index) = new;
            settings.(field){fieldInd2} = values;
        case 'double'
            new = inputdlg('Enter new value','ConfigCamera',[1,50], ...
                {props(index,:)});
            if numel(new) == 0
                return;
            end
            values = settings.(field){fieldInd2};
            values(index) = str2double(new{1});
            settings.(field){fieldInd2} = values;
        case 'int32'
            new = inputdlg('Enter new value','ConfigCamera',[1,50], ...
                {props(index,:)});
            if numel(new) == 0
                return;
            end
            values = settings.(field){fieldInd2};
            values(index) = int32(str2double(new));
            settings.(field){fieldInd2} = values;
        otherwise
            
    end
    setappdata(h.app,'settings',settings);
    ListCallback(h.list,[],h);
else
    
end


function AddButton1Callback(obj,~,h)
return;


function AddButton2Callback(obj,~,h)
return;


function SaveButtonCallback(obj,~,h)
fname = getappdata(h.app,'file');
resp = questdlg('Make a backup? Old backups will be overwritten.', ...
    'CameraConfig','Yes');
switch resp
    case 'Cancel'
        return;
    case 'Yes'
        backupName = [fname(1:end-6),'bak'];
        movefile(fname,backupName,'f');
end
settings = getappdata(h.app,'settings'); %#ok<NASGU>
save(fname,'-struct','settings','-mat');


function CloseFCN(obj,~)
delete(obj)