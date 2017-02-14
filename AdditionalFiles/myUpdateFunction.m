function [ handles ] = myUpdateFunction( hObject,handles,event )

global mainPosition;
global mainBuffer;
global FilterOrder;
global NumBuffers;
global FileNameSave;
global sliderVal;
% now mainBuffer has [time,rawVoltages,rawScaled,filteredScaled,derivativeScaled]

b = ones(FilterOrder,1)./FilterOrder;
filtBuff = NumBuffers*length(event.Data);
mainBuffer(mainPosition:(mainPosition+length(event.Data)-1),1:2)=[event.TimeStamps event.Data];

% early on in the run, use the whole data for filtering
if( mainPosition <= filtBuff )   
    y=mainBuffer(~isnan(mainBuffer(:,2)),2);
    y2 = filtfilt( b,1,y );    
    myMax = handles.hundredPoint;
    myMin = handles.zeroPoint; 
    yP = (y-myMin)./(myMax-myMin)*100;
    y2P = (y2-myMin)./(myMax-myMin)*100;
    % mDeriv =     
    mainBuffer(mainPosition:(mainPosition+length(event.Data)-1),3)=yP(mainPosition:(mainPosition+length(event.Data)-1));
    mainBuffer(mainPosition:(mainPosition+length(event.Data)-1),4)=y2P(mainPosition:(mainPosition+length(event.Data)-1));
    % mainBuffer(mainPosition:(mainPosition+length(event.Data)-1),5)=mDeriv(mainPosition:(mainPosition+length(event.Data)-1));
% now we just can use the past filtBuff datapoints
else
    y=mainBuffer((mainPosition-filtBuff):mainPosition+length(event.Data)-1,2);
    y2 = filtfilt( b,1,y );
    myMax = handles.hundredPoint;
    myMin = handles.zeroPoint; 
    yP = (y-myMin)./(myMax-myMin)*100;
    y2P = (y2-myMin)./(myMax-myMin)*100;
    % mDeriv = 
    mainBuffer(mainPosition:(mainPosition+length(event.Data)-1),3)=yP((end-length(event.Data)+1):end);
    mainBuffer(mainPosition:(mainPosition+length(event.Data)-1),4)=y2P((end-length(event.Data)+1):end);
    % mainBuffer(mainPosition:(mainPosition+length(event.Data)-1),5)=mDeriv((end-length(event.Data)+1):end);
end

% now mainBuffer has [time,rawVoltages,rawScaled,filteredScaled,derivativeScaled]
y = mainBuffer(~isnan(mainBuffer(:,3)),3);
y2= mainBuffer(~isnan(mainBuffer(:,4)),4);
y3= mainBuffer(~isnan(mainBuffer(:,5)),5);

sprintf('Slider val = %.2f', sliderVal)

UpdateGraph( handles, mainBuffer(~isnan(mainBuffer(:,1)),1), y, y2, y3 );


% CEHCK IF OVERSHOOTING, ABOUT TO TIMEOUT!!!!
mainPosition=mainPosition+length(event.Data);
if (mainPosition >= handles.mainSession.DurationInSeconds*handles.mainSession.Rate-1)
     handles.IsMainRunning=0;
     set(handles.pushInspect,'Enable','on');
     set(handles.pushStartStop,'String','Start');   
     % WRITING TO FILE IS DONE HERE
     mFileName = handles.File;
     mFile=[mFileName(1:end-3) 'data' mFileName(end-3:end)];
     fileID = fopen(mFile,'a');
     fprintf(fileID,'%12.8f, %12.8f, %12.8f\n',[mainBuffer(:,1)' ; mainBuffer(:,2)' ; mainBuffer(:,3)' ]);
     fclose(fileID);
      % Force to rechoose filename      
      %handles.File = [];
      %FileNameSave = handles.File;
      handles.FilenameComplete = 0;
      set(handles.pushStartStop,'Enable','off');
      set(handles.editMaxRecord,'Enable','on');
      set(handles.mChan,'Enable','on');
      set(handles.textFilename,'String','Choose filename');
end
 












