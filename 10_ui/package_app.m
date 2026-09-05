function package_app(rootDir)
% package_app 打包向导：校验UI文件齐套后打开“打包为App”对话框（R2023a无纯脚本打包API）
%   手动两步：Main file选 10_ui/vcu_app.m → Share → .mlappinstall
%   团队主分发走U3工具栏装载，本函数为发版辅助
if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath'));
    rootDir = fileparts(rootDir);
end
need = {'10_ui/vcu_app.m','10_ui/vcu_log.m','10_ui/vcu_swc_list.m','10_ui/vcu_cur.m', ...
    '10_ui/callbacks/cb_new_swc.m','10_ui/callbacks/cb_dd.m','10_ui/callbacks/cb_model.m', ...
    '10_ui/callbacks/cb_gen.m','10_ui/callbacks/cb_arxml.m','10_ui/callbacks/cb_cal.m', ...
    '10_ui/callbacks/cb_req.m','10_ui/callbacks/cb_test.m','VERSION'};
missing = {};
for k = 1:numel(need)
    if ~exist(fullfile(rootDir, need{k}), 'file'), missing{end+1} = need{k}; end
end
assert(isempty(missing), 'UI文件缺失: %s', strjoin(missing, ', '));
fprintf('UI文件齐套（%d个），即将打开打包对话框：Main file选 10_ui/vcu_app.m\n', numel(need));
matlab.apputil.create();
end
