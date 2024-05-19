function [results,filename,info] = Record_Intensity_Speckles( nOfFrames, camParams, setupParams, folder, prefix, suffix, overwriteFlag, plotFlag, vid )
%% Check functin input parameters and set defualt values for missing parameters

if ~exist('nOfFrames','var') || isempty(nOfFrames)
    nOfFrames = 1;
end
 
if ~exist('camParams','var') || isempty(camParams)
    camParams = struct();
elseif ~isstruct(camParams)
    error('camParams shold be a struct!')
end

if ~exist('setupParams','var') || isempty(setupParams)
    setupParams = struct();
elseif ~isstruct(setupParams)
    error('setupParams shold be a struct!')
end

if ~exist('prefix','var')
    prefix = '';
end

if ~exist('suffix','var') 
    suffix = '';
elseif ~isempty(suffix)
    suffix=['_' suffix];
end


if ~exist('forceWrite','var') || isempty(overwriteFlag)
    overwriteFlag = false;
end

if ~exist('plotFlag','var') || isempty(plotFlag)
    plotFlag = true;
    figHandle = figure('name','Record Image');
else
    if isequal(plotFlag,true)
        figHandle = figure('name','Record Image');
    elseif isequal(plotFlag,false)
        % do nothing
    elseif isgraphics(plotFlag,'figure')
        figHandle =  plotFlag;
        plotFlag = true;
    else 
        error('Wrong input for plotFlag - must be true/false or a figure handle')
    end
end

% check existance of parent folder
if exist('folder','var') && ~isempty(folder) && exist(fileparts(folder),'dir') ~= 7
        error('The parent folder of the destination folder must exist');
end

createVid= ~exist('vid','var') || isempty(vid);

%% Create vid and set Camera parameters
if ~isfield(camParams,'videoFormat') 
    if ~createVid
        videoFormat = vid.VideoFormat;
        if ~ismember({'Mono8','Mono12'},videoFormat)
            error(['Unexpected video format "' videoFormat '"']);
        end
    else
        videoFormat = 'Mono8';
    end
elseif ~ismember({'Mono8','Mono12'},camParams.videoFormat)
    error(['Video format "' camParams.videoFormat '" is not supported. Must be "Mono8" or "Mono10"'])
else
    videoFormat = camParams.videoFormat;
end

if createVid
    vid = videoinput("gentl", 1, videoFormat);
end

vid.FramesPerTrigger = inf; 
src = getselectedsource(vid);

camInputFields = fieldnames(camParams); 
camInputFields(ismember(camInputFields,{'addToFilename','videoFormat'})) = [];
camOriginalFields = fieldnames(src);
if ~all(ismember(camInputFields,camOriginalFields))
    disp('camera src struct fields : ')
    disp(camOriginalFields)
    badFields = strjoin(camInputFields(~ismember(camInputFields,camOriginalFields)));
    delete(vid)
    error(['camParams should have only legit fields for camera src struct. The following field are not exceptable :' badFields ])
end

% set camera parameters
if ( isfield(camParams,'TriggerMode') &&  strcmpi(camParams.TriggerMode,'On') ) || strcmpi(src.TriggerMode,'On')
    triggerconfig(vid, 'hardware');
end

if ~isempty(camInputFields)
    for field = camInputFields(:)'
        if strcmp(field{1},'addToFilename'); continue; end
        if ischar(camParams.(field{1}))
             fprintf('Setting %s = %s\n',field{1},camParams.(field{1}));
        else
            fprintf('Setting %s = %g\n',field{1},camParams.(field{1}));
        end
        src.(field{1}) = camParams.(field{1});  
    end    

    if isfield(camParams,'AcquisitionFrameRate') 
         src.AcquisitionFrameRateEnable = 'True'; 
    end
end

%% Create filename from Parameters Structs
if exist('folder','var') && ~isempty(folder)
    [filename, recName] = GenerateFileName(folder,camParams,setupParams,prefix,suffix,overwriteFlag,src);
else
    [filename, recName] = GenerateFileName('',camParams,setupParams,prefix,suffix,overwriteFlag,src);
end

%% Create info struct
if isfield(camParams,'addToFilename'); camParams = rmfield(camParams,'addToFilename'); end
if isfield(setupParams,'addToFilename'); setupParams = rmfield(setupParams,'addToFilename'); end

