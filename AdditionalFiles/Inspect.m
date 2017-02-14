function varargout = Inspect(varargin)
global mainBuffer;
% INSPECT MATLAB code for Inspect.fig
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Inspect_OpeningFcn, ...
                   'gui_OutputFcn',  @Inspect_OutputFcn, ...
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


% --- Executes just before Inspect is made visible.
function Inspect_OpeningFcn(hObject, eventdata, handles, varargin)
    global mainBuffer;
    global DAQSampRate;
    global ZeroPointCal;
    global SlopeDataPts;
    global SSizeMG;
        
    SlopeDataPts = [];

    set(gcf,'toolbar','figure');
    set(gcf,'CloseRequestFcn',@mCloseRequestFn);
    
    handles.output = hObject;
    
    set( handles.checkRaw,'Value',1 );
    set( handles.checkFilter,'Value',1 );
    set( handles.checkDeriv,'Value',1 );
    set( handles.editFiltLen,'String','0.1');
    
    handles.x   = mainBuffer(~isnan(mainBuffer(:,1)),1);
    handles.raw = mainBuffer(~isnan(mainBuffer(:,2)),2);
    myMin = ZeroPointCal;
    myMax = max(filtfilt(ones(30,1)/30,1,mainBuffer(1:round(DAQSampRate/10),2)));
    handles.y = (handles.raw-myMin)./(myMax-myMin)*100;
    handles.FiltLen = ceil(str2double(get(handles.editFiltLen,'String'))*DAQSampRate);
    b = ones(handles.FiltLen,1)/handles.FiltLen;
    handles.y2 = filtfilt(b,1,handles.y);
    handles.y3 = ([diff(handles.y2);diff(handles.y2((end-1):end))]*DAQSampRate)/SSizeMG;
    l = length(handles.x);
    mainBuffer = NaN(size(mainBuffer));
    mainBuffer(1:l,1) = handles.x;
    mainBuffer(1:l,2) = handles.raw;
    mainBuffer(1:l,3) = handles.y;
    mainBuffer(1:l,4) = handles.y2;
    mainBuffer(1:l,5) = handles.y3;        
    
    handles = RedoCalcs( hObject,handles );
    UpdateInsAxes( hObject,handles );
    
guidata(hObject, handles);


% calculate things in mainBuffer
function handles = RedoCalcs( hObject,handles )
    global mainBuffer;
    global DAQSampRate;
    global ZeroPointCal;
    global SSizeMG;

    myMin = ZeroPointCal;
    myMax = max(filtfilt(ones(30,1)/30,1,mainBuffer(1:round(DAQSampRate/10),2)));
    handles.y = (handles.raw-myMin)./(myMax-myMin)*100;
    b = ones(handles.FiltLen,1)/handles.FiltLen;
    handles.y2 = filtfilt(b,1,handles.y);
    handles.y3 = [diff(handles.y2);diff(handles.y2((end-1):end))]*DAQSampRate/SSizeMG;
    l = length(handles.x);
    mainBuffer(1:l,3) = handles.y;
    mainBuffer(1:l,4) = handles.y2;
    mainBuffer(1:l,5) = handles.y3;        
guidata( hObject,handles );


function UpdateInsAxes(  hObject,handles )
    global DAQSampRate;
    global mainBuffer;
    
    co = [ 0.0000 0.4470 0.7410;
       0.0000 0.0000 0.0000;
       0.8500 0.3250 0.0980];
    
    ax=handles.axesInspect;
    cla(ax,'reset');
    hold(ax,'on');
    if( get(handles.checkRaw,'Value') == 1)
        plot(ax,handles.x,handles.y,'Color',co(1,:)) 
        ylim(ax,[min( [0 min(handles.y)] ) max(handles.y)]);
    end
    if( get(handles.checkFilter,'Value') == 1)
        plot(ax,handles.x,handles.y2,'k','Linewidth',2)            
        ylim(ax,[min( [0 min(handles.y)] ) max(handles.y)]);
        AddVertical( 10,1 );

    end
    if( get(handles.checkDeriv,'Value') == 1)          
        [hhh,l1,l2]=plotyy(ax,handles.x,NaN(size(handles.x)),handles.x,handles.y3);                      
        set(hhh(1),'YTickMode','auto','YTickLabelMode','auto','YColor',co(2,:));
        ylim(hhh(1),[min( [0 min(handles.y)] ) max(handles.y)]);
        set(hhh(2),'YTickMode','auto','YTickLabelMode','auto','YColor',co(3,:));
        set(hhh(2),'XLim',[0 max(handles.x)]);        
        hold(ax,'off');
    end    
    hold(ax,'off');
    ylabel(ax,'O_2 Saturation');
    xlim(ax,[0 max(handles.x)]);
    if  ((get(handles.checkRaw,'Value') == 0)&&(get(handles.checkFilter,'Value') == 0))&&(get(handles.checkDeriv,'Value') == 1)
        pos=0;
        AddVertical( 10,pos )
    end
    
