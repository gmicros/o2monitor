function [  ] = UpdateGraph( handles, x, y, y2, y3 )
% inputs are 
% handles
% x - time
% y - raw signal
% y2 - filtered signal 
% y3 - derivative signal
global sliderVal;
global sigLen;
global DAQSampRate;
global windowLength;
global mainBuffer;

ax1=handles.primaryAxis;

start  = (sliderVal * sigLen)/ DAQSampRate;
stop = (sliderVal * sigLen + windowLength) / DAQSampRate;
startInd = floor(sliderVal * sigLen) + 1;
stopInd = floor(sliderVal * sigLen + windowLength);

if( eq(sliderVal,1))
    sigLen = sum(~isnan(mainBuffer(:,1)));
    start  = (sliderVal * sigLen - windowLength)/ DAQSampRate;
    stop = (sliderVal * sigLen) / DAQSampRate;
    startInd = floor(sliderVal * sigLen - windowLength);
    stopInd = floor(sliderVal * sigLen);
    set(handles.scrollLocationText, 'String', strcat(num2str(start), ' sec'));
end

if(stopInd > sum(~isnan(mainBuffer(:,1))))
    stopInd = length(y2);
    
end


if(get(handles.fullSignalCheck, 'Value') == 1)
    start = min(x);
    startInd = 1;
    stop = max(x);
    stopInd = length(x);
end

%[startInd, stopInd]
%[min(y2(startInd:stopInd)), max(y2(startInd:stopInd))]

myMaxDisp = max(y2(startInd:stopInd));
myMinDisp = min(y2(startInd:stopInd));

commentFlag = [];
if (length(mainBuffer(:,1)) > 100)
    commentFlag = mainBuffer(2:end,6) - mainBuffer(1:end-1,6);
end

isCommented = ~isempty(find(commentFlag',1));
if( isCommented )
    commentIntervals = find(commentFlag);
end

co = [ 0.0000 0.4470 0.7410;
       0.0000 0.0000 0.0000;
       0.8500 0.3250 0.0980];
% set(groot,'defaultAxesColorOrder',co);   

handles.Raw = get( handles.checkboxRaw,'Value' );
handles.Filter = get( handles.checkboxFilter,'Value' );
handles.Derivative = get( handles.checkboxSlope,'Value' );

% only plotting raw (blue)
if( handles.Raw==1 && handles.Filter==0 && handles.Derivative==0 )
    plot(ax1,x,y,'Color',[0.0000 0.4470 0.7410],'Linewidth',2);
    ylabel(ax1, 'O_2 Saturation');
    %ylim(ax1, [myMinDisp myMaxDisp] );
    xlim (ax1,[start, stop]);
    xlabel(ax1, 'Time (s)');
end
% only plotting filtered (black)
if( handles.Raw==0 && handles.Filter==1 && handles.Derivative==0 )
    plot(ax1,x,y2,'k','Linewidth',2);
    ylabel(ax1, 'O_2 Saturation');
    %ylim(ax1, [myMinDisp myMaxDisp] );
    xlim (ax1,[start ,stop]);
    xlabel(ax1, 'Time (s)');
end
% plotting both, no derivative (blue, then black)
if( handles.Raw==1 && handles.Filter==1 && handles.Derivative==0 )
    hh=plot(ax1,x,y,x,y2,'Linewidth',2);
    hh(1).Color = co(1,:);
    hh(2).Color = co(2,:);    
    ylabel(ax1, 'O_2 Saturation');
    %ylim(ax1, [myMinDisp myMaxDisp] );
    xlim (ax1,[start,stop]);
    xlabel(ax1, 'Time (s)');
end

% plotting raw + derivative (blue + orange)
if( handles.Raw==1 && handles.Filter==0 && handles.Derivative==1 )
   [hAx,hLine1,hLine2] = plotyy(ax1,x,y,x,y3);
   xlim(hAx(1), [start, stop] );
   xlim(hAx(2), [start, stop] );
   %ylim(hAx(1), [myMinDisp, myMaxDisp] );
   set(hLine1,'Linewidth',2);
   set(hLine1,'Color',co(1,:));
   set(hLine2,'Color',co(3,:));
   set(hAx(1),'YTickMode','auto','YTickLabelMode','auto','YColor',co(2,:));
   set(hAx(2),'YTickMode','auto','YTickLabelMode','auto','YColor',co(3,:));
   xlim (ax1,[min(x),max(x)]);
   xlabel(ax1, 'Time (s)');
   ylabel(hAx(1),'O_2 Saturation');
   ylabel(hAx(2),'Change in Saturation');
end

% plotting filtered + derivative (black + orange)
if( handles.Raw==0 && handles.Filter==1 && handles.Derivative==1 )
   [hAx,hLine1,hLine2] = plotyy(ax1,x,y2,x,y3);
   xlim(hAx(1), [min(x),max(x)] );
   xlim(hAx(2), [min(x),max(x)] );
   %ylim(hAx(1), [myMinDisp, myMaxDisp] );
   set(hLine1,'Linewidth',2);
   set(hLine1,'Color',co(2,:));
   set(hLine2,'Color',co(3,:));
   set(hAx(1),'YTickMode','auto','YTickLabelMode','auto','YColor',co(2,:));
   set(hAx(2),'YTickMode','auto','YTickLabelMode','auto','YColor',co(3,:));
   xlim (ax1,[min(x),max(x)]);
   xlabel(ax1, 'Time (s)');
   ylabel(hAx(1),'O_2 Saturation');
   ylabel(hAx(2),'Change in Saturation');
end

% plotting both + derivative (blue, black, + orange)
if( handles.Raw==1 && handles.Filter==1 && handles.Derivative==1 )
    [hAx,hLine1,hLine2] = plotyy(ax1,x,y,x,y3);
    xlim(hAx(1), [min(x),max(x)] );
    xlim(hAx(2), [min(x),max(x)] );
    %ylim(hAx(1), [myMinDisp, myMaxDisp] );
    set(hLine1,'Color',co(1,:));
    set(hLine1,'Linewidth',2);
    set(hLine2,'Color',co(3,:));
    set(hAx(1),'YTickMode','auto','YTickLabelMode','auto','YColor',co(2,:));
    set(hAx(2),'YTickMode','auto','YTickLabelMode','auto','YColor',co(3,:));
    hold(hAx(1),'on');
    plot(hAx(1),x,y2,'k','Linewidth',2);
    hold(hAx(1),'off');
    xlim (ax1,[min(x),max(x)]);
    xlabel(ax1, 'Time (s)');
    ylabel(hAx(1),'O_2 Saturation');
    ylabel(hAx(2),'Change in Saturation');
end



hold(ax1, 'on');
if(isCommented)
    for i = 1:length(commentIntervals)
        plot(ax1, [x(commentIntervals(i)),x(commentIntervals(i))],...
            [myMinDisp - 5, myMaxDisp + 5], 'g');
    end
end
hold(ax1, 'off');

xlim (ax1,[start, stop]);
xlabel(ax1, 'Time (s)');