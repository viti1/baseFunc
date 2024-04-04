function fig = my_imagesc(im)
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