function varargout = PolarographicSystemMonitor(varargin)
% POLAROGRAPHICSYSTEMMONITOR MATLAB code for PolarographicSystemMonitor.fig
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PolarographicSystemMonitor_OpeningFcn, ...
                   'gui_OutputFcn',  @PolarographicSystemMonitor_OutputFcn, ...
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




% OPENING FUNCTION
% --- Executes just before PolarographicSystemMonitor is made visible.
function PolarographicSystemMonitor_OpeningFcn(hObject, eventdata, handles, varargin)

global mainBuffer;
global mainPosition;
global FilterOrder; % order of filter for the smoothing
FilterOrder = 30;   
global NumBuffers;
NumBuffers = 5;
global ExtraSmooth;
ExtraSmooth = 250; % order for extra smoothing performed before derivative
global DAQSampRate;
DAQSampRate = 1000;
global ZeroPointCal;
ZeroPointCal = 0;
global SSizeMG; % for scaling the derivative? (gets divided by this)
SSizeMG = 1.0;
global sliderVal
sliderVal = 0;
    handles.output = hObject;
    addpath('.\AdditionalFiles\');
    % identify all NI DAQ devices.
    devices=daq.getDevices;
    mDevice=0;
    for i = 1:length(devices)
       if(strcmp('USB-6001',devices(i).Model)) % find the one we want (USB-6001), let's call it mDevice
           mDevice=i;
       end    
    end; clear i;
    if mDevice==0
        errordlg( 'No NI USB-6001 device found to record' );
    end
    mDevice = devices(mDevice); clear devices;
    handles.mDevice=mDevice;
    % Set default sampling rate and channel values,recording length, etc.
    handles.SamplingRate = DAQSampRate; % FIXED, JUST CHANGE WHAT WE UPDATE EVERY
    handles.UpdateEvery = 0.1;
    handles.zeroPoint = 0;
    set(handles.mSampRate,'String',num2str(1/handles.UpdateEvery));
    handles.UpdateEveryPts = handles.UpdateEvery*handles.SamplingRate;
    handles.Chan = 4;
    set(handles.mChan,'String',num2str(handles.Chan));
    handles.MaxRecord = 180;
    set(handles.editMaxRecord,'String',num2str(handles.MaxRecord));
    handles.ExpSampSizeMG = 1.0;
    set(handles.sampMG,'String',num2str(handles.ExpSampSizeMG));
    set(handles.checkboxRaw,'Value',1);
    handles.Raw = 1;
    set(handles.checkboxFilter,'Value',0);
    handles.Filter = 0;
    set(handles.checkboxSlope,'Value',0);
    handles.Derivative = 0;
    set(handles.pushStartStop,'Enable','off');
    handles.CalibrateComplete = 0;
    handles.FilenameComplete = 0;
    handles.IsMainRunning = 0;
    set(handles.mSampRate,'Visible','off');
    set(handles.textSampRate,'Visible','off');    
    
    mainBuffer = NaN( ceil(handles.SamplingRate*handles.MaxRecord),5 );
    mainPosition = 1;
guidata(hObject, handles);





% CLOSING FUNCTION
% --- Outputs from this function are returned to the command line.
function varargout = PolarographicSystemMonitor_OutputFcn(hObject, eventdata, handles) 
% daqreset;
% Get default command line output from handles structure
varargout{1} = handles.output;




% SETTING DAQ CHANNEL
% Callback for setting the channel number
function mChan_Callback(hObject, eventdata, handles)
    handles.Chan = round ( str2double(get(hObject,'String')) );
    if( handles.Chan > 7)
        handles.Chan=7;
    end
    if( handles.Chan < 0)
        handles.Chan = 0;
    end
    set( handles.mChan,'String',num2str(handles.Chan) );
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function mChan_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% SETTING SAMPLING RATE
% CalLback for setting the sampling rate (between 1 and 100 Hz is allowed)
function mSampRate_Callback(hObject, eventdata, handles)
    handles.UpdateEvery = 1/str2double(get(hObject,'String'));
    % *** do some error / boundary checking ***
    if( handles.UpdateEvery >= 1 ) % 1 Hz 'sampling' rate is lowest we will allow
       handles.UpdateEvery = 1;
       handles.UpdateEveryPts = handles.UpdateEvery*handles.SamplingRate;
       set(handles.mSampRate,'String',num2str(1/handles.UpdateEvery));
    end
    if( handles.UpdateEvery <= 0.001 )
       handles.UpdateEvery = 0.001; % 100 Hz 'sampling' rate is highest we allow
       handles.UpdateEveryPts = handles.UpdateEvery*handles.SamplingRate;
       set(handles.mSampRate,'String',num2str(1/handles.UpdateEvery));
    end
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function mSampRate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% SETTING MAXIMUM RECORD DURATION TIME
function editMaxRecord_Callback(hObject, eventdata, handles)
    handles.MaxRecord = str2double(get(hObject,'String'));
    if(handles.MaxRecord > 2400)
       warning('Max experiment time is limited to 40 minutes'); 
       handles.MaxRecord=2400;
       set(handles.editMaxRecord,'String',num2str(handles.MaxRecord));
    end
    % ***do some error checking ????
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function editMaxRecord_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% CALIBRATION ROUTINES
% --- Executes on button press in pushCalibrate.
function pushCalibrate_Callback(hObject, eventdata, handles)
    % check to see if hardware needs to be released..
    if( handles.IsMainRunning==1);
        stop( handles.mainSession );        
        release( handles.mainSession );
        handles = rmfield( handles, {'mainSession','mainlh'});
    end
    Calibrate(handles.Chan,handles.SamplingRate,handles.mDevice,handles.MaxRecord,handles.UpdateEvery);

% --- Executes on button press in pushLoadcalibrate.
function pushLoadcalibrate_Callback(hObject, eventdata, handles)
global ZeroPointCal;
global HundredPointCal;
global mainBuffer;
global mainPosition;
    % Load in the calibration point!
    [FileName,PathName]=uigetfile('*pick.csv','Please select calibration file');
    if isequal(FileName,0)
        % user canceled
    else
        mainBuffer = NaN( ceil(handles.SamplingRate*handles.MaxRecord),5 );
        mainPosition = 1;        
        fullName = [PathName FileName];
        if strcmp( fullName(end-7:end-4),'pick' )
            % when using 'pick' data, use the last point selected
            M = readtable( fullName,'ReadVariableNames',false );
            C = table2cell(M(:,1));
            v = table2array(M(:,2));
            indMax= find( strcmp(C,'MaxSetPoint'),1,'last' );
            HundredPointCal = v(indMax);
            indMin= find( strcmp(C,'MinSetPoint'),1,'last' );
            ZeroPointCal = v(indMin);
            handles.zeroPoint = ZeroPointCal;
            handles.hundredPoint = HundredPointCal;
            handles.CalibrateComplete=1;
            if handles.FilenameComplete==1
                set( handles.pushStartStop,'Enable','on' );
            end
        else
            % invalid file type
            errordlg('Load in a .pick.csv');
        end
    end
guidata(hObject,handles);



% --- STARTING/STOPPING THE DATA COLLECTION
function pushStartStop_Callback(hObject, eventdata, handles)
    global mainBuffer;
    global mainPosition;
    global FileNameSave;

    if( handles.IsMainRunning==0 || strcmp( get(handles.pushStartStop,'String' ),'Start') )
        
        if( strcmp( get(handles.pushStartStop,'String' ),'Start') && handles.IsMainRunning==1 )
            stop( handles.mainSession );
            release( handles.mainSession );
            handles = rmfield( handles, {'mainSession','mainlh'} );
        end
        set(handles.pushInspect,'Enable','off');
        set(handles.editMaxRecord,'Enable','inactive');
        set(handles.mChan,'Enable','inactive');
        mainBuffer = NaN( ceil(handles.SamplingRate*handles.MaxRecord),5 );
        mainPosition = 1;
        set( handles.pushStartStop,'String','Stop' );
        handles.IsMainRunning = 1;
        handles.mainSession = daq.createSession('ni');
        addAnalogInputChannel(handles.mainSession,handles.mDevice.ID,handles.Chan,'Voltage');
        handles.mainSession.Rate=handles.SamplingRate;
        handles.mainSession.DurationInSeconds = handles.MaxRecord;
        handles.mainSession.NotifyWhenDataAvailableExceeds = round(handles.SamplingRate*handles.UpdateEvery);
        handles.mainlh=addlistener( handles.mainSession,'DataAvailable',@(src,event) myUpdateFunction(hObject,handles,event) );
        handles.mainSession.startBackground();
    else % WE PUSHED THE STOP BUTTON BEFORE IT TIMED OUT!!!!!
        handles.IsMainRunning=0;
        set(handles.pushStartStop,'String','Start');
        set(handles.pushInspect,'Enable','on');
        set(handles.editMaxRecord,'Enable','on');
        set(handles.mChan,'Enable','on');
        stop( handles.mainSession );        
        release( handles.mainSession );
        handles = rmfield( handles, {'mainSession','mainlh'});        
        % WRITING TO FILE IS DONE HERE
        earlyStop = find( isnan(mainBuffer(:,1)),1 )-1;
        mFileName = handles.File;
        mFile=[mFileName(1:end-3) 'data' mFileName(end-3:end)];
        fileID = fopen(mFile,'a');
        fprintf(fileID,'%12.8f, %12.8f, %12.8f\n',[mainBuffer(1:earlyStop,1)' ; mainBuffer(1:earlyStop,2)' ; mainBuffer(1:earlyStop,3)' ]);
        fclose(fileID); 
        % Force to rechoose filename
        %handles.File = [];
        %FileNameSave = handles.File;
        handles.FilenameComplete = 0;
        set(handles.pushStartStop,'Enable','off');
        set(handles.textFilename,'String','Choose filename');               
    end
guidata(hObject, handles);





% --- FILE TO SAVE.
function pushFileSave_Callback(hObject, eventdata, handles)
    global FileNameSave;
    [filename,pathname]=uiputfile('*.csv','Save file name for experimental run');
    if isequal(filename,0) || isequal(pathname,0)
       % disp('User selected Cancel')
    else
        set(handles.textFilename,'String',filename);
        handles.File = [pathname filename];
        FileNameSave = handles.File;
        handles.FilenameComplete = 1;
        if (handles.CalibrateComplete == 1)
            set(handles.pushStartStop,'Enable','on');
        end    
    end
guidata(hObject,handles);



% WHAT TO VISUALIZE ON THE MAIN AXES 
% --- Executes on button press in checkboxRaw.
function checkboxRaw_Callback(hObject, eventdata, handles)
    global mainBuffer;
    handles.Raw = get(hObject,'Value');
    if handles.Raw == 0; % need *at least* either the filtered or raw shown
        set(handles.checkboxFilter,'Value',1);
    end
    if any(~isnan(mainBuffer(:)))
        x =mainBuffer(~isnan(mainBuffer(:,1)),1);
        y =mainBuffer(~isnan(mainBuffer(:,3)),3);
        y2=mainBuffer(~isnan(mainBuffer(:,4)),4);
        y3=mainBuffer(~isnan(mainBuffer(:,5)),5);
        UpdateGraph( handles,x,y,y2,y3 );
    end
guidata(hObject,handles);


% --- Executes on button press in checkboxFilter.
function checkboxFilter_Callback(hObject, eventdata, handles)
    global mainBuffer;
    handles.Filter = get(hObject,'Value');
    if handles.Filter == 0; % need *at least* either the filtered or raw shown
        set(handles.checkboxRaw,'Value',1);
    end
    if any(~isnan(mainBuffer(:)))
        x =mainBuffer(~isnan(mainBuffer(:,1)),1);
        y =mainBuffer(~isnan(mainBuffer(:,3)),3);
        y2=mainBuffer(~isnan(mainBuffer(:,4)),4);
        y3=mainBuffer(~isnan(mainBuffer(:,5)),5);
        UpdateGraph( handles,x,y,y2,y3 );
    end
guidata(hObject,handles);


% --- Executes on button press in checkboxSlope.
function checkboxSlope_Callback(hObject, eventdata, handles)
    global mainBuffer;
    handles.Derivative = get(hObject,'Value');    
    if any(~isnan(mainBuffer(:)))
        x =mainBuffer(~isnan(mainBuffer(:,1)),1);
        y =mainBuffer(~isnan(mainBuffer(:,3)),3);
        y2=mainBuffer(~isnan(mainBuffer(:,4)),4);
        y3=mainBuffer(~isnan(mainBuffer(:,5)),5);
        UpdateGraph( handles,x,y,y2,y3 );
    end
guidata(hObject,handles);


% --- Executes on button press in pushInspect.
function pushInspect_Callback(hObject, eventdata, handles)
Inspect();



function sampMG_Callback(hObject, eventdata, handles)
global SSizeMG; % for scaling the derivative? (gets divided by this)
handles.ExpSampSizeMG = str2double(get(hObject,'String'));
SSizeMG = handles.ExpSampSizeMG;
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function sampMG_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AxesMainLen_Callback(hObject, eventdata, handles)
% hObject    handle to AxesMainLen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AxesMainLen as text
%        str2double(get(hObject,'String')) returns contents of AxesMainLen as a double


% --- Executes during object creation, after setting all properties.
function AxesMainLen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AxesMainLen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AddEventButton.
function AddEventButton_Callback(hObject, eventdata, handles)
% hObject    handle to AddEventButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function EventDescription_Callback(hObject, eventdata, handles)
% hObject    handle to EventDescription (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EventDescription as text
%        str2double(get(hObject,'String')) returns contents of EventDescription as a double


% --- Executes during object creation, after setting all properties.
function EventDescription_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EventDescription (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on slider movement.
function timeSlider_Callback(hObject, eventdata, handles)
% hObject    handle to timeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global sliderVal
val = get(hObject, 'Value');
sliderVal = val;
guidata(hObject, handles)



% --- Executes during object creation, after setting all properties.
function timeSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
