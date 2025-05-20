function markTiming(timingFile,startTime)
% 
    T = readtable(timingFile);
    if nargin < 2
        startTime = T.Time{1};
    end
    if isa(startTime,'datetime')
        startTime = datestr(startTime, 'HH:MM:SS');
    elseif nnz(startTime==':') == 1
        startTime = [ startTime , ':00'] ;
    end
        
    ylims = get(gca,'YLim');
    xlims = get(gca,'XLim');
    dx = 0.01*diff(xlims);
    hold on;
    for k=1:size(T,1)
        currTime = minutes(duration(T.Time{k},'InputFormat','hh:mm') - duration(startTime)); % minutes from recording start
        plot(currTime*[1 1],ylims,'k-');
        text(currTime+dx,ylims(1)+diff(ylims)*0.95,T.Event{k},'Rotation',-90,'Clipping','on','FontSize',12);
    end
    set(gca,'YLim',ylims);
    
    
function nOfMin = difftime(eventTime,startTime)  
    nOfMin  = etime(datevec(datenum(eventTime)),datevec(datenum(startTime)))/60;
    