info.cam = camParams; % TBD consider using only user requested + expT,Gain,FR,BL
mustFieldsToSave = {'Gain','ExposureTime','BlackLevel','AcquisitionFrameRate'} ;
for field = mustFieldsToSave(:)'
    if ~isfield(camParams,field{1})
        info.cam.(field{1})= src.(field{1});
    end
end
info.setup = setupParams;

%% Get images Sequence from Camera
fprintf('Recording "%s" ... \n',recName);
start(vid);

%allocate 
fprintf('%d',vid.FramesAvailable);
while(~vid.FramesAvailable); pause(0.001); end

im1 = double(squeeze(getdata(vid, 1)));
im2 = double(squeeze(getdata(vid, 1)));

avg_im1 = mean(im1(:));
avg_im2 = mean(im2(:));

if avg_im1 > avg_im2
    im=im1;
else
    im=im2;
end

f=figure('units','normalized','position',[0.1 0.1 0.6 0.8]); imagesc(im); SetAxisEqual();
title('Please draw a circle of ROI');
circ = drawcircle('Color','r','FaceAlpha',0.2);
mask = false(size(im,1),size(im,2));
[x,y] = meshgrid(1:size(im,2),1:size(im,1));
mask((x-circ.Center(1)).^2 + (y-circ.Center(2)).^2 < circ.Radius^2 ) = true;

close(f)

%choose ROI
%mask=findMask(im);

% Start aquisition
h_waitbar = waitbar(0,'Recording ...');

%Sound Setting
fs = 44100; % Sampling frequency (Hz)
t = 0:1/fs:1; % Time vector (1 second)
freq = [700,400]; % Frequency of the sine wave (Hz)
amplitude = 0.4; % Amplitude of the sine wave
freq_i = 3;
beepFlag = exist('beepInterval','var');

colomns=ceil(nOfFrames/5);
results = struct('time',  zeros(5,colomns), 'intensity', zeros(5,colomns), 'speckle',  zeros(5,colomns));

intensity_vec=zeros(1,6);
for i=1:6
    im =squeeze(getdata(vid, 1));
    intensity_vec(i)=sum(im(mask));
end
[sortedVec, sortedIdx] = sort(intensity_vec,'descend');
threshold=sortedVec(5)/5;


tic;
for k=1:colomns
    for i=sortedIdx
        if vid.FramesAvailable
            fprintf('image "%d" ... \n',(k-1)*6+i);
            im =double(squeeze(getdata(vid, 1)))8;
            intensity=sum(im(mask));
            
            if intensity<threshold 
                if ~i==6
                    fpeintf('problem :(');
                else
                    continue;
                end
            end
            results.time(i,k)=toc;
            results.intensity(i,k)=intensity;
            
            if mod(k,10)==0 
                waitbar(k/nOfFrames,h_waitbar,['Recording frame ' num2str(k)]);
            end
            
            if beepFlag && mod((k-1)*6+i,beepInterval)==0               
                sound(amplitude * sin(2*pi*freq(freq_i)*t), fs);
                freq_i = freq_i + 1;9
                if freq_i >  length(freq); freq_i=1; end
            end
        end
    end
end
fprintf('\n');
%disp(['src.AcquisitionFrameRate = ' num2str(src.AcquisitionFrameRate)] );

stop(vid);
if createVid; delete(vid); end

waitbar(k/nOfFrames,h_waitbar,'Saving...');
%% Plot
% if plotFlag
%     
%     set(figHandle,'name',recName);
%     figure(figHandle);
%     imagesc(rec(:,:,end)); colormap gray;
%     axis equal
%     imageAx = gca;
%     imageAx.XLim = [0 size(rec,2)];
%     imageAx.YLim = [0 size(rec,1)];
%     title({recName ; sprintf('frame %d',size(rec,3))},'FontSize',10,'interpreter','none');
%     colorbar;
% end

%% Save Recording
if exist('folder','var') && ~isempty(folder)
    % -- create folder if needed
    if ~exist(folder,'dir')||~strcmp(folder, filename)
        mkdir(filename);
    end    
    save([filename '\result.mat'],'-struct','info');
    save([filename '\info.mat'],'-struct','info');
