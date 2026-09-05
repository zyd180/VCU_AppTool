function new_swc(SWCName, rootDir)
% new_swc 一键新建SWC全套文件：xlsx+m+模板模型
%   new_swc('BattIf')
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
addpath(fullfile(rootDir,'01_template'), fullfile(rootDir,'02_dd'), fullfile(rootDir,'09_req'));
create_dd_template(SWCName, rootDir);
dd_excel2m(SWCName, rootDir);
create_swc_template(SWCName, rootDir);
req_gen(SWCName, rootDir);
fprintf('new_swc完成: %s\n', SWCName);
end
