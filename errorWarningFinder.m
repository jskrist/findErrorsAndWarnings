function [Found] = errorWarningFinder(varargin)
%This looks through the current folder and it's subfolders recursively,
%reads any MATLAB file, i.e. files which have a '.m' extension, and finds
%any error or warning statements which are in UNCOMMENTED lines and fit
%the following patterns:
%
%     error(message('My:Error:ID'));
%     error(message('My:Error:ID', arg1, arg2));
%     error(...
%           message('My:Error:ID', arg1, arg2));
%     error(...
%           message(...
%                   'My:Error:ID', arg1, arg2));
%     error(...
%           message(...
%                   'My:Error:ID',...
%                   arg1, arg2));
%     error(...
%           message(...
%                   'My:Error:ID',...
%                   arg1,...
%                   arg2));
%
%   warning(message('My:Error:ID'));
%   warning(message('My:Error:ID', arg1, arg2));
%   warning(...
%           message('My:Error:ID', arg1, arg2));
%   warning(...
%           message(...
%                   'My:Error:ID', arg1, arg2));
%   warning(...
%           message(...
%                   'My:Error:ID',...
%                   arg1, arg2));
%   warning(...
%           message(...
%                   'My:Error:ID',...
%                   arg1,...
%                   arg2));
%
%
%It makes no assurances about finding any warnings or errors which do not
%match the patterns above or logical extensions of the above patterns.  It
%also does not look for more than one error or warning in a single line of
%code, which could happen, but is poor style.
%
%After finding all instances of errors and warning in a file this function
%adds three elements to a structure called 'Found'.  These elements are:
%
%   a string, 'fName', which is the name of the file including the path,
%
%   a cell array, 'errors', which contain the errors found in the file, if
%   there were no errors in the file, then an empty cell array is added
%
%   a cell array, 'warns', which contain the warnings found in the file, if
%   there were no warnings in the file, then an empty cell array is added
%

%% Variable initialization

%Structure to track and output what we found
Found.fName  =  '';
Found.errors = {''};
Found.warns  = {''};

%Used to gather errors and warnings line by line for each file
errStr  = '';
warnStr = '';

output = false;

%Check for inputs and go to the given directory, also set the path variable
switch length(varargin)
    case 0
        fPath = '.';
        output = true;
    case 1
        fPath = ['.' filesep varargin{1}];
    case 2
        fPath = [varargin{2} filesep varargin{1}];        
    otherwise
        warning('Wrong:num:inputs',                                     ...
               ['Can only accept 0, 1, or 2 inputs.  '                  ...
                'Using current directory as the search path'])
end
    
%% Get a list of the files and folders in the current directory

%Directory structure
dList = dir(fPath);

%Logical array for indexing
subDirIdx = [dList.isdir];
%Find MATLAB files in the current directory
%Files in the current directory
files = dList(~subDirIdx);
%Create a cell array to capture all the mfiles in the directory
mFiles = {''};
for i= 1:length(files)
    fileName = files(i).name;
    if(strcmpi(fileName(end-1:end),'.m'))
        mFiles(end+1) = {fileName};
    end
end

%% Go through all the files and look for errors and warnings
for i = 2:length(mFiles)
    %open the file
    f = fopen([fPath filesep mFiles{i}]);
    %get a single line out of the file
    str = fgetl(f);
    %while we have not reached the end of the file
    while(~feof(f))
        %parse the line for the error or warning
        [errStr{end+1} warnStr{end+1} f] = parseLine(str, f);
        str = fgetl(f);
    end
    fclose(f);
    %Save the information about the last file
    Found(end+1).fName = [fPath filesep mFiles{i}];
    Found(end).errors  = errStr;
    Found(end).warns   = warnStr;
    %reinitialize temporary variables
    errStr  = '';
    warnStr = '';
end

%% recursive call for all subdirectories

%find the subDirectories' names
Dir         =  dList(subDirIdx);   %pull out only the directories
subDirNames = {Dir(3:end).name};   %put all the names into an array,
                                   %excluding the current and previous
                                   %directory symbols, . and ..

%make the call and combine the errors and warnings found
for i = 1:length(subDirNames)
    recFind = errorWarningFinder(subDirNames{i}, fPath);
    %combine the recursive finds with the higher level finds
    for j = 2:length(recFind)
        Found(end+1) = recFind(j);
    end
end


%% format output and show results
if(output)
    %Number of files
    numFilesLookedAt = length(Found) - 1;
    %Create Report
    display(repmat('-',1,76));
    display('Begin Report');
    fprintf('Number of files searched through: %d\n', numFilesLookedAt);
    for i = 2:length(Found)
        fprintf('\nFile: %s\n', Found(i).fName);
        fprintf('\nErrors:\n');
        for j = 1:length(Found(i).errors)
            if(~isempty(Found(i).errors{j}{1}))
                display(repmat(' -',1,38));
                fprintf('Original: %s\n', Found(i).errors{j}{1}{1});
                fprintf('Modified: %s\n', Found(i).errors{j}{1}{2});
                display(repmat(' -',1,38));
            end
        end
        fprintf('\nWarnings:\n');
        for j = 1:length(Found(i).warns)
            if(~isempty(Found(i).warns{j}{1}))
                display(repmat('- --',1,19));
                fprintf('Original: %s\n', Found(i).warns{j}{1}{1});
                fprintf('Modified: %s\n', Found(i).warns{j}{1}{2});
                display(repmat('- --',1,19));
            end
        end
    end
end
