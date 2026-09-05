function model = create_swc_template(SWCName, rootDir)
% create_swc_template 按字典建端口的模板模型（最小可生成代码，用户在此基础上填算法）
%   端口/桩全部来自字典Input/Output/Calibration：Inport按Input.Port建，
%   Outport按Output.Port建并轮询挂到Cal常量桩上（用户后续替换为真实算法）
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
assert(exist(xlsx, 'file'), '找不到字典 %s，先跑create_dd_template', xlsx);
T_in = readcell(xlsx, 'Sheet', 'Input');
T_out = readcell(xlsx, 'Sheet', 'Output');
try T_cal = readcell(xlsx, 'Sheet', 'Calibration'); catch, T_cal = {'CalibName'}; end
modelDir = fullfile(rootDir, '03_model');
if ~exist(modelDir,'dir'), mkdir(modelDir); end
model = SWCName;
slx = fullfile(modelDir, [model '.slx']);
if bdIsLoaded(model), close_system(model, 0); end
if exist(slx,'file'), delete(slx); end
new_system(model); open_system(model);
g = @(T,r,c) char(string(T{r,c}));
y = 60;
for r = 2:size(T_in,1)
    add_block('simulink/Sources/In1', [model '/' g(T_in,r,2)], 'Position', [30 y 60 y+14]);
    y = y + 60;
end
y = 60; nCal = size(T_cal,1) - 1;
calBlk = {};
for r = 2:size(T_cal,1)
    nm = g(T_cal,r,1); dt = g(T_cal,r,2);
    add_block('simulink/Sources/Constant', [model '/' nm], 'Value', nm, ...
        'OutDataTypeStr', dt, 'Position', [150 y 200 y+30]);
    calBlk{end+1} = nm; %#ok<AGROW>
    y = y + 60;
end
y = 60;
for r = 2:size(T_out,1)
    op = g(T_out,r,2);
    add_block('simulink/Sinks/Out1', [model '/' op], 'Position', [400 y 430 y+14]);
    if ~isempty(calBlk)
        src = calBlk{mod(r-2, numel(calBlk)) + 1};
        add_line(model, [src '/1'], [op '/1']);
    end
    y = y + 60;
end
set_param(model, 'SystemTargetFile', 'autosar.tlc');
save_system(model, slx);
% AUTOSAR映射：默认映射保底，字典Interface名由dd_apply_interface写进模型
try
    autosar.api.create(model);
catch ME
    warning('AUTOSAR映射部分跳过: %s', ME.message);
end
try
    arProps = autosar.api.getAUTOSARProperties(model);
    addpath(fileparts(mfilename('fullpath')));
    ert_autosar_config(model);
    addpath(fullfile(rootDir, '02_dd'));
    dd_apply_interface(SWCName, rootDir, model);
catch ME
    warning('配置部分跳过: %s', ME.message); save_system(model);
end
fprintf('模板模型已生成: %s（端口来自字典）\n', slx);
end
