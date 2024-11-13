function actualGain = GetActualGain(info)

%% Check User Input
if ~isfield(info,'cameraSN') && isfield(info.name,'CameraSN')
    info.cameraSN = num2str(info.name.CameraSN);
end

if ~isfield(info,'cameraSN') 
    error('No cameraSN data in info file');
end

%% check if there is a measured value for this camera
switch info.cameraSN
    case '40335410' % Menahem Camera
        if info.nBits == 12 
            switch info.name.Gain
                case 16
                    actualGain = 2.3427;
                case 20
                    actualGain = 3.7251;
                case 24
                    actualGain = 5.8617;
                otherwise 
                    GainAt24dB = 5.8617;
                    actualGain = GainAt24dB / 10^(24/20) * 10^(info.name.Gain/20);
            end
        elseif info.nBits == 8
           
            GainAt16dB = 0.146;
            actualGain = GainAt16dB / 10^(16/20) * 10^(info.name.Gain/20);  
        else
            error([' Camera SN' info.cameraSN ' Is 12 or 8 Bits Only']);
        end
    case '00000000' % Tomoya Camera
        if info.nBits == 12 
            GainAt16dB = NaN;  % put your value here
            actualGain = GainAt16dB / 10^(16/20) * 10^(info.name.Gain/20);
        elseif info.nBits == 8
            GainAt20dB = NaN;  % put your value here
            actualGain = GainAt20dB / 10^(20/20) * 10^(info.name.Gain/20);            
        end
    case '40335401' % Vika Camera
        if info.nBits == 8
            GainAt0dB = 0.0238;
            actualGain = GainAt0dB * 10^(info.name.Gain/20);
        end
    case '40513592' % Nadav06 a2A1920-160umPRO Camera 
        if info.nBits == 10
           GainAt16dB = 0.5846;
           actualGain = GainAt16dB * 10^((info.name.Gain-16)/20); 
        end
end


if ~exist('actualGain','var') || isempty(actualGain) || isnan(actualGain)
    if ~isfield(info,'cameraModel')
        error('no ''cameraModel'' field in info input struct ');
    end
    
    switch info.cameraModel
        case'InGaAsNIT'
            maxCapacity = 17e3;% [e]
            info.name.Gain = 0;
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
    actualGain = ConvertGain(info.name.Gain,info.nBits,maxCapacity);
    warning('Using Calculated Gain');
end