end
close(h_waitbar);

end
%%
function [fullName, recName] = GenerateFileName(folder,camParams,setupParams,prefix,suffix,forceWrite,src)
    mustFieldsForFilename = {'Gain','ExposureTime'};
    for field = mustFieldsForFilename(:)'
        if ~isfield(camParams,field{1})
            camParams.(field{1})= src.(field{1});
        end
    end
    camParamsStr   = Struct2String(camParams,CamParamsLUT());
    setupParamsStr = Struct2String(setupParams,SetupParamsLUT);
        
    recNameBase = sprintf('%s%s%s%s',prefix,setupParamsStr,camParamsStr,suffix);
    if isempty(recNameBase)
        error('Record name cannot be empty! Please specify prefix/suffix or enable parameters in the name');
    end
    if isempty(prefix) && recNameBase(1)=='_'
        recNameBase(1) = []; 
    end

    if forceWrite
        if exist([folder '\' recNameBase '.avi'],'file')
            delete([folder '\' recNameBase '.avi']);
        elseif exist([folder '\' recNameBase ],'file')                
            delete([folder '\' recNameBase ]);
        end
        recName = recNameBase;
    else
        pattern = [regexptranslate('escape', recNameBase), '_(\d+)(.avi)?$'];

        samefiles = dir([folder '\' recNameBase '_*']);
        if ~isempty(samefiles)
            samefiles = samefiles([samefiles.isdir] | cellfun(@(x) endsWith(x,',avi'), {samefiles.name} ,'UniformOutput',true)); % filter only folders and .avi files
            samefiles = { samefiles(cellfun(@(x) ~isempty(regexp(x, pattern,'once')), {samefiles.name} ,'UniformOutput',true)).name } ; % find files with the same name but different index
            filesIndices = [];
            for filename=samefiles(:)'
                match = regexp(filename{1}, pattern,'tokens');
                filesIndices = [ filesIndices, str2double(match{1}{1}) ]; %#ok<AGROW>
            end
            if isempty(filesIndices)
                newIndex = 0;
            else
                newIndex = max(filesIndices)+1;
            end
            if newIndex > 999
                error(['Too many records with the same name "' folder '\' recNameBase '"' ] );
            end
        else
            newIndex = 0;
        end
        newIndexStr = sprintf('%0*d',3,newIndex);
        recName = [recNameBase '_' newIndexStr];
    end

    fullName = fullfile(folder,recName);
end

function  [lut, name_out , units ] = CamParamsLUT(name_in)
    % Create lut
    lut = { 'ExposureTime'          , 'expT'   , 'us' ;...
            'AcquisitionFrameRate'  , 'FR'     , 'Hz' ;...
            'BlackLevel'            , 'BL'     , 'DU' ;...
            'Gain'                  , 'Gain'   , 'dB' ;...
          };
    
    % Check lut first column uniqueness 
    if  numel(unique(lut(:,1))) ~= size(lut,1)
        error('Values in first column of CamParamsLut should be unique!')
    end
    
    % Extract param from lut  
    if nargin > 0
        ind = ismember(lut(:,1),name_in);
        if numel(ind) == 0
            name_out = name_in;
        elseif numel(ind) > 1
            error('Two identical entries in lut table');
        else
            name_out = lut(ind,2);
            units    = lut(ind,3);
        end
    else
        name_out = '';
        units = '';
    end
end

function  [lut, name_out, units ] = SetupParamsLUT(name_in)
    % Create lut
    lut = { 'Lens'                  , 'Lens'   , 'mm' ;...
            };
    
    % Check lut first column uniqueness 
    if  numel(unique(lut(:,1))) ~= size(lut,1)
        error('Values in first column of CamParamsLut should be unique!')
    end
    
    % Extract param from lut  
    if nargin > 0
        ind = ismember(lut(:,1),name_in);
        if numel(ind) == 0
            name_out = name_in;
        elseif numel(ind) > 1
            error('Two identical entries in lut table');
        else
            name_out = lut(ind,2);
            units    = lut(ind,3);
        end
    else
        name_out = '';
        units = '';
    end
end

%% help code
% objects = imaqfind;if numel(objects)>0; delete(objects(1)); end