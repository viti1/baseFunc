rec=RecordFromCamera(6,2);


f=figure('units','normalized','position',[0.1 0.1 0.6 0.8]); my_imagesc(rec(:,:,1)); SetAxisEqual();
title('draw ROI of camera 1');
circ1 = drawcircle('Color','r','FaceAlpha',0.2);
center1 = circ1.Center;
radius1 = circ1.Radius;
[W,H]=size(rec(:,:,1));
[X, Y] = meshgrid(1:H, 1:W);
distance_from_center1 = sqrt((X - center1(1)).^2 + (Y - center1(2)).^2);
mask1 = double(distance_from_center1 <= radius1);

for i=1:6
    im=double(rec(:,:,i));
%     my_imagesc(im);
    title(['Im',num2str(i)])
    fprintf('Image %d :',i);
    disp(prctile(im(mask1>0),[5,50,95]));
end