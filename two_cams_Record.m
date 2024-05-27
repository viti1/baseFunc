function [results,new_folder,info] = two_cams_Record( nOfFrames, exposure_time,folder, prefix, suffix)
%% Check functin input parameters and set defualt values for missing parameters

if ~exist('nOfFrames','var') || isempty(nOfFrames)
    nOfFrames = 500;
end

if ~exist('prefix','var')
    prefix = '';
end

if ~exist('suffix','var') 
    suffix = '';
elseif ~isempty(suffix)
    suffix=['_' suffix];
end

% check existance of parent folder
if exist('folder','var') && ~isempty(folder) && exist(fileparts(folder),'dir') ~= 7
        error('The parent folder of the destination folder must exist');
end

createVid= ~exist('vid','var') || isempty(vid);
%%
info_camera = imaqhwinfo('gentl');
SignalCam=strfind(info_camera.DeviceInfo(1).DeviceName,'acA1440-220um (40335408)');

if SignalCam
    SignalCamIdx=1;
    SculpCamIdx=2;
else
    SignalCamIdx=2;
    SculpCamIdx=1;
end

videoFormat1=info_camera.DeviceInfo(SignalCamIdx).DefaultFormat;
videoFormat2=info_camera.DeviceInfo(SculpCamIdx).DefaultFormat;

if createVid
    vid1 = videoinput("gentl",cell2mat(info_camera.DeviceIDs(SignalCamIdx)), videoFormat1);
    vid2 = videoinput("gentl",cell2mat(info_camera.DeviceIDs(SculpCamIdx)), videoFormat2);
end

vid1.FramesPerTrigger = inf; 
vid2.FramesPerTrigger = inf; 

triggerconfig(vid1, 'hardware');
triggerconfig(vid2, 'hardware');
    
src1 = getselectedsource(vid1);
src2 = getselectedsource(vid2);

%% Create info struct
info.cam1 = []; % TBD consider using only user requested + expT,Gain,FR,BL
info.cam2 = [];
mustFieldsToSave = {'Gain','BlackLevel'} ;
for field = mustFieldsToSave(:)'
    info.cam1.(field{1})= src1.(field{1});
    info.cam2.(field{1})= src2.(field{1});
end

info.cam1.('ExposureTime')= exposure_time;
info.cam2.('ExposureTime')= exposure_time;

%% Create filename from Parameters Structs

new_folder = fullfile(folder, [prefix, '_ExposureTime_', int2str(exposure_time),'_',suffix, '_', int2str(0)]);
counter = 1;
while exist(new_folder, 'dir') 
    new_folder = fullfile(folder, [prefix, '_ExposureTime_', int2str(exposure_time),'_', suffix , '_', int2str(counter)]);
    counter = counter + 1;
end

mkdir(new_folder);

data_folder = fullfile(new_folder, 'Data');
plots_folder = fullfile(new_folder, 'Plots');

mkdir(data_folder);
mkdir(plots_folder);

save([data_folder '\info.mat'],'-struct','info');

%% calc noises
 src1.TriggerMode='OFF';
 uiwait(msgbox("Turn off the laser","calc noise","warn"));
src1.ExposureTime=21;%nsec
nOfFramesForReadNoise=100;

%record nOfFrames images
WindowSize=7;
rec=RecordFromCamera(nOfFramesForReadNoise,SignalCamIdx,[],[]);
readNoisePerPixel=std(double(rec),0,3);
readNoisePerWindow=imboxfilt(readNoisePerPixel,WindowSize);
%readNoisseMean=mean2(readNoisseStd);?
clear rec;

%% calc dark noise
nOfFramesForDarkIm=500;
src1.ExposureTime=exposure_time;
rec=RecordFromCamera(nOfFramesForDarkIm,SignalCamIdx,[],[],[],[],[],[],[],0);
darkImageAvg1=mean(double(rec),3);
clear rec;
src1.TriggerMode='ON';
triggerconfig(vid1, 'hardware');

src2.TriggerMode='OFF';
src2.ExposureTime=exposure_time;
rec=RecordFromCamera(nOfFramesForDarkIm,SculpCamIdx,[],[],[],[],[],[],[],0);
darkImageAvg2=mean(double(rec),3);

clear rec;
src2.TriggerMode='ON';
triggerconfig(vid2, 'hardware');

uiwait(msgbox("Turn on the laser","finish calculating noise","warn"));

%% calc ROI of each camera
start([vid1,vid2]);

while ( vid1.FramesAvailable < 1 && vid2.FramesAvailable < 1 ); pause(0.001); end
imagesBuff = getdata(vid1,1); 
Hight=size(imagesBuff,1);
Width=size(imagesBuff,2);

rec1=double(squeeze(getdata(vid1, 2)));
rec2=double(squeeze(getdata(vid2, 2)));

%%
stop([vid1,vid2]);
flushdata([vid1,vid2]);

meanValues1 = mean(rec1, [1, 2]);
[~, maxTimeIdx1] = max(meanValues1);

meanValues2 = mean(rec2, [1, 2]);
[~, maxTimeIdx2] = max(meanValues2);

im1=rec1(:,:,maxTimeIdx1);
im2=rec2(:,:,maxTimeIdx2);

% f=figure('units','normalized','position',[0.1 0.1 0.6 0.8]); 
f = my_imagesc(im1);
xlim(Width* [-0.3 1.3])
ylim(Hight* [-0.3 1.3] )
title('draw ROI of camera 1');
circ1 = drawcircle('Color','r','FaceAlpha',0.2);
center1 = circ1.Center;
radius1 = circ1.Radius;
[X, Y] = meshgrid(1:Width, 1:Hight);
distance_from_center1 = sqrt((X - center1(1)).^2 + (Y - center1(2)).^2);
mask1 = double(distance_from_center1 <= radius1);

