function fig = my_imagesc(im)
% Create figure with stretched image between 0.99 and 0.01 percentiles and equal axis

im = double(im);
fig = figure('Units','Normalized','Position',[0.05,0.05,0.6,0.8]); 
imagesc(im); 
[N,edges] = histcounts(im(:),1000,'Normalization','cdf');
upperLim = ceil(edges(find(N > 0.99,1))); 
lowerLim = floor(edges(find(N > 0.01,1)));
if isequal(upperLim,lowerLim)
    upperLim = lowerLim + 0.1;
end
SetAxisEqual();
set(gca,'CLim',[ lowerLim upperLim]); 
colorbar;
colormap gray;

function SetAxisEqual(ax)
if nargin < 1
    ax = gca();
end
axis equal; 
dataObj = findall(ax,'Type','Image');
set(ax,'XLim', dataObj.XData + 0.5*[-1 1], 'YLim', dataObj.YData + 0.5*[-1 1])