function varargout = Calibrate(varargin)
% RUNS THE CALIBRATION ROUTINE
% Can only get to here if the DAQ is on
% CALIBRATE MATLAB code for Calibrate.fig
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Calibrate_OpeningFcn, ...
                   'gui_OutputFcn',  @Calibrate_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
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


% --- Executes just before Calibrate is made visible.
function Calibrate_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.Ch=cell2mat(varargin(1));
handles.SR=cell2mat(varargin(2));
handles.mDev=varargin{3};
handles.MaxRecord=cell2mat(varargin(4));
handles.UpdateEvery=cell2mat(varargin(5));
handles.IsRunning=0;
handles.Buffer = NaN(ceil(handles.MaxRecord*handles.SR),3); % time,raw,filtered
set(handles.pushStartStop,'Enable','off');
set(handles.pushPicker,'Enable','off');
set(handles.pushMin,'Enable','off');
ax1=handles.axes1;
xlim (ax1,[0 1]);
xlabel(ax1, 'Time (s)');
ylabel(ax1, 'Raw voltage units');
set(gcf,'toolbar','figure');
guidata(hObject, handles);
% UIWAIT makes Calibrate wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Calibrate_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushSetup.
function pushSetup_Callback(hObject, eventdata, handles)
[filename,pathname]=uiputfile('*.csv','Save file name for calibration run');
if isequal(filename,0) || isequal(pathname,0)
   % disp('User selected Cancel')
else
    handles.File = [pathname filename];
    handles.FilenameComplete = 1;
    set(handles.pushStartStop,'Enable','on');    
end
guidata(hObject, handles);
% hObject    handle to pushSetup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushStartStop.
function pushStartStop_Callback(hObject, eventdata, handles)
    global CalBuffer;
    global CalPosition;
% hObject    handle to pushStartStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(handles.IsRunning==0 || strcmp( get(handles.pushStartStop,'String' ),'Start'))    
    if( strcmp( get(handles.pushStartStop,'String' ),'Start') && handles.IsRunning==1 )
            stop( handles.mSession );
            release( handles.mSession );
            handles = rmfield( handles, {'mSession','lh'} );
    end    
    set(handles.pushPicker,'Enable','on');
    CalBuffer = NaN( ceil(handles.SR*handles.MaxRecord),3 );
    CalPosition = 1;
    set(handles.pushStartStop,'String','Stop');
    handles.IsRunning=1;
    handles.mSession = daq.createSession('ni');
    addAnalogInputChannel(handles.mSession,handles.mDev.ID,handles.Ch,'Voltage');
    handles.mSession.Rate=handles.SR;
    handles.mSession.DurationInSeconds = handles.MaxRecord;
    handles.mSession.NotifyWhenDataAvailableExceeds = round(handles.SR*handles.UpdateEvery);
    handles.lh=addlistener( handles.mSession,'DataAvailable',@(src,event) myCalibrateFunction(hObject,handles,event) );
    handles.mSession.startBackground();  
else
    handles.IsRunning=0;
    set(handles.pushStartStop,'String','Start');
    handles.mSession.stop();
    release( handles.mSession );
    handles = rmfield( handles, {'mSession','lh'});
end
guidata(hObject, handles);


% --- Executes on button press in pushPicker.
function pushPicker_Callback(hObject, eventdata, handles)
global CalBuffer;
global DAQSampRate;

% [x,y]=ginput(1);
% WRITING TO FILE IS DONE HERE
datacursormode on;
dcm_obj=datacursormode(gcf);
choice = MFquestdlg([0.5,0.5],{'Add two cursor points, Shift+Click to add second point';'Press OK after both points are chosen'},'Max Point Selection','OK','Cancel','OK');
switch choice
    case 'OK'
        info_struct=getCursorInfo(dcm_obj);
        if length( info_struct )~=2
            uiwait(msgbox('You must select exactly two points. Zoom in to area of interest before selection','Restart Process','modal'));
        else
            x1=info_struct(1).Position;y1=x1(2);x1=round(x1(1)*DAQSampRate);
            x2=info_struct(2).Position;y2=x2(2);x2=round(x2(1)*DAQSampRate);
            if( x1>x2 )
                xtemp=x2;x2=x1;x1=xtemp;clear xtemp;
                % ytemp=y2;y2=y1;y1=ytemp;clear ytemp;
            end
            MaximumAverage = mean( CalBuffer(x1:x2,2) );
            mFileName=handles.File;            
            mFile=[mFileName(1:end-3) 'pick' mFileName(end-3:end)];
            fileID = fopen(mFile,'a');            
            fprintf(fileID,'%s, %12.8f\n','MaxSetPoint',MaximumAverage);
            fclose(fileID);              
            delete(findall(gcf,'Type','hggroup'));
            MaxTextBox = uicontrol('style','text');
            set(MaxTextBox,'Units','characters')
            set(MaxTextBox,'Position',[80 32 30 1]);
            set(MaxTextBox,'String',['Max Setpoint: ' num2str(MaximumAverage)]);         
        end
    case 'Cancel'
end
datacursormode off;  
set(handles.pushMin,'Enable','on');


% hObject    handle to pushPicker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushMin.
function pushMin_Callback(hObject, eventdata, handles)
global CalBuffer;
global DAQSampRate;

% [x,y]=ginput(1);
% WRITING TO FILE IS DONE HERE
datacursormode on;
dcm_obj=datacursormode(gcf);
choice = MFquestdlg([0.5,0.5],{'Add two cursor points, Shift+Click to add second point';'Press OK after both points are chosen'},'Min Point Selection','OK','Cancel','OK');
switch choice
    case 'OK'
        info_struct=getCursorInfo(dcm_obj);
        if length( info_struct )~=2
            uiwait(msgbox('You must select exactly two points. Zoom in to area of interest before selection','Restart Process','modal'));
        else
            x1=info_struct(1).Position;y1=x1(2);x1=round(x1(1)*DAQSampRate);
            x2=info_struct(2).Position;y2=x2(2);x2=round(x2(1)*DAQSampRate);
            if( x1>x2 )
                xtemp=x2;x2=x1;x1=xtemp;clear xtemp;
                % ytemp=y2;y2=y1;y1=ytemp;clear ytemp;
            end
            MinAverage = mean( CalBuffer(x1:x2,2) );
            mFileName=handles.File;            
            mFile=[mFileName(1:end-3) 'pick' mFileName(end-3:end)];
            fileID = fopen(mFile,'a');            
            fprintf(fileID,'%s, %12.8f\n','MinSetPoint',MinAverage);
            fclose(fileID);              
            delete(findall(gcf,'Type','hggroup'));
            MaxTextBox = uicontrol('style','text');
            set(MaxTextBox,'Units','characters')
            set(MaxTextBox,'Position',[80 30 30 1]);
            set(MaxTextBox,'String',['Min Setpoint: ' num2str(MinAverage)]);                  
        end
    case 'Cancel'
datacursormode off;        
end
% hObject    handle to pushMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