close(f)

f=figure('units','normalized','position',[0.1 0.1 0.6 0.8]); my_imagesc(im2); SetAxisEqual();
title('draw ROI of camera 2');
circ2 = drawcircle('Color','r','FaceAlpha',0.2);
center2 = circ2.Center;
radius2 = circ2.Radius;
[X, Y] = meshgrid(1:Width, 1:Hight);
distance_from_center2 = sqrt((X - center2(1)).^2 + (Y - center2(2)).^2);
mask2 = double(distance_from_center2 <= radius2);

close(f)

info.masks1=mask1;
info.masks2=mask2;
info.DU_per_Pixel1=sum(double(im1),'all')/sum(mask1,'all');
info.DU_per_Pixel2=sum(double(im2),'all')/sum(mask2,'all');

save([data_folder '\info.mat'],'-struct','info');
%% determine the threshold value
rec =RecordFromCamera(6,SignalCamIdx,[],[]);
intensity_vec1=zeros(1,6);
fprintf('camera %d :/n',1);

for i=1:6
    im=double(rec(:,:,i));
    fprintf('Image %d :',i);
    disp(prctile(im(mask1>0),[5,50,95]));
    intensity_vec1(i)=sum(im.*mask1-darkImageAvg1.*mask1, 'all');
end
sorted_intensity1=sort(intensity_vec1);
threshold1=mean(sorted_intensity1(1:2));
clear rec

rec =RecordFromCamera(6,SculpCamIdx,[],[]);
intensity_vec2=zeros(1,6);
fprintf('camera %d :/n',2);
for i=1:6
    im=double(rec(:,:,i));
    fprintf('Image %d :',i);
    disp(prctile(im(mask2>0),[5,50,95]));
    intensity_vec2(i)=sum(im.*mask2-darkImageAvg2.*mask2, 'all');
end
sorted_intensity2=sort(intensity_vec2);

threshold2=mean(sorted_intensity2(1:2));
clear rec
%%
colomns=ceil(nOfFrames/5);
results = struct('time',  zeros(5,colomns), 'intensity1', zeros(5,colomns), 'intensity2', zeros(5,colomns), 'speckle',  zeros(5,colomns));
% Start aquisition
h_waitbar = waitbar(0,'Recording ...');
fprintf('Recording "%s" ... \n',recName);
start([vid1,vid2]);
counter = 1;
intensity1 = Inf;
while intensity1 > threshold1 && counter < 7
    while(~vid1.FramesAvailable); end
    im1=double(squeeze(getdata(vid1, 1)));
    intensity1=sum(im1.*mask1-darkImageAvg1.*mask1, 'all');
    counter = counter +1;
end
  fprintf('counter1 = %d\n',counter);
if counter == 8 
    errordlg('Could not find dark image camera 1');
    return;
end
disp(vid2.FramesAvailable)
while(~vid2.FramesAvailable); end
rec2 = squeeze( getdata(vid2,vid2.FramesAvailable));
im2 = double(rec2(:,:,end));
intensity2=sum(im2.*mask2-darkImageAvg2.*mask2, 'all');
counter = 2;
while intensity2 > threshold2 && counter < 7
    while(~vid2.FramesAvailable); end
    im2=double(squeeze(getdata(vid2, 1)));
    intensity2=sum(im2.*mask2-darkImageAvg2.*mask2, 'all');
    counter = counter +1;
end
if counter == 8 
    errordlg('Could not find dark image camera 2');
    return;
end

temp_rec1 = nan(Hight,Width,6);
temp_rec2 = nan(Hight,Width,6);

for i=1:6
    temp_rec1(:,:,i) =double(squeeze(getdata(vid1, 1)));
    temp_rec2(:,:,i) =double(squeeze(getdata(vid2, 1)));
end

error_counter = 0;
allowedNumOfErrors = 4;

atime = tic;
fprintf('Start Recording ... \n')

for k=1:colomns+1
    fprintf(' %d ,',k);
    if mod(k,50) == 0
        fprintf('\n');
    end
    for i=1:6
        while(~vid1.FramesAvailable||~vid2.FramesAvailable); end
        
        im1 =double(squeeze(getdata(vid1, 1)));
        im2 =double(squeeze(getdata(vid2, 1)));
        intensity1=sum(im1.*mask1-darkImageAvg1.*mask1, 'all');
        intensity2=sum(im2.*mask2-darkImageAvg2.*mask2, 'all');
        
        if intensity1<threshold1 
            if intensity2>=threshold2
                error("the cameras are not syncronized");
            elseif i~=6
                if error_counter > allowedNumOfErrors
                    error("the signals are not syncronized");
                else
                    errordlg("the signals are not syncronized");
                end
                error_counter = error_counter + 1;
            end
            break;
        end
        results.time(i,k)=toc(atime);
        results.intensity1(i,k)=intensity1;
        results.intensity2(i,k)=intensity2; %currently it is a sculp avrage- nee to be changed!
        results.speckle(i,k)=1; %need to be changed!  
    end
    
    if mod(k,10)==0
        waitbar(k/colomns,h_waitbar,['Recording frame ' num2str(k)]);
    end
        
    if mod(k,20)==0 && k~=0
        save([data_folder '\results.mat'],'-struct','results');
    end
end

fprintf('\n');
waitbar(k/colomns,h_waitbar,'Saving...');
save([data_folder '\results.mat'],'-struct','results');

stop([vid1,vid2]);
delete([vid1,vid2]);

close(h_waitbar);
end