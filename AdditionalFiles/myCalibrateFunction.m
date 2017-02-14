function [ mReturnVars ] = myCalibrateFunction( hObject,handles,event )

global CalPosition;
global CalBuffer;
global FilterOrder;

b = ones(FilterOrder,1)./FilterOrder;
CalBuffer(CalPosition:(CalPosition+length(event.Data)-1),1:2)=[event.TimeStamps event.Data];

x=CalBuffer(~isnan(CalBuffer(:,1)),1);
y=CalBuffer(~isnan(CalBuffer(:,2)),2);

% SMALL AMOUNT OF SMOOTHING IS DONE HERE
if(CalPosition <= 3*(3*FilterOrder-1))   
    y2 = filtfilt( b,1,y );
    CalBuffer( CalPosition:(CalPosition+length(event.Data)-1),3)=y2(CalPosition:(CalPosition+length(event.Data)-1) );
else      
    y3 = filtfilt(  b, 1, y((end-3*length(event.Data)+1):end) );
    y = y3( (end-length(event.Data)+1):end ) ;
    CalBuffer(CalPosition:(CalPosition+length(event.Data)-1),3)=y;
end

ax1=handles.axes1;
plot(ax1, x,CalBuffer(~isnan(CalBuffer(:,2)),2), x,CalBuffer(~isnan(CalBuffer(:,3)),3),'k','linewidth',2);
xlim (ax1,[min(x),max(x)]);
xlabel(ax1, 'Time (s)');
ylabel(ax1, 'Raw voltage units');

% WRITING TO FILE IS DONE HERE
mFileName = handles.File;
mFile=[mFileName(1:end-3) 'data' mFileName(end-3:end)];
fileID = fopen(mFile,'a');
fprintf(fileID,'%12.8f, %12.8f, %12.8f\n',[event.TimeStamps' ; event.Data' ; CalBuffer(CalPosition:(CalPosition+length(event.Data)-1),3)']);
fclose(fileID);

% CEHCK IF OVERSHOOTING, TO CLEAN UP A BIT
CalPosition=CalPosition+length(event.Data);
if (CalPosition >= handles.mSession.DurationInSeconds*handles.mSession.Rate-1)
    handles.IsRunning=0;
    set(handles.pushStartStop,'String','Start');
    % stop( handles.mSession );
    % release( handles.mSession );
    % handles=rmfield(handles,{'mSession','lh'});    
end


mReturnVars=0;