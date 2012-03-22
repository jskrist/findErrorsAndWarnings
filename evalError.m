function evalError(str)
%This function takes in a string which contains a call to the ERROR
%function, evaluates that error and then displays the message from the
%error in the command window

%pull the identifier out of the error
identStr = regexp(str,'(?<='').*(?='')', 'match');
%define a format string to tell the user something meaningful in case of a
%failure
fmtStr = '\n\nidentifiers in %s on line %d do not match: \n%s ~= %s\n\n';
%evaluate and catch the error so we can display it
  try
    eval(str)
  catch EM
    disp(EM.message);
    %if the identifiers are not equal then something went wrong, so flag it
    %and keep going
    if(~isequal(identStr{:}, EM.identifier))
      st = dbstack; fprintf(fmtStr,            ...
                            EM.stack(1,1).name,...
                            st(1).line,        ...
                            EM.identifier,     ...
                            identStr{:});
    end
  end
end
