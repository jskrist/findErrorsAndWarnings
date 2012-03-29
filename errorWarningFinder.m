function [Found, numErrors, numWarnings] = errorWarningFinder(varargin)
%ERRORWARNINGFINDER
%
% USES:
%
%[Found, numErrors, numWarnings] = ERRORWARNINGFINDER()
%
%[Found, numErrors, numWarnings] = ERRORWARNINGFINDER(folderName)
%
%[Found, numErrors, numWarnings] = ERRORWARNINGFINDER(folderPath,recurFlag)
%
%
%ERRORWARNINGFINDER() checks the current directory and its subdirectories
%for any malformed error or warning messages.
%
%ERRORWARNINGFINDER(folderName) recursively checks a directory with the
%name folderName located in the current directory for any malformed errors
%or warnings.
%
%ERRORWARNINGFINDER(folderPath, recurFlag) recursively checks a directory
%located at folderPath for any malformed errors or warnings.  If recurFlag
%is set to false the report is output, if it is set to true the report is
%not generated.
%
%This looks through the current folder and it's subfolders recursively,
%reads any MATLAB file, i.e. files which have a '.m' extension, and finds
%any error or warning statements which are UNCOMMENTED and fit the
%following patterns:
%
%     error(message('My:Error:ID'));
%     error(message('My:Error:ID', arg1, arg2));
%     error(                                                            ...
%           message('My:Error:ID', arg1, arg2));
%     error(                                                            ...
%           message(                                                    ...
%                   'My:Error:ID', arg1, arg2));
%     error(                                                            ...
%           message(                                                    ...
%                   'My:Error:ID',                                      ...
%                   arg1, arg2));
%     error(                                                            ...
%           message(                                                    ...
%                   'My:Error:ID',                                      ...
%                   arg1,                                               ...
%                   arg2));
%     error(                                                            ...
%           message(                                                    ...
%                   'My:Error:ID',                                      ...
%                   arg1,                                               ...
%                   arg2                                                ...
%                   ));
%
%   warning(message('My:Error:ID'));
%   warning(message('My:Error:ID', arg1, arg2));
%   warning(                                                            ...
%           message('My:Error:ID', arg1, arg2));
%   warning(                                                            ...
%           message(                                                    ...
%                   'My:Error:ID', arg1, arg2));
%   warning(                                                            ...
%           message(                                                    ...
%                   'My:Error:ID',                                      ...
%                   arg1, arg2));
%   warning(                                                            ...
%           message(                                                    ...
%                   'My:Error:ID',                                      ...
%                   arg1,                                               ...
%                   arg2));
%   warning(                                                            ...
%           message(                                                    ...
%                   'My:Error:ID',                                      ...
%                   arg1,                                               ...
%                   arg2                                                ...
%                   ));
%
%
%It makes no assurances about finding any warnings or errors which do not
%match the patterns above or logical extensions of the above patterns.  It
%will, however, find more than one error or warning in a single line of
%code, which could happen, but is poor style.
%
%After finding all instances of errors and warning in a file this function
%adds four elements to a structure called 'Found'.  These elements are:
%
%   a string, 'fName', which is the name of the file including the path,
%
%   a cell array, 'errors', which contain the modified and original errors
%   found in the file, if there were no errors in the file, then an empty
%   cell array is added
%
%   a cell array, 'warns', which contain the modified and original warnings
%   found in the file, if there were no warnings in the file, then an empty
%   cell array is added
%
%   a number, disp, which indicates if it needs to be displayed or not.  It
%   is a count of all errors and warnings found in the file, so if it is
%   equal to 0 then there is no need to display the empty output
%

%% Variable initialization

%Structure to track and output what we found
Found.fName  =  '';
Found.errors = {''};
Found.warns  = {''};
Found.disp   = 0;

%Used to gather errors and warnings line by line for each file
errStr  = '';
warnStr = '';

%counters for errors and warnings
numErrors = 0;
numWarnings  = 0;

%Check for inputs and go to the given directory, also set the path variable
switch length(varargin)
    case 0
        fPath = '.';
        recurrFlag = false;
    case 1
        fPath = ['.' filesep varargin{1}];
        recurrFlag = false;
    case 2
        if(islogical(varargin{2}))
            fPath      = varargin{1};
            recurrFlag = varargin{2};
        else
            fPath = [varargin{1} filesep varargin{2}];
        end
    otherwise
        warning('Wrong:num:inputs',                                     ...
               ['Can only accept 0, 1, or 2 inputs.  '                  ...
                'Using current directory as the search path'])
        fPath = '.';
end
    
%% Get a list of the files and folders in the current directory

