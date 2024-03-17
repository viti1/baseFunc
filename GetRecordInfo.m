function info = GetRecordInfo(recordName)
    if ~exist(recordName,'file')
        error('Record "%s" does not exist',recordName);
    end
    
    if exist(recordName,'file') == 7 % it's a folder
        infoFilename = fullfile(recordName,'info.mat');
    else % its a file        
        infoFilename = [recordName(1:find(recordName=='.',1,'last')-1),'_info.mat'];
    end
    if exist(infoFilename,'file')
        info = load(infoFilename);
    end
    info.name = GetParamsFromFileName(recordName);
    
    
    
