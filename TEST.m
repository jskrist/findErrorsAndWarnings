%TEST FILE
% the quick brown fox ...
% jumped over the lazy dog error(message(...
% 'MATLAB:odearguments:InconsistentDataType', 0, 0, 0));
% test warning(message('MATLAB:rmpath:DirNotFound', 0));
% 
                              error(message('MATLAB:rmpath:DirNotFound',...
                                            0));
warning(message('MATLAB:rmpath:DirNotFound', 0));
a = 1+1;

                         error(message('MATLAB:rmpath:DirNotFound',... test
                                            0));

% eval('warning(message('MATLAB:odearguments:InconsistentDataType'...
% , 0, 0, 0)));

error(message('MATLAB:rmpath:DirNotFound', 0)); error(message('MATLAB:rmpath:DirNotFound', 0));


a = 'error(message(''MATLAB:odearguments:InconsistentDataType'', 0, 0, 0)); error(message(''MATLAB:rmpath:DirNotFound'', 0)); %this is a comment warning(message(''MATLAB:odearguments:InconsistentDataType'', 0, 0, 0));';


    warning(...
        message('MATLAB:rmpath:DirNotFound', 0));

    warning(...
            message(...
                    'MATLAB:rmpath:DirNotFound', 0));

    warning(...
            message(...
                    'MATLAB:rmpath:DirNotFound',...
                    0));
