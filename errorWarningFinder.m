function [Found numRptMsgs] = errorWarningFinder(varargin)
% ERRORWARNINGFINDER finds malformed errors in MATLAB files
%
% Syntax:
%   Found = ERRORWARNINGFINDER()
%   Found = ERRORWARNINGFINDER(folderPath)
%   Found = ERRORWARNINGFINDER(folderPath,dispReport)
%   Found = ERRORWARNINGFINDER(folderPath,files)
%
% Description:
%   ERRORWARNINGFINDER() checks the current directory and its
%       subdirectories for any malformed error or warning messages.
%
%   ERRORWARNINGFINDER(folderPath) recursively checks a directory at the
%       path 'folderPath' for any malformed errors or warnings.
%
%   ERRORWARNINGFINDER(folderPath, dispReport) recursively checks a
%       directory located at 'folderPath' for any malformed errors or
%       warnings.  'dispReport' is a boolean which determines whether or
%       not a report is generated.
%
%   ERRORWARNINGFINDER(folderPath, files) checks the files in 'files', a
%       cell array of file names, in the given folder path, 'folderPath',
%       for any malformed errors or warnings.
%
%
%    Note: This function reads any MATLAB file, i.e. files which have a
%          '.m' extension, and finds any error or warning statements which
%          are UNCOMMENTED.
%
% Warning:
%    This code relies on a certain pattern to the error and warning
%    statements in the files it checks.  If the pattern is not met this
%    code will output a warning that the 'Warning/Error was not logically
%    split'.
%
%    The pattern to match is error(message('MESSAGE:ID', arg1, arg2, ...))
%    or warning(message('MESSAGE:ID', arg1, arg2, ...)).  Where there can
%    be zero or more arguments, and the statement can be split on multiple
%    lines, as long as the last '))' stays together.
%
%    It makes no assurances about finding any warnings or errors which do
%    not match the patterns above.  It will, however, find more than one
%    error or warning in a single line of code.
%
% Output:
%    If 'dispReport' is set to true, then a report is output, which states
%    how many files were looked through, and how many issues were found.
%
%    If any issues were found they are also listed.
%
%    After finding all instances of errors and warning in a file this
%    function adds two elements to a structure called 'Found'.  These
%    elements are:
%
%    a string, 'fName', which is the name of the file including the path,
%
%    a cell array, 'rptMsg', which contains messages about issues found
%    with errors or warnings found in the files.  if there were no errors
%    or warnings in the files then an empty cell array is added.
%
% See also:
%    ERROR, MESSAGE
%
% Copyright by James Kristoff 2012
%

%% Variable initialization

%Structure to track and output what we found
Found.fName  =  '';
Found.rptMsg = {''};

%Number of report messages
numRptMsgs = 0;

%Used to gather issues line by line for each file
msgs = '';

singleFileFlag = false;

%Check for inputs and go to the given directory, also set the path variable
switch length(varargin)
    case 0
        fPath = '.';
        recurrFlag = false;
    case 1
        fPath = varargin{1};
        if(strcmp(fPath(end), '\'))
            fPath(end) = '';
        end
        recurrFlag = false;
    case 2
        fPath = varargin{1};
        if(strcmp(fPath(end), '\'))
            fPath(end) = '';
        end
        if(islogical(varargin{2}))
            recurrFlag = ~varargin{2};
        else
            files          = varargin{2};
            singleFileFlag = true;
            recurrFlag     = false;
        end
    otherwise
        warning('Wrong:num:inputs',                                     ...
               ['Can only accept 0, 1, or 2 inputs.  '                  ...
                'Using current directory as the search path'])
        fPath = '.';
end
    
%% Get a list of the files and folders in the current directory
if(~singleFileFlag)
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
else
    %Create a cell array to capture all the mfiles in the directory
    mFiles = {''};
    for i= 1:size(files, 1)
        fileName = files(i,:);
        %Find MATLAB files in the current directory
        if(strcmpi(fileName{1}(end-1:end),'.m'))
            mFiles(end+1) = fileName; %#ok<*AGROW>
        end
    end
end

%% Go through all the files and look for errors and warnings
%ignore the first file which is always empty
for i = 2:length(mFiles)
    %add the path to the filename and set the line number to 0
    fInfo.name = [fPath filesep mFiles{i}];
    fInfo.lineNum = 0;

    %open the file
    f = fopen(fInfo.name);
    if(f == -1)
        error('failed to open file %s', fInfo.name);
    end
    %get a single line out of the file and itterate the line number
    str = fgetl(f);
    fInfo.lineNum = fInfo.lineNum + 1;
    %while we have not reached the end of the file
    while(ischar(str))
        %parse the line for issues
        [messages,f,fInfo,cnts] =  parseLine(str, f, fInfo);
        for j = 1:cnts
            msgs{end+1} = messages{j};
        end
        %get a new line, itterate line number
        str = fgetl(f);
        fInfo.lineNum = fInfo.lineNum + 1;
        %count number of messages to display later
        numRptMsgs = numRptMsgs + cnts;
    end
    %close file
    fclose(f);
    %Save the information about the last file
    Found(end+1).fName = [fPath filesep mFiles{i}];
    Found(end).rptMsg  = msgs;
    %reinitialize temporary variables
    msgs = '';
end

%% recursive call for all subdirectories
if(~singleFileFlag)
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
        %directories begining with @ or hidden folders which begin with .
        subDirNames(end+1) = {Dir(i).name};
      end
    end
    %make the recursive call and combine the errors and warnings found
    for i = 2:length(subDirNames)
        [recFind cnts] = errorWarningFinder([fPath, filesep,            ...
                                            subDirNames{i}],            ...
                                            false);
        numRptMsgs  = numRptMsgs + cnts;
        %combine the recursive finds with the higher level finds
        for j = 2:length(recFind)
            Found(end+1) = recFind(j);
        end
    end
end
%% format output and show results
if(~recurrFlag)
    %Create Report
    display(repmat('-',1,76)); %header solid line
    display('Begin Report');
    fprintf('Number of files searched through: %d\n', length(Found) - 1);
    fprintf('Number of Issues found: %d\n', numRptMsgs);
    % Output the issues found
    if(numRptMsgs > 0)
        fprintf('\nIssues:\n');
        for i = 2:length(Found)
            if(~isempty(Found(i).rptMsg))
                fprintf('\nFile: %s\n', Found(i).fName);
                display(repmat('*',1,76));
                for j = 1:length(Found(i).rptMsg)
                    if(~isempty(Found(i).rptMsg{j}))
                        fprintf('%s\n', Found(i).rptMsg{j});
                        display(repmat(' -',1,38));
                    end
                end
            end
        end
    end
end
