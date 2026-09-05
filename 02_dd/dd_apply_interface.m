function dd_apply_interface(SWCName, rootDir, modelName)
% dd_apply_interface 把字典Input/Output的Interface名+信号名真正写进AUTOSAR模型
%   规则：Interface页 If_* 重命名接口；DataElement重命名为信号名In_*/Out_*；端口名P_*不变
%   用法: dd_apply_interface('TrqArb')，幂等，可重复跑
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
if nargin < 3 || isempty(modelName), modelName = SWCName; end
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
assert(exist(xlsx,'file'), '找不到字典 %s', xlsx);
T_in = readcell(xlsx, 'Sheet', 'Input');
T_out = readcell(xlsx, 'Sheet', 'Output');
slx = fullfile(rootDir, '03_model', [modelName '.slx']);
assert(exist(slx,'file'), '找不到模型 %s', slx);
if ~bdIsLoaded(modelName), open_system(slx); end
try autosar.api.create(modelName, 'incremental'); catch, end % 拾取后加的端口（多速率慢速口等），无新增时无操作
arProps = autosar.api.getAUTOSARProperties(modelName);
slMap = autosar.api.getSimulinkMapping(modelName);
g = @(T,r,c) char(string(T{r,c}));
nOK = 0;
% 访问模式：单速率Implicit，多速率自动切Explicit（慢速端口Implicit构建失败，见HANDOFF）
inMode = 'ImplicitReceive'; outMode = 'ImplicitSend';
try
    st = Simulink.BlockDiagram.getSampleTimes(modelName);
    vals = vertcat(st.Value); nRates = sum(isfinite(vals(:,1)));
    if nRates > 1
        inMode = 'ExplicitReceive'; outMode = 'ExplicitSend';
        fprintf('dd_apply_interface: 检出%d个速率，端口切Explicit\n', nRates);
    end
catch
end
for i = 2:size(T_in,1)
    nOK = nOK + mapOne(g(T_in,i,1), g(T_in,i,2), g(T_in,i,3), 'Inport', inMode);
end
for i = 2:size(T_out,1)
    nOK = nOK + mapOne(g(T_out,i,1), g(T_out,i,2), g(T_out,i,3), 'Outport', outMode);
end
save_system(modelName);
fprintf('dd_apply_interface完成: %s，共%d个端口已对齐字典\n', modelName, nOK);

    function ok = mapOne(sigName, portName, ifName, kind, mode)
        ok = false;
        % 当前端口绑定的接口名
        try
            curIf = char(string(get(arProps, [modelName '/' portName], 'Interface')));
        catch
            warning('端口 %s 不存在，跳过', portName); return;
        end
        % 接口重命名（幂等：已是目标名则跳过；目标名被占则报错提示）
        if ~strcmp(curIf, ifName)
            ifs = find(arProps, [], 'SenderReceiverInterface');
            if ismember(ifName, string(ifs)) && ~strcmp(curIf, ifName)
                error('接口名冲突：%s 已存在，端口 %s 无法重命名 %s->%s', ifName, portName, curIf, ifName);
            end
            set(arProps, curIf, 'Name', ifName);
            curIf = ifName;
        end
        % 当前DataElement名
        try
            if strcmp(kind, 'Inport'), [~, curEl, ~] = slMap.getInport(portName);
            else, [~, curEl, ~] = slMap.getOutport(portName); end
            curEl = char(string(curEl));
        catch
            curEl = '';
        end
        if ~strcmp(curEl, sigName) && ~isempty(curEl)
            set(arProps, [curIf '/' curEl], 'Name', sigName);
        end
        % 重映射（保证端口->接口.元素关系正确）
        if strcmp(kind, 'Inport')
            slMap.mapInport(portName, portName, sigName, mode);
        else
            slMap.mapOutport(portName, portName, sigName, mode);
        end
        ok = true;
    end
end
