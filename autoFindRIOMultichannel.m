function [ masks, totMask, channels, fig , h_circles] = autoFindRIOMultichannel(im,approxRadius)

if ~exist('approxRadius','var')
    approxRadius = 90; 
end

%% find circles
[centersBright, radiiBright, metric] = imfindcircles(im ,round(approxRadius*[0.95 1.05]),'ObjectPolarity','bright','Sensitivity',0.993); %,'EdgeThreshold',0.3);
% my_imagesc(im); viscircles(centersBright, radiiBright,'Color','b','EnhanceVisibility',false,'LineWidth',1);

%% reduce duplicates
N = numel(radiiBright);
distances = nan(N);
checked_rows = [];
channels.Centers = nan([0 2]);
channels.Radii = [];
channels.Metric = [];
for i = 1:N    
    if ismember(i,checked_rows)
        continue;
    end
    same_circle_rows = i;
    for j = 1:N
        if j==i; continue; end
        distances(i,j) = norm(diff(centersBright([i,j],:)));
        if distances(i,j) < approxRadius
            same_circle_rows = [same_circle_rows j];
        end
    end 
    checked_rows = [ checked_rows , same_circle_rows ];

    [~, max_ind] =  max( metric(same_circle_rows) ) ; 
    max_row = same_circle_rows(max_ind);
    channels.Centers(end+1,:) = centersBright(max_row,:);
    channels.Radii(end+1)   = radiiBright(max_row);
    channels.Metric(end+1)  = metric(max_row);
end

fig = my_imagesc(im); 
h_circles = viscircles(channels.Centers, channels.Radii,'Color','y','EnhanceVisibility',false,'LineWidth',1);

% create masks
masks = cell(1,numel(channels.Radii) );
[x,y] = meshgrid(1:size(im,2),1:size(im,1));

totMask = false(size(im,1),size(im,2)); 
for k = 1:numel(channels.Radii)    
    masks{k} = false(size(im,1),size(im,2));
    masks{k}((x-channels.Centers(k,1)).^2 + (y-channels.Centers(k,2)).^2 < channels.Radii(k)^2 ) = true;
    totMask = totMask |  masks{k};
end