%Directory structure
dList = dir(fPath);

%Logical array for indexing all directories
subDirIdx = [dList.isdir];
%Files in the current directory are anything NOT a directory
files = dList(~subDirIdx);
%Create a cell array to capture all the mfiles in the directory
mFiles = {''};
for i= 1:length(files)
    fileName = files(i).name;
    %Find MATLAB files in the current directory
    if(strcmpi(fileName(end-1:end),'.m'))
        mFiles(end+1) = {fileName}; %#ok<*AGROW>
    end
end

%% Go through all the files and look for errors and warnings
%ignore the first file which is always empty
for i = 2:length(mFiles)
    %add the path to the filename and set the line number to 0
    fInfo.name = [fPath filesep mFiles{i}];
    fInfo.lineNum = 0;
    show = false; %works with disp to ensure there is an accurate account
                  %of which files need to be displayed
    %open the file
    f = fopen(fInfo.name);
    %get a single line out of the file and itterate the line number
    str = fgetl(f);
    fInfo.lineNum = fInfo.lineNum + 1;
    %while we have not reached the end of the file
    while(~feof(f))
        %parse the line for the error or warning
        [errStr{end+1} warnStr{end+1} f fInfo disp numErrs numWarns] =  ...
            parseLine(str, f, fInfo, show);
        %get a new line, itterate line number and sum the new disp with the
        %old show
        str  = fgetl(f);
        fInfo.lineNum = fInfo.lineNum + 1;
        show = show + disp;
        %count errors and warnings to display them later
        numErrors   = numErrors   + numErrs;
        numWarnings = numWarnings + numWarns;
    end
    %close file
    fclose(f);
    %Save the information about the last file
    Found(end+1).fName = [fPath filesep mFiles{i}];
    Found(end).errors  = errStr;
    Found(end).warns   = warnStr;
    Found(end).disp    = show;
    %reinitialize temporary variables
    errStr  = '';
    warnStr = '';
end

%% recursive call for all subdirectories

%find the subDirectories' names
Dir         =  dList(subDirIdx);   %pull out only the directories
subDirNames = {''};                %initialize cell array
%for all directories
for i = 1:length(Dir)
  %store name to temporary variable so we can index it
  dirName = Dir(i).name;
  if(dirName(1) ~= '@' && dirName(1) ~= '.')
    %put all the names into an array, this excludes the current and
    %previous directory symbols, . and .. as well as any linked
    %directories which begin with @ or hidden folders which begin with .
    subDirNames(end+1) = {Dir(i).name};
  end
end
%make the recursive call and combine the errors and warnings found
for i = 2:length(subDirNames)
    [recFind numErrs numWarns] = errorWarningFinder([fPath, filesep,    ...
                                                     subDirNames{i}],   ...
                                                     true);
    numErrors   = numErrors   + numErrs;
    numWarnings = numWarnings + numWarns;
    %combine the recursive finds with the higher level finds
    for j = 2:length(recFind)
        Found(end+1) = recFind(j);
    end
end

%% format output and show results
if(~recurrFlag)
    %Number of files
    numFilesLookedAt = length(Found) - 1;
    %Create Report
    display(repmat('-',1,76)); %header solid line
    display('Begin Report');
    fprintf('Number of files searched through: %d\n', numFilesLookedAt);
    fprintf('Number of Errors found: %d\n',   numErrors);
    fprintf('Number of Warnings found: %d\n', numWarnings);
%% Uncomment this section to report the original and modified errors and
%warnings found
%
%     for i = 2:length(Found)
%         if(Found(i).disp ~= 0)
%             fprintf('\nFile: %s\n', Found(i).fName);
%             fprintf('\nErrors:\n');
%             for j = 1:length(Found(i).errors)
%                 for k = 1:length(Found(i).errors{j})
%                   if(~isempty(Found(i).errors{j}{k}))
%                       display(repmat(' -',1,38));
%                       fprintf('Original: %s\n', Found(i).errors{j}{k}{1});
%                       fprintf('Modified: %s\n', Found(i).errors{j}{k}{2});
%                       display(repmat(' -',1,38));
%                   end
%                 end
%             end
%             fprintf('\nWarnings:\n');
%             for j = 1:length(Found(i).warns)
%                 for k = 1:length(Found(i).warns{j})
%                   if(~isempty(Found(i).warns{j}{k}))
%                       display(repmat('- --',1,19));
%                       fprintf('Original: %s\n', Found(i).warns{j}{k}{1});
%                       fprintf('Modified: %s\n', Found(i).warns{j}{k}{2});
%                       display(repmat('- --',1,19));
%                   end
%                 end
%             end
%         end
%     end
end
