function [ mask , c ] = GetROI(im)

f=figure('units','normalized','position',[0.1 0.1 0.6 0.8]); imagesc(im); SetAxisEqual(); colormap; 
title('Please draw a circle of ROI');

% centers = imfindcircles(im,50) 
%  mask=[]; circ=[];
circ = drawcircle('Color','r','FaceAlpha',0.2);
mask = false(size(im,1),size(im,2));
[x,y] = meshgrid(1:size(im,2),1:size(im,1));
mask((x-circ.Center(1)).^2 + (y-circ.Center(2)).^2 < circ.Radius^2 ) = true;
c.Center = circ.Center;
c.Radius = circ.Radius;
close(f)