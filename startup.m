%%==============================================================================
addpath(genpath(pwd));

if isfolder('.git')
  rmpath('.git');
end

set(0,'DefaultAxesFontSize',12);
set(0,'DefaultTextFontSize',12);
set(0,'DefaultLineLinewidth',1.5);
format compact;
set(0,'defaultfigurecolor',[1 1 1]);
