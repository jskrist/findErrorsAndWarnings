function [errFound warnFound fh fInfo disp numErrs numWarns] =          ...
            parseLine(str, fh, fInfo, disp)
%PARSELINE takes in a line from a file, evaluates whether or not that line
%contains an error or a warning, and returns cell arrays containing the
%original and modified, errors and warnings found.
%
%If an errors or a warnings are found any arguments they have are striped
%out, and replaced with 0. Then, they are evaluated through a call to
%evalChk which checks to make sure the evaluated error or warning was the
%error or warning passed to it.
%
%This means that the errors and warnings will not be formatted like errors
%or warnings normally are, but I do not believe there is a way to evaluate 
%the ERROR command without it aborting the script or function which called
%it and I wanted the output to look uniform.

%initialize output variables
errFound  = '';
warnFound = '';
numErrs   = 0;
numWarns  = 0;

%assume we will not have to do a recursive call
callAgain = false;

%regular expressions to use which make the code easier to modify
startStr        = '(error|warning)\(';
msgStr          = 'message\(';
IdStr           = '''(\w*(:\w*){1,})'',?';
argStr          = '(((\w*(\(.*\))?)|\d*?),?){0,}';
badArgsStr      = '(?<='',.*(\(|\[)).*?[^\)],[^\(].*(?=(\)|\]).*?\){2}$)';
lineBreakChkStr = '\.\.\.';
commentChar     = '%';
%value which will replace any arguments found
argRepStr            = '0';

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
  if(~isempty(regexp(str, lineBreakChkStr, 'once')))
    %if a linebreak exists, parse the current and next lines logically

    %look for the start of the error or warning by itself
    mat = regexp(str,                                                   ...
                 [ startStr, '(?=[^', msgStr, '])' ],                   ...
                 'match');
    if(isempty(mat)) %error( or warning( did not appear by itself so check
                     %for the error and the warning with the message but
                     %without the message ID or arguments
      mat = regexp(str,                                                 ...
                   [ startStr, msgStr, '(?=[^''])'],                    ...
                   'match');
      if(isempty(mat)) %[error( | warning(]message( was not found alone so
                       %check for the error or warning with the message and
                       %ID but without arguments or an ending
        mat = regexp(str,                                               ...
                     [startStr, msgStr, IdStr, '(?=(\.\.\.|%))'],       ...
                     'match');
        if(isempty(mat)) %the line contains the error or warning, a message
                         %function and the message ID, but does not end
                         %there, so check for arguments
          mat = regexp(str,                                             ...
                       [startStr, msgStr, IdStr, argStr, '[^\){2}]'],   ...
                       'match');
          if(isempty(mat)) %the line contains the error or warning, a
                           %message function and the message ID, and
                           %may contain one or more arguments so check if
                           %it ends here (i.e. check for the whole thing)
            mat = regexp(str,                                           ...
                         [startStr, msgStr, IdStr,argStr, '\){2}'],     ...
                         'match');
            if(isempty(mat)) %it was not found, but we know it exists, so
                             %it was not split logically
              warning('lineFromFile:NotLogicallySplit',                 ...
                     ['Warning/Error was not logically split.\n'        ...
                      '> In %s at %d'],                                 ...
                      fInfo.name,                                       ...
                      fInfo.lineNum);
            end
          else %call parseLine again to check for more arguments or the end
            callAgain = true;
          end
        else %found linebreak after message ID so call parseLine again
            callAgain = true;
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
                 [startStr, msgStr, IdStr,'.*?\){2,}'],                 ...
                 'match');
  end
  if(callAgain)
    %get the next line from the file and itterate the line number counter
    str2 = fgetl(fh);
    fInfo.lineNum = fInfo.lineNum + 1;
    if(ischar(str2)) %make sure we haven't reached EOF
      %Remove the ... from the first line
      str = regexprep(str, [lineBreakChkStr, '.*'], '');
      %Remove spaces in the second line
      str2 = regexprep(str2, '\s', '');
      %concatonate the two lines and recursively call this function
      str = [str, str2];
      [errFound warnFound fh fInfo disp numErrors numWarnings] =        ...
          parseLine(str, fh, fInfo, disp);
      numErrs  = numErrs  + numErrors;
      numWarns = numWarns + numWarnings;
    else
        warning('FILE:EndedOnLineBreak', 'file ended with a linebreak');
    end
  else
    %combine all errors and warnings found then evaluate them in the
    %command window. Also, store the original and modified versions to
    %output later
    for i = 1:length(mat)
      %remove any [] or () or [,] or (,) within the arguments
      modTmp = regexprep(mat{i},badArgsStr, '0');
      %replace all arguments with argRepStr
      mod    = regexprep(modTmp,                                        ...
                         '(?<='',((.*,)?)*).*?(?=(,|\){2}$))',          ...
                         argRepStr);
      %separate the errors and warnings and store them
      if(mat{i}(1) == 'w')
        warnFound{end+1} = {mat{i}; mod};
      else
        errFound{end+1}  = {mat{i}; mod};
      end
      %evaluate and check the modified errors and warnings
      evalChk(mod, fInfo);
    end
    %don't display results by default
    disp = false;
    %if no errors were found set output to empty cell array
    if(isempty(errFound))
      errFound  = {''; ''};
    else %otherwise set display flag to true and itterate numErrs
      disp    = true;
      numErrs = numErrs + length(errFound);
    end
    %if no warnings were found set output to empty cell array
    if(isempty(warnFound))
      warnFound = {''; ''};
    else %otherwise set display flag to true and itterate numWarns
      disp     = true;
      numWarns = numWarns + length(warnFound);
    end
  end
else %line is commented or does  not contain an error or warning
  disp = false;
  errFound  = {''; ''};
  warnFound = {''; ''};
end
