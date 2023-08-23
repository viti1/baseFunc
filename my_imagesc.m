function my_imagesc(im)
figure; 
imagesc(im); 
[N,edges] = histcounts(im(:),1000,'Normalization','cdf');
upperLim = edges(find(N > 0.99,1)); 
lowerLim = edges(find(N > 0.01,1));
SetAxisEqual();
set(gca,'CLim',[ lowerLim upperLim]); 
colorbar;
colormap gray;