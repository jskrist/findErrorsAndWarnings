function [errFound warnFound fh] = parseLine(str, fh)
%PARSELINE takes in a line from a file, evaluates whether or not that line
%contains an error or a warning, and returns cell arrays containing the
%original and modified errors and warnings found.
%
%If an error or a warning is found it strips out any arguments, replaces
%them with 0, and then evaluates it through a call to evalError if it is an
%error and through a call to eval if it is a warning.
%
%This means that the errors will not be formatted like errors, but I do not
%believe there is a way to evaluate the ERROR command without it aborting
%the script or function which called it.

%initialize output variables
errFound  = '';
warnFound = '';

%assume we will not have to do a recursive call
callAgain = false;

%regular expressions to use which make the code easier to modify
startStr          = '(error|warning)\(';
msgStr            = 'message\(';
lineBreakCheckStr = '\.\.\.';
commentChar       = '%';
argStr            = '0';
%first check that the line is not a comment and that it has an error or
%warning in it

commentLocation = regexp(str,commentChar);
errWarnStart    = regexp(str, startStr);

if(~isempty(commentLocation))
    if(~isempty(errWarnStart))
        isCommented = max(commentLocation < errWarnStart);
    else
        isCommented = true;
    end
else
    isCommented = false;
end

if(~isCommented && ~isempty(errWarnStart))
  %then check if the line has a line break in it
  if(~isempty(regexp(str, lineBreakCheckStr, 'once')))
    %if a linebreak exists, parse the current and next lines logically
    %look for the start of the error or warning by itself
    mat = regexp(str,                                                   ...
                 [ startStr, '.*?[^', msgStr, '.*]' ],                  ...
                 'match');
    if(isempty(mat)) %error( or warning( did not appear by itself
      mat = regexp(str,                                                 ...
                   [ startStr, msgStr, '.*?[^(\w*:)*\)\)]'],            ...
                   'match');
      if(isempty(mat)) %[error( | warning(]message( was not found alone
        mat = regexp(str,                                               ...
                     '(error|warning)\(message\(.*?(\w*:)*\)\)',        ...
                     'match');
        if(~isempty(mat))
          warning('lineFromFile:NotLogicallySplit',                     ...
                  'Warning/Error was not logically split.');
        end
      else %[error( or warning(] and message( was found by itself, so pass
           %back a value to the calling function to trigger it to send this
           %function two lines concatonted together in order to find the
           %error or warning
           callAgain = true;
      end
    else %error( or warning( was found by itself, so pass back a value
         %to the calling function to trigger it to send this function
         %two lines concatonted together in order to find the error or
         %warning
      callAgain = true;
    end
  else %there is not a line break; check for whole warnings and errors
    mat = regexp(str,                                                   ...
                 '(error|warning)\(message\(.*?(\w*:)*\)\)',            ...
                 'match');
  end
  if(callAgain)
    %get the next line from the file
    str2 = fgetl(fh);
    if(ischar(str2))
      %Remove the ... from the first line
      str = regexprep(str, ['\s*?',                                     ...
                            lineBreakCheckStr,                          ...
                            '\s*?'], '');
      %Remove leading or trailing spaces in the second line
      str2 = regexprep(str2, '(^( *?)|( *?)$', '');
      %concatonate the two lines and recall this function
      str = [str, str2];
      [errFound warnFound fh] = parseLine(str, fh);
    else
        warning('FILE:EndedOnLineBreak', 'file ended with a linebreak');
    end
  else
    %combine all errors and warnings found
    %remove any spaces from the errors and warnings, remove any arguments
    %and replace them with 0, then evaluate them in the command window.
    %Also, store the original and modified versions to output later
    for i = 1:length(mat)
      mat{i} = regexprep(mat{i}, '\s*?', '');
      mod    = regexprep(mat{i}, '(?<=\w*:\w*,).*(?=(,|\)))', argStr);
      
      if(mat{i}(1) == 'w')
        warnFound{end+1} = {mat(i); mod};
        eval(mod);
      else
        errFound{end+1}  = {mat(i); mod};
        evalError(mod);
      end
    end
  end
  %************************************************************************
  % replace Params from Errors or Warnings with zeros, store the originals
  %in a structure like errFound{{original; modified}} along with the
  %modified Errors and Warnings
else
  errFound  = {''; ''};
  warnFound = {''; ''};
end
% This is the regexp which seems to work best so far:
% [ mat tok ] = regexp(a(1:end),...
%                      '(error|warning)\(message\(.*?(\w*:)*\)\)',...
%                      'match',...
%                      'tokens');
