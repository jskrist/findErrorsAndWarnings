function [errFound warnFound fh] = parseLine(str, fh)
%PARSELINE takes in a line from a file, evaluates whether or not that line
%contains an error or a warning, and returns cell arrays containing the
%original and modified, errors and warnings found.
%
%If an error or a warning is found it strips out any arguments, replaces
%them with 0, and then evaluates it through a call to evalChk which also
%checks to make sure the evaluated error is the one passed in to the
%function.
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

%first remove any spaces from the line
str = regexprep(str, '\s', '');

%then check the line for a comment, an error, or a warning
commentLocation = regexp(str,commentChar);
errWarnStart    = regexp(str, startStr);

%if there is a comment in the line, check to see if it is before or after
%the warning or error
if(~isempty(commentLocation))
    if(~isempty(errWarnStart))
        isCommented = max(commentLocation < errWarnStart);
    else
        isCommented = true;
    end
else
    isCommented = false;
end
%if the line is not commented and has an error or a warning
if(~isCommented && ~isempty(errWarnStart))
  %then check if the line has a line break in it
  if(~isempty(regexp(str, lineBreakCheckStr, 'once')))
    %if a linebreak exists, parse the current and next lines logically
    %look for the start of the error or warning by itself
    mat = regexp(str,                                                   ...
                 [ startStr, '(?=', msgStr, ')' ],                  ...
                 'match');
    if(~isempty(mat)) %error( or warning( did not appear by itself so check
                      %for the error and the warning with the message
      mat = regexp(str,                                                 ...
                   [ startStr, msgStr, '.*?[^(\w*:)*\)\)]'],            ...
                   'match');
      if(isempty(mat)) %[error( | warning(]message( was not found alone so
                       %check for the entire error or warning as a whole
        mat = regexp(str,                                               ...
                     '(error|warning)\(message\(.*?(\w*:)*\)\)',        ...
                     'match');
        if(isempty(mat)) %it was not found, but we know it exists, so it
                         %was not split logically
          warning('lineFromFile:NotLogicallySplit',                     ...
                  'Warning/Error was not logically split.');
        end
      else %[error( or warning(] and message( was found by itself, so set a
           %flag to trigger a recursive call to this function with two
           %lines concatonted together to try to find the error or warning
        callAgain = true;
      end
    else %error( or warning( was found by itself, so set a flag to trigger
         %a recursive call to this function with two lines concatonted
         %together to try to find the error or warning
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
      str = regexprep(str, lineBreakCheckStr, '');
      %Remove spaces in the second line
      str2 = regexprep(str2, '\s', '');
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
      mod    = regexprep(mat{i}, '(?<=\w*:\w*''?,).*?(?=[,\)])', argStr);

      if(mat{i}(1) == 'w')
        warnFound{end+1} = {mat{i}; mod};
      else
        errFound{end+1}  = {mat{i}; mod};
      end
      evalChk(mod);
    end
    if(isempty(errFound))
      errFound  = {''; ''};
    end
    if(isempty(warnFound))
      warnFound = {''; ''};
    end
  end
else
  errFound  = {''; ''};
  warnFound = {''; ''};
end
% This is the regexp which seems to work best so far:
% [ mat tok ] = regexp(a(1:end),...
%                      '(error|warning)\(message\(.*?(\w*:)*\)\)',...
%                      'match',...
%                      'tokens');
