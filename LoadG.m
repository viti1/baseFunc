function actualGain = LoadG(info,gainDataFile)

% Input :  info - struct that should contain the following fields:
%                 'nBits' 
%                 'Gain' or 'name.Gain'  
%                 'cameraSN'
%                 'cameraModel'
%          gainDataFile - .csv or .txt file that can be loaded as table, contains measured values of Gain [DU/e]
%                         have the following columns : cameraSN, gain_dB, measuredG
%                         default : [mfilelocation '\CamerasMeasuredGain.csv']
%  
% Output : actualG - the [DU] to [e] conversion constant , measured or calculated

%% Check Input
requiredFields = {'nBits' , 'cameraSN' , 'cameraModel' };
for k=1:numel(requiredFields)
    if ~isfield(info,requiredFields{k})
        error(['LoadGain: info struct must contain ' requiredFields{k} 'field'])
    end
end
if isfield(info,'name') && isfield(info.name,'Gain')
    if isfield(info,'Gain') 
        if info.Gain ~= info.name.Gain
            error('info.Gain=%g but info.name.Gain=%g',info.Gain,info.name.Gain);
        end
    else
        info.Gain = info.name.Gain;
    end
end
if isnan(str2double(info.cameraSN))
    error('wrong info.cameraSN')
end


% check gainDataFile
if ~exist('gainDataFile','var')
    gainDataFile = [fileparts(mfilename('fullpath')) filesep 'CamerasMeasuredGain.csv'];
    if ~exist(gainDataFile,'file')
        error(['Could not find measured gain data file. Expected to be : ' gainDataFile])
    end
end

%% get measured G
T = readtable(gainDataFile);
db_vs_G = T{T.nBits == info.nBits & ismember(T.cameraSN,str2double(info.cameraSN)), {'gain_dB', 'measuredG'}};

if ~isempty(db_vs_G)
% find closest gain_db in the table , then calc the actual Gain
    [~, ind_ClosestGaininTable] = min( abs(db_vs_G(:,1) - info.Gain) ) ;
    ClosestGaininTable = db_vs_G(ind_ClosestGaininTable,1);
    G_atClosestGain = db_vs_G(ind_ClosestGaininTable,2);
    actualGain =  G_atClosestGain * 10^((info.Gain-ClosestGaininTable)/20);

    if ~ismember( info.Gain,db_vs_G(:,1) )
        warning('CameraSN+nBits+Gain[dB] not in G[DU/e] table : Using Calculated G[DU/e] for that camera and nBits');
    end
else
    % calc estimated gain based on camera model
    if ~isfield(info,'cameraModel')
        error('no ''cameraModel'' field in info input struct ');
    end

    switch info.cameraModel
        case'InGaAsNIT'
            maxCapacity = 17e3;% [e]
            info.Gain = 0;
            info.nBits = 14;
        case 'acA1440-220um'  %  Basler
            maxCapacity = 10.5e3;% [e]
        case {'a2A1920-160umPRO','a2A1920-160umBAS'} % Basler
            maxCapacity = 10.4e3; %[e]
        case 'acA3088-57um'
            maxCapacity = 14.4e3;
        otherwise
            error('Unknown Camera Model')
    end
    actualGain = ConvertGain(info.Gain,info.nBits,maxCapacity);
    warning('CameraSN+nBits not in G[DU/e] table : Using Calculated G[DU/e]');
end
