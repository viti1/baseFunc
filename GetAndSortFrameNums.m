function [ frameNums , sortedFrameNames ]= GetAndSortFrameNums(fileNamesOrFolderName)
    input_is_filenames = iscell(fileNamesOrFolderName);
    if ~input_is_filenames
        if exist(fileNamesOrFolderName,'dir') == 7 %its a folder
            fileNamesDir = dir([fileNamesOrFolderName filesep '*.tiff']);
            fileNames = {fileNamesDir.name};
        else
            frameNums = getNum(fileNamesOrFolderName);
            return;
        end
    else
        fileNames = fileNamesOrFolderName;
    end
    
    if startsWith(fileNames{1},'Frame','IgnoreCase',true) && isstrprop(fileNames{1}(6),'digit')
        frameNums = cellfun(@(x) str2double(x(6:end-5)), fileNames);
    else
        frameNums = cellfun(@(x) getNum(x),fileNames );
    end
    [~,sort_idx] = sort(frameNums);
    if input_is_filenames
        sortedFrameNames = fileNames(sort_idx);
    else
        sortedFrameNames = fileNamesDir(sort_idx);
    end
end

function ret = getNum(str)
   ind = find(str=='_',1,'last');
   ret = str2double(str(ind+1:end-5));
end