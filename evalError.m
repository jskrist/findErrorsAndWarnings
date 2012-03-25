function evalChk(str)
%This function takes in a string which contains a call to the ERROR or
%Warning function, evaluates that call and then displays the message from
%the error or warning in the command window

%pull the identifier out of the error or warning
identStr = regexp(str,'(?<='').*(?='')', 'match', 'once');
%define a format string to tell the user something meaningful in case of a
%failure
fmtStr = '\n\nidentifiers in %s on line %d do not match: \n%s ~= %s\n\n';
%evaluate and catch the error or warning so we can display it
  try
    eval(str);
  catch M
    disp(M.message);
    %if the identifiers are not equal then something went wrong, so flag it
    %and keep going
    if(~isequal(identStr{:}, M.identifier))
      st = dbstack;
      str = sprintf(fmtStr,            ...
                    M.stack(1,1).name,...
                    st(1).line,        ...
                    M.identifier,     ...
                    identStr{:});
      warning('Evaluation:Failure', str);
    end
  end
end