guidata(hObject, handles);

function AddVertical( len,pos )
    global SlopeDataPts;
    for i = 1:size(SlopeDataPts,1)
       [z]=SlopeDataPts(i,1:2);
       [z2]=SlopeDataPts(i,3:4);
       x=z(1);y=z(2);
       x2=z2(1);y2=z2(2);
       if( pos == 0)
           y=50;y2=50;
       end
       line([x x],[y+len y-len],'Color','k')       
       line([x2 x2],[y2+len y2-len],'Color','k')
       % here we add the text (D#x: slopeVal)
       text( mean([x x2]),mean([y y2]),['D' num2str(i) ': ' num2str(SlopeDataPts(i,5),4)]);
    end
    



% --- Outputs from this function are returned to the command line.
function varargout = Inspect_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;




function mCloseRequestFn( src,callbackdata )
% Close request function 
global mainBuffer;
global FileNameSave;
global SlopeDataPts;
% here we write the last result to a file before closing the window
% WRITING TO FILE IS DONE HERE
earlyStop = find( isnan(mainBuffer(:,1)),1 )-1;
if( isempty(earlyStop) )
   earlyStop = size(mainBuffer,1); 
end
mFileName = FileNameSave;
mFile=[mFileName(1:end-3) 'filtered' mFileName(end-3:end)];
fileID = fopen(mFile,'a');
fprintf(fileID,'%12.5f, %12.8f, %12.8f, %12.8f, %12.8f\n',[mainBuffer(1:earlyStop,1)' ; mainBuffer(1:earlyStop,2)' ; mainBuffer(1:earlyStop,3)' ; mainBuffer(1:earlyStop,4)' ; mainBuffer(1:earlyStop,5)' ]);
fclose(fileID);

% here we write the selected points to a file, order is x1, y1, x2, y2, (y2-y1)/(x2-x1)
if( ~isempty( SlopeDataPts ) )
    mFileName = FileNameSave;
    mFile=[mFileName(1:end-3) 'slopePoints' mFileName(end-3:end)];
    fileID = fopen(mFile,'a');
    fprintf(fileID, 'X1, Y1, X2, Y2, ScaledSlope\n');
    fprintf(fileID,'%12.5f, %12.8f, %12.5f, %12.8f, %12.8f\n',[SlopeDataPts(:,1)' ; SlopeDataPts(:,2)' ; SlopeDataPts(:,3)' ; SlopeDataPts(:,4)' ; SlopeDataPts(:,5)' ]);
    fclose(fileID);        
end


delete(gcf);





% --- Executes on button press in checkRaw.
function checkRaw_Callback(hObject, eventdata, handles)
    UpdateInsAxes( hObject, handles );
guidata(hObject, handles);

% --- Executes on button press in checkFilter.
function checkFilter_Callback(hObject, eventdata, handles)
    UpdateInsAxes(  hObject,handles );
guidata(hObject, handles);

% --- Executes on button press in checkDeriv.
function checkDeriv_Callback(hObject, eventdata, handles)
    UpdateInsAxes(  hObject,handles );
guidata(hObject, handles);

function editFiltLen_Callback(hObject, eventdata, handles)
    global DAQSampRate;
    handles.FiltLen = ceil(str2double(get(handles.editFiltLen,'String'))*DAQSampRate);
    handles = RedoCalcs(  hObject,handles );
    UpdateInsAxes(  hObject,handles );
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editFiltLen_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushSlope.
function pushSlope_Callback(hObject, eventdata, handles)
global SlopeDataPts;
global SSizeMG;
datacursormode on;
dcm_obj=datacursormode(gcf);
choice = MFquestdlg([0.5,0.5],{'Add two cursor points, Shift+Click to add second point';'Press OK after both points are chosen'},'Point Selection','OK','Cancel','OK');
switch choice
    case 'OK'
        info_struct=getCursorInfo(dcm_obj);
        if length( info_struct )~=2
            uiwait(msgbox('You must select exactly two points. Zoom in to area of interest before selection','Restart process','modal'));
        else
            x1 = info_struct(1).Position; y1 = x1(2); x1=x1(1);
            x2 = info_struct(2).Position; y2 = x2(2); x2=x2(1);
            % sort based on x1 position;
            if x1>x2
                xT=x2 ; x2=x1 ; x1=xT;
                yT=y2 ; y2=y1 ; y1=yT;
            end
            SlopeDataPts=[SlopeDataPts; [x1 y1 x2 y2 ((y2-y1)/(x2-x1))/SSizeMG]];
            datacursormode off;
            delete(findall(gcf,'Type','hggroup','HandleVisibility','off'));                           
        end                    
    case 'Cancel'        
end
UpdateInsAxes(  hObject,handles );




