function evalChk(str, fInfo)
%This function takes in a string which contains a call to the ERROR or
%Warning function, evaluates that call and then displays the message from
%the error or warning in the command window.  It also checks whether or not
%the error or warning to be displayed is the error or warning passed in and
%if it is not, then it displays a warning.

%pull the identifier out of the error or warning
identStr = regexp(str,'(?<='').*(?='')', 'match', 'once');
%define a format strings to tell the user something meaningful in case of a
%failure
fmtStr1 = '\n\nError evaluating identifier from file %s on line %d\n';
fmtStr2 = '%s ~= %s\n\n';
  %evaluate and catch the error so we can display it
  try
    %if it is an error, then evaluate it as an error in order to catch the
    %message
    if(str(1) == 'w')
      str2 = regexp(str,'message\(.*(?=\){1,})','match');
      eval(['error(', str2{:}, ')'])
    else
      eval(str);
    end
  catch M
    %if the identifiers are not equal then something went wrong, so flag it
    %and keep going, most likely due to the identifier not being found by
    %MATLAB, not sure how to get around that
    if(~isequal(identStr, M.identifier))
      warning('Eval:Failure',                                           ...
              [fmtStr1,fmtStr2],                                        ...
              fInfo.name,                                               ...
              fInfo.lineNum,                                            ...
              M.identifier,                                             ...
              identStr);
    else %print out the error or warning message
      if(str(1) == 'e')
        fprintf('ERROR: %s\n> In %s at %d\n',                           ...
                M.message,                                              ...
                fInfo.name,                                             ...
                fInfo.lineNum);
      else
        fprintf('WARNING: %s\n> In %s at %d\n',                         ...
                M.message,                                              ...
                fInfo.name,                                             ...
                fInfo.lineNum);
      end
    end
  end
end
