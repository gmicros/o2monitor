function [  ] = UpdateGraph( handles, x, y, y2, y3 )
% inputs are 
% handles
% x - time
% y - raw signal
% y2 - filtered signal 
% y3 - derivative signal
global start;
global stop;
ax1=handles.primaryAxis;


myMaxDisp = max([100 max(y2)]);
myMinDisp = min([0 min(y2)]);


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
    ylim(ax1, [myMinDisp myMaxDisp] );
    xlim (ax1,[start, stop]);
    xlabel(ax1, 'Time (s)');
end
% only plotting filtered (black)
if( handles.Raw==0 && handles.Filter==1 && handles.Derivative==0 )
    plot(ax1,x,y2,'k','Linewidth',2);
    ylabel(ax1, 'O_2 Saturation');
    ylim(ax1, [myMinDisp myMaxDisp] );
    xlim (ax1,[min(x),max(x)]);
    xlabel(ax1, 'Time (s)');
end
% plotting both, no derivative (blue, then black)
if( handles.Raw==1 && handles.Filter==1 && handles.Derivative==0 )
    hh=plot(ax1,x,y,x,y2,'Linewidth',2);
    hh(1).Color = co(1,:);
    hh(2).Color = co(2,:);    
    ylabel(ax1, 'O_2 Saturation');
    ylim(ax1, [myMinDisp myMaxDisp] );
    xlim (ax1,[min(x),max(x)]);
    xlabel(ax1, 'Time (s)');
end

% plotting raw + derivative (blue + orange)
if( handles.Raw==1 && handles.Filter==0 && handles.Derivative==1 )
   [hAx,hLine1,hLine2] = plotyy(ax1,x,y,x,y3);
   xlim(hAx(1), [min(x),max(x)] );
   xlim(hAx(2), [min(x),max(x)] );
   ylim(hAx(1), [myMinDisp, myMaxDisp] );
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
   ylim(hAx(1), [myMinDisp, myMaxDisp] );
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
    ylim(hAx(1), [myMinDisp, myMaxDisp] );
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














