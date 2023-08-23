%% [totBP, spatialBP, temporalBP] = FindBadPixels(rec,thresholdSpatRel,thresholdTempRel, window)
%
%
%
%
%

function [totBP, spatialBP, temporalBP] = FindBadPixels(rec,threshSpatAbs,threshTempNumOfStd, threshTempAbs, window)
    rec = double(rec);
       
    if nargin < 3 || isempty(threshTempNumOfStd) % rellevant only if threshTempAbs is missing or empty
        threshTempNumOfStd = 4; %  4 std above average
    end
    
    if nargin < 5 || isempty(window)
        window = 5;
    end
%% Temporal Bad Pixels
    if size(rec,3) < 2  %  3D
       temporalBP = false([size(rec,1) size(rec,2)]); 
    else
       if size(rec,3) < 10
           error('must have at least 10 frames for temporal bad pixels recognition');
       end
       
       tmpNoiseMat = std(rec,0,3);

       if exist('threshTempAbs','var') && ~isempty(threshTempAbs)
           temporalBP =  tmpNoiseMat > threshTempAbs;
       else % use fixed percentage of temporal bad pixels
%            [pdf,edges_pdf] = histcounts(a,1000);
%            figure; plot(edges_pdf(1:end) + diff(edges_pdf(1:2)/2) , pdf); title(['Temporal Noise , std = ' num2str(std(tmpNoiseMat(:)))]);

%            [cdf,edges] = histcounts(a,1000,'Normalization', 'cdf');
%            threshTempAbs = edges( find( cdf > (1-threshTempPercent) ,1 ));

           temporalBP =  tmpNoiseMat > median(tmpNoiseMat(:)) + ( threshTempNumOfStd * std(tmpNoiseMat(:)) );
       end
    end 

%% Spatial Bad Pixels
    if nargin < 2 || isempty(threshSpatAbs)
        threshSpatAbs = 0.1 * mean2(rec(:,:,1));
    end
    
    im = mean(rec,3);
    hp_im = im - medfilt2(im,window*[1,1], 'symmetric' );
    spatialBP = abs(hp_im) > threshSpatAbs;
    
%% Total Bad Pixels Map
totBP = spatialBP | temporalBP ;
end