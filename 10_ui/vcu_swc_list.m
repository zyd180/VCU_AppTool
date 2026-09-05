function list = vcu_swc_list(rootDir)
% vcu_swc_list 扫描03_model}{*}.slx列SWC下拉（UI唯一模型发现入口）
%   用法: vcu_swc_list() / vcu_swc_list(rootDir)
if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath'));
    rootDir = fileparts(rootDir);
end
d = dir(fullfile(rootDir, '03_model', '*.slx'));
list = cellfun(@(n) n(1:end-4), {d.name}, 'uni', 0);
end
