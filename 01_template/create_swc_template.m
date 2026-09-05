function model = create_swc_template(SWCName, rootDir)
% create_swc_template 以DemoSwc为架构模板克隆新SWC模型（用户改DemoSwc即改模板）
%   架构：顶层Inport -> 同名核心子系统（比较/增益/限幅/切换骨架） -> Outport
%   端口按字典Input/Output重命名（按顺序），标定常量按Calibration补齐
%   用法: create_swc_template('BattIf')；DemoSwc本身是模板源，不可重建
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
assert(~strcmp(SWCName, 'DemoSwc'), 'DemoSwc是架构模板源，不可重建（如需重置请从git恢复）');
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
assert(exist(xlsx, 'file'), '找不到字典 %s，先跑create_dd_template', xlsx);
tpl = fullfile(rootDir, '03_model', 'DemoSwc.slx');
assert(exist(tpl, 'file'), '架构模板 %s 缺失', tpl);
T_in = readcell(xlsx, 'Sheet', 'Input');
T_out = readcell(xlsx, 'Sheet', 'Output');
try T_cal = readcell(xlsx, 'Sheet', 'Calibration'); catch, T_cal = {'CalibName','DataType'}; end
modelDir = fullfile(rootDir, '03_model');
model = SWCName;
slx = fullfile(modelDir, [model '.slx']);
if bdIsLoaded(model), close_system(model, 0); end
if exist(slx,'file'), delete(slx); end
if ~bdIsLoaded('DemoSwc'), load_system(tpl); end
new_system(model); open_system(model);
g = @(T,r,c) char(string(T{r,c}));
% 顶层端口（按字典）
y = 60;
for r = 2:size(T_in,1)
    add_block('simulink/Sources/In1', [model '/' g(T_in,r,2)], 'Position', [30 y 60 y+14]);
    y = y + 60;
end
y = 60;
for r = 2:size(T_out,1)
    add_block('simulink/Sinks/Out1', [model '/' g(T_out,r,2)], 'Position', [560 y 590 y+14]);
    y = y + 60;
end
% 核心子系统：整体克隆（含算法骨架与内部连线）
add_block('DemoSwc/DemoSwc', [model '/' model], 'Position', [200 40 400 260]);
sub = [model '/' model];
% 克隆带入的库链接断开本地化（none=彻底断链，无告警；避免库升级串改模板）
try
    links = find_system(sub, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'LinkStatus', 'resolved');
    for k = 1:numel(links)
        try set_param(links{k}, 'LinkStatus', 'none'); catch, end
    end
catch, end
% 子系统端口按顺序重命名（算法拓扑不动）
subIn = find_system(sub, 'SearchDepth', 1, 'BlockType', 'Inport');
subOut = find_system(sub, 'SearchDepth', 1, 'BlockType', 'Outport');
for k = 1:numel(subIn)
    if k <= size(T_in,1)-1
        set_param(subIn{k}, 'Name', g(T_in,k+1,2));
    else
        warning('模板子系统多余输入口 %s 已删除', get_param(subIn{k}, 'Name'));
        delete_block(subIn{k});
    end
end
for k = 1:numel(subOut)
    if k <= size(T_out,1)-1
        set_param(subOut{k}, 'Name', g(T_out,k+1,2));
    else
        warning('模板子系统多余输出口 %s 已删除', get_param(subOut{k}, 'Name'));
        delete_block(subOut{k});
    end
end
% 标定常量：同名保留，其余按Calibration表补齐
haveCals = find_system(sub, 'SearchDepth', 1, 'BlockType', 'Constant');
haveNames = cellfun(@(b) get_param(b,'Name'), haveCals, 'uni', 0);
yy = 300;
for r = 2:size(T_cal,1)
    nm = g(T_cal,r,1); dt = g(T_cal,r,2);
    if ~ismember(nm, haveNames)
        initv = '0'; v = T_cal{r,6};
        if isnumeric(v), initv = num2str(v);
        else
            try sv = string(v); if isscalar(sv) && ~ismissing(sv) && strlength(strtrim(sv))>0, initv = char(strtrim(sv)); end; catch, end
        end
        add_block('simulink/Sources/Constant', [sub '/' nm], 'Value', initv, ...
            'OutDataTypeStr', dt, 'Position', [30 yy 90 yy+30]);
        yy = yy + 50;
    end
end
% 骨架算术块类型跟随端口（默认single，与默认字典一致；换基类型字典需手工对齐内部）
for bt = {'Gain','MinMax','Switch','Compare'}
    bs = find_system(sub, 'SearchDepth', 1, 'BlockType', bt{1});
    for k = 1:numel(bs)
        try set_param(bs{k}, 'OutDataTypeStr', 'single'); catch, end
    end
end
% 骨架Compare常量跟随枚举输入（否则double常量无法转枚举，构建失败）
try
    T_en = readcell(xlsx, 'Sheet', 'Enum');
    enNames = unique(string(T_en(2:end,1)));
    for r = 2:size(T_in,1)
        lt = char(string(T_in{r,4}));
        if ismember(string(lt), enNames)
            rows = find(string(T_en(:,1)) == string(lt)); rows(rows==1) = [];
            lit = sprintf('%s.%s', lt, char(string(T_en{rows(1),3})));
            cmps = find_system(sub, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'BlockType', 'Constant');
            for k = 1:numel(cmps)
                if contains(get_param(cmps{k}, 'Parent'), 'Compare')
                    try set_param(cmps{k}, 'Value', lit, 'OutDataTypeStr', ['Enum: ' lt]); catch, end
                end
            end
        end
    end
catch, end
% 顶层连线：Inport_i -> 子系统输入i；子系统输出j -> Outport_j
nIn = size(T_in,1)-1; nOut = size(T_out,1)-1;
for k = 1:nIn
    add_line(model, [g(T_in,k+1,2) '/1'], [model '/' num2str(k)]);
end
for k = 1:nOut
    add_line(model, [model '/' num2str(k)], [g(T_out,k+1,2) '/1']);
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
fprintf('模板模型已生成（克隆DemoSwc架构）: %s\n', slx);
end
