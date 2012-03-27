%TEST FILE
% the quick brown fox ...
% jumped over the lazy dog error(message(...
% 'MATLAB:odearguments:InconsistentDataType', 0, 0, 0));
% test warning(message('MATLAB:rmpath:DirNotFound', 0));
%
error(message('ERRORHANDLER:utils:CannotCopyPluginFile', srcfile, ...
              linkfoundation.util.decoratePath(destdir), mesg));

error(message('ERRORHANDLER:utils:InvalidType', 'modelInfo', ...
              'RTW.BuildInfo or linkfoundation.pjtgenerator.ProjectBuildInfo'));

error(message('ERRORHANDLER:utils:CheckEnv_NoPlatformDefinition', [ pdfFile, '.p' ]));

error(message('TICCSEXT:util:Demo_UnsupportedSpecificProcessor', upper( demopjt.demoAttribs.name ), upper( strToLookFor )));

                              error(message('MATLAB:rmpath:DirNotFound',...
                                            0));
warning(message('MATLAB:rmpath:DirNotFound', 1));
a = 1+1;

                         error(message('MATLAB:rmpath:DirNotFound',... blah
                                            2));

% eval('warning(message('MATLAB:odearguments:InconsistentDataType'...
% , 0, 0, 0)));

alpha = 2;
error(message('MATLAB:rmpath:DirNotFound', 3)); error(message('MATLAB:rmpath:DirNotFound', alpha));

beta = 'hello';
    warning(...
        message('ERRORHANDLER:utils:SSHError', 0, beta));

    warning(...
            message(...
                    'MATLAB:rmpath:DirNotFound', 4));

    warning(...
            message(...
                    'MATLAB:rmpath:DirNotFound',...
                    5));

    warning(...
            message(...
                    'MATLAB:rmpath:DirNotFound',...
                    5 ...
                ));


error(message('TICCSEXT:util:LicenseGUIUnknownAction',lower(varargin{index})));

error(message('ERRORHANDLER:utils:SSHError',linkfoundation.util.decoratePath(msg),test));

error(message('ERRORHANDLER:utils:SSHError',test,linkfoundation.util.decoratePath(msg,msg1)));

error(message('ERRORHANDLER:utils:SSHError',test,linkfoundation.util.decoratePath(msg,msg1),test));


a = {''};
a{1} = 'error(message(''TICCSEXT:util:LicenseGUIUnknownAction'',lower(varargin{index})));';
a{2} = 'error(message(''ERRORHANDLER:utils:SSHError'',linkfoundation.util.decoratePath(msg),test));';
a{3} = 'error(message(''ERRORHANDLER:utils:SSHError'',test,linkfoundation.util.decoratePath(msg,msg1)));';
a{4} = 'error(message(''ERRORHANDLER:utils:SSHError'',test,linkfoundation.util.decoratePath(msg,msg1),test));';
a{5} = 'error(message(''ERRORHANDLER:utils:SSHError'',linkfoundation.util.decoratePath(msg),test,linkfoundation.util.decoratePath(msg,msg1),test));';
a{6} = 'error(message(''MATLAB:odearguments:InconsistentDataType'', a, 0, msg));';
a{7} = 'error(message(''MATLAB:rmpath:DirNotFound'', 0)); error(message(''MATLAB:rmpath:DirNotFound'', alpha));';


