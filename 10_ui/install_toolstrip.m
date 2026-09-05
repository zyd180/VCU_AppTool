function install_toolstrip(rootDir)
% install_toolstrip 一键装载VCU工具栏（幂等）：建component（如缺）+ 写JSON已在仓内 + reload
%   用法: install_toolstrip
if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath'));
    rootDir = fileparts(rootDir);
end
addpath(genpath(rootDir));
uiDir = fullfile(rootDir, '10_ui');
loaded = slLoadedToolstripComponents();
if ~any(strcmp({loaded.name}, 'vcu'))
    slCreateToolstripComponent("vcu", Location=uiDir);
end
slReloadToolstripConfig();
loaded = slLoadedToolstripComponents();
assert(any(strcmp({loaded.name}, 'vcu')), 'VCU工具栏装载失败，检查JSON语法');
fprintf('VCU工具栏已装载：打开任意Simulink模型，选VCU选项卡\n');
end
