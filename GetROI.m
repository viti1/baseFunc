function [ mask , circ , figIm ] = GetROI(im)

figIm = my_imagesc(im);
xlim(size(im,2)*[-0.3 1.3]);
ylim(size(im,1)*[-0.3 1.3]);
title('Please draw a circle of ROI');
% centers = imfindcircles(im,50) 
%  mask=[]; circ=[];
circ_h = drawcircle('Color','r','FaceAlpha',0.2);
mask = false(size(im,1),size(im,2));
[x,y] = meshgrid(1:size(im,2),1:size(im,1));
mask((x-circ_h.Center(1)).^2 + (y-circ_h.Center(2)).^2 < circ_h.Radius^2 ) = true;
circ.Center = circ_h.Center;
circ.Radius = circ_h.Radius;
close(figIm)