folder='C:\Users\LabUser\Desktop\Tamar_Elia_Proj\24_5_24_test';
if ~exist(folder,'dir'); mkdir(folder); end
time=1*60; %in seconds
nFrames=20*time; 
[results,filename,info]=two_cams_Record(nFrames,15000,folder,'hey','by');
%%
% info=load(fullfile(folder, '\Data\info.mat'));
% results=load(fullfile(folder, '\Data\results.mat'));
%plots_folder=info.plotsFolder;
%%
DU_mat_1=results.intensity1(1:5,:);
DU_mat_2=results.intensity2(1:5,:);

time_mat=results.time(1:5,:);

avg_pixel_1=DU_mat_1(:,1)/sum(info.masks1,'all');  

num_wavelengths = 5;
wavelengths = [680;785; 808; 830; 860];
efficency = [0.47; 0.27; 0.25; 0.2; 0.15];

min_val = min(DU_mat_1(:));
max_val = max(DU_mat_1(:));
figure;
for i=1:num_wavelengths
    subplot(5,1,i);
    plot(time_mat(i,:),DU_mat_1(i,:),'.-');
    ylim([min_val, max_val]);
    xlabel('Time(sec)');
    ylabel('Power(Watt)');
    title(['Wavelength: ' num2str(wavelengths(i)) 'nm']);
end
sgtitle('DU VS time');

intensity_mat_1=zeros(size(DU_mat_1));
intensity_mat_2=zeros(size(DU_mat_2));

for i=1:5
    intensity_mat_1(i,:)=DU_mat_1(i,:)*convert_du2W(wavelengths(i)*1e-9,efficency(i),info.cam1.Gain);
    intensity_mat_2(i,:)=DU_mat_2(i,:)*convert_du2W(wavelengths(i)*1e-9,efficency(i),info.cam2.Gain);
end

figure;
min_val = min(intensity_mat_1(:));
max_val = max(intensity_mat_1(:));
for i=1:num_wavelengths
    ylim([min_val, max_val]);
    subplot(5,1,i);
    plot(time_mat(i,:),intensity_mat_1(i,:),'.-');
    xlabel('Time(sec)');
    ylabel('Power(Watt)');
    title(['Wavelength: ' num2str(wavelengths(i)) 'nm']);
end
sgtitle('Intensity VS time');

%%
len1=size(intensity_mat_1,2);
len2=size(intensity_mat_2,2);
len=min(len1,len2);

atten1=zeros(size(intensity_mat_1));
atten1=atten1(:,1:len);
atten2=zeros(size(intensity_mat_2));
atten2=atten2(:,1:len);

filterd_signal=zeros(size(intensity_mat_1));

for i = 1:num_wavelengths
    power_i_1=intensity_mat_1(i,:);
    power_i_2=intensity_mat_2(i,:);
    for l = 2:length(power_i)
        atten1(i,l) = log10(power_i_1(1)./power_i_1(l));
        atten2(i,l) = log10(power_i_2(1)./power_i_2(l));
    end
    B=pinv(atten2(i,:))*atten1(i,:); %detract the attenuetion
    filterd_signal(i,:)=atten1(i,l)-B*atten2;
end

figure;
for i = 1:num_wavelengths
    subplot(5,1,i);
    plot(time_mat(i,:),filterd_signal(i,:))
    xlabel('Time[sec]');
    ylabel('Power(dB)');
    title(['Laser ' num2str(wavelengths(i)) 'nm']);
end
sgtitle('Attenuation VS time');
%% consetration change
fig3 = figure('Units','Normalized','Position',[0 0 1 0.95],'name','HbO2 HHb oxCCO');
optode_dist = 3;  % cm - change as needed
DPF = 6.26; %adult forearm 4.16, baby head 4.99, adult head 6.26, adult leg 5.51 (Duncan et al. 1995)

% Differential Pathlength Factor
DPF_dep = stretch_DPF_Lambda_Dependency_680to915; 
laser_idx=wavelengths-679*ones(5,1);
DPF_dep = DPF_dep(laser_idx,2); 

atten_wldep=zeros(size(filterd_signal));

% take into account wavelength dependency
for k = 1:num_wavelengths    
    atten_wldep(k,:) = filterd_signal(k,:) / DPF_dep(k); 
end

ext_coeffs = tissue_specific_extinction_coefficient_650to1000;

ingred=["HbO2","HHb","Difference Cytochrome Oxidase","ox-redCCO","oxCCO"];

ext_coeffs = ext_coeffs(laser_idx,2:6);
ext_coeffs=log10(ext_coeffs);

% Invert
ext_coeffs_inv = pinv(ext_coeffs);

conc =ext_coeffs_inv * atten_wldep .* 1/(optode_dist*DPF);
min_val = min(conc(:));
max_val = max(conc(:));

for i=1:3
    subplot(3,1,i);
    plot(time_mat(i,:),conc(i,:),'.-')
    ylim([min_val, max_val]);
    xlabel('Time[sec]');
    ylabel('delta C');
    title(ingred(i))
end
sgtitle('delta C VS time');

savefig(fig3,[folder '\Components.fig']);
%%
%addpath([fileparts(fileparts(mfilename('fullpath'))) '\baseFunc']);
%savefig([fullfile(folder, 'DU VS time.fig'),fullfile(folder, 'Intensity VS time.fig'),fullfile(folder, 'Attenuation VS time.fig'),fullfile(folder, 'delta C VS time.fig')]);


%% help code
% objects = imaqfind;if numel(objects)>0; delete(objects); end