function run_all(SWCName, rootDir)
% run_all CI一键全链：字典->检查->代码->arxml->标定钩子
if nargin < 1 || isempty(SWCName), SWCName = 'TrqArb'; end
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
addpath(genpath(rootDir));
try toolVer = strtrim(fileread(fullfile(rootDir, 'VERSION'))); catch, toolVer = 'unknown'; end
fprintf('VCU_AppTool v%s\n', toolVer);
dd_excel2m(SWCName, rootDir);
dd_check(SWCName, rootDir);
codegen_onekey(SWCName, rootDir);
arxml_gen(SWCName, rootDir);
arxml_check(SWCName, rootDir);
export_a2l_hook(SWCName, rootDir);
req_gen(SWCName, rootDir); % 缺失才建，不覆写手填内容
req_link(SWCName, rootDir);
[reqOK, reqMsgs] = req_check(SWCName, rootDir);
assert(reqOK, 'req_check失败:\n%s', strjoin(reqMsgs, newline)); % slbuild兜不住追溯过期，必须硬失败
fprintf('run_all全链通过: %s\n', SWCName);
end
