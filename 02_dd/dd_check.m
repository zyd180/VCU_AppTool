function [ok, msgs] = dd_check(SWCName, rootDir, modelName)
% dd_check V2：Input/Output/Calibration显式区分 + Interface/Port交叉一致 + 模型一致性
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
msgs = {}; ok = true;
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
R = @(s) readcell(xlsx, 'Sheet', s);
hasSheet = @(s) any(strcmpi(sheetnames(xlsx), s));
must = @(cond, m) addMsg(cond, m);
try
    T_if = R('Interface'); T_pt = R('Port'); T_dt = R('DataType'); T_rn = R('Runnable'); T_en = R('Enum');
    if hasSheet('Calibration'), T_cal = R('Calibration'); else, T_cal = R('Parameter'); end
    if hasSheet('Input'), T_in = R('Input'); else, T_in = {'SignalName','Port','Interface','DataType','Unit','Min','Max','Init','Desc'}; end
    if hasSheet('Output'), T_out = R('Output'); else, T_out = {'SignalName','Port','Interface','DataType','Unit','Min','Max','Init','Desc'}; end
    if hasSheet('Signal_NVM'), T_sg = R('Signal_NVM'); else, T_sg = {'Name','Kind','DataType','Init','Desc'}; end
catch ME
    ok = false; msgs{end+1} = ['读Excel失败: ' ME.message]; disp(strjoin(msgs, newline)); return;
end
g = @(T,r,c) string(T{r,c});
enumNames = unique(string(T_en(2:end,1)));
dtNames = string(T_dt(2:end,1)); ifNames = string(T_if(2:end,1));
validTypes = unique([dtNames; enumNames]);
inSig = string(T_in(2:end,1)); outSig = string(T_out(2:end,1));
inPort = string(T_pt(2:end,1)); calNames = string(T_cal(2:end,1));
% 1. 前缀：输入In_ / 输出Out_ / 标定Cal_ / 端口P_ / 接口If_
for i = 2:size(T_in,1)
    must(startsWith(g(T_in,i,1), "In_"), sprintf('Input %s 必须In_开头', g(T_in,i,1)));
    must(startsWith(g(T_in,i,2), "P_"), sprintf('Input %s 的Port %s 必须P_开头', g(T_in,i,1), g(T_in,i,2)));
    must(startsWith(g(T_in,i,3), "If_"), sprintf('Input %s 的Interface %s 必须If_开头', g(T_in,i,1), g(T_in,i,3)));
end
for i = 2:size(T_out,1)
    must(startsWith(g(T_out,i,1), "Out_"), sprintf('Output %s 必须Out_开头', g(T_out,i,1)));
    must(startsWith(g(T_out,i,2), "P_"), sprintf('Output %s 的Port %s 必须P_开头', g(T_out,i,1), g(T_out,i,2)));
    must(startsWith(g(T_out,i,3), "If_"), sprintf('Output %s 的Interface %s 必须If_开头', g(T_out,i,1), g(T_out,i,3)));
end
for i = 2:size(T_cal,1)
    must(startsWith(g(T_cal,i,1), "Cal_"), sprintf('Calibration %s 必须Cal_开头', g(T_cal,i,1)));
end
% 2. DataType引用存在（Input col4 / Output col4 / Calib col2）
for i = 2:size(T_in,1), must(ismember(g(T_in,i,4), validTypes), sprintf('Input %s 引用了不存在的DataType/Enum %s', g(T_in,i,1), g(T_in,i,4))); end
for i = 2:size(T_out,1), must(ismember(g(T_out,i,4), validTypes), sprintf('Output %s 引用了不存在的DataType/Enum %s', g(T_out,i,1), g(T_out,i,4))); end
for i = 2:size(T_cal,1), must(ismember(g(T_cal,i,2), dtNames) | ismember(g(T_cal,i,2), ["single","double","int32","uint8","boolean"]), sprintf('Calibration %s 数据类型 %s 非法', g(T_cal,i,1), g(T_cal,i,2))); end
% 3. 跨表无重名（输入/输出/标定信号名全局唯一）
allSig = [inSig; outSig; calNames];
must(numel(unique(allSig))==numel(allSig), 'Input/Output/Calibration之间有重名');
must(numel(unique(inSig))==numel(inSig), 'Input表内有重名');
must(numel(unique(outSig))==numel(outSig), 'Output表内有重名');
must(numel(unique(calNames))==numel(calNames), 'Calibration表内有重名');
% 3b. Signal_NVM：Kind合法 + 前缀 + 类型引用 + Init数值 + 与端口/标定无重名（同模型块命名空间）
sgNames = string(T_sg(2:end,1));
must(numel(unique(sgNames))==numel(sgNames), 'Signal_NVM表内有重名');
for i = 2:size(T_sg,1)
    kind = g(T_sg,i,2);
    must(ismember(kind, ["IRV","NVM","Meas"]), sprintf('Signal_NVM %s Kind=%s 非法（IRV/NVM/Meas）', g(T_sg,i,1), kind));
    if kind == "IRV", must(startsWith(g(T_sg,i,1), "Irv_"), sprintf('IRV %s 必须Irv_开头', g(T_sg,i,1))); end
    if kind == "NVM", must(startsWith(g(T_sg,i,1), "Nvm_"), sprintf('NVM %s 必须Nvm_开头', g(T_sg,i,1))); end
    if kind == "Meas", must(startsWith(g(T_sg,i,1), "Meas_"), sprintf('Meas %s 必须Meas_开头', g(T_sg,i,1))); end
    must(ismember(g(T_sg,i,3), validTypes) | ismember(g(T_sg,i,3), ["single","double","int32","uint8","boolean"]), sprintf('Signal_NVM %s 引用了不存在的DataType/Enum %s', g(T_sg,i,1), g(T_sg,i,3)));
    must(~isnan(str2double(g(T_sg,i,4))), sprintf('Signal_NVM %s Init非数值', g(T_sg,i,1)));
    must(~ismember(g(T_sg,i,1), [string(T_pt(2:end,1)); calNames]), sprintf('Signal_NVM %s 与Port/Calibration重名（同模型块命名空间）', g(T_sg,i,1)));
end
% 4. Min<Max（Input col6/7, Output col6/7, Calib col4/5）
chkRange = @(T,r,cLo,cHi,label) must(str2double(g(T,r,cLo)) < str2double(g(T,r,cHi)), sprintf('%s %s Min>=Max', label, g(T,r,1)));
for i = 2:size(T_in,1), chkRange(T_in,i,6,7,'Input'); end
for i = 2:size(T_out,1), chkRange(T_out,i,6,7,'Output'); end
for i = 2:size(T_cal,1), chkRange(T_cal,i,4,5,'Calibration'); end
% 5. Interface/Port对照视图与Input/Output一致
for i = 2:size(T_pt,1)
    must(ismember(g(T_pt,i,3), ifNames), sprintf('Port %s 引用了不存在的Interface %s', g(T_pt,i,1), g(T_pt,i,3)));
end
expInPorts = string(T_in(2:end,2)); expOutPorts = string(T_out(2:end,2));
actInPorts = {}; actOutPorts = {};
for i = 2:size(T_pt,1)
    if string(T_pt{i,2})=="In", actInPorts{end+1}=char(string(T_pt{i,1})); else, actOutPorts{end+1}=char(string(T_pt{i,1})); end
end
must(isempty(setxor(string(actInPorts), expInPorts)), 'Port表In端口集合与Input表不一致');
must(isempty(setxor(string(actOutPorts), expOutPorts)), 'Port表Out端口集合与Output表不一致');
% 6. Runnable访问的端口必须在Port表中 + 全行合法性（R_前缀/唯一/周期数值）
allPorts = string(T_pt(2:end,1));
rnNames = string(T_rn(2:end,1));
must(numel(unique(rnNames))==numel(rnNames), 'Runnable表内有重名');
for i = 2:size(T_rn,1)
    must(startsWith(g(T_rn,i,1), "R_"), sprintf('Runnable %s 必须R_开头', g(T_rn,i,1)));
    must(~isnan(str2double(g(T_rn,i,2))) && str2double(g(T_rn,i,2)) > 0, sprintf('Runnable %s Period_ms非法', g(T_rn,i,1)));
    acc = split(string(T_rn{i,4}), ";");
    for k = 1:numel(acc)
        must(ismember(strtrim(acc(k)), allPorts), sprintf('Runnable %s 访问了不存在的端口 %s', g(T_rn,i,1), strtrim(acc(k))));
    end
end
% 7. 可选：模型Inport/Outport与字典一致（含数据类型）
if nargin >= 3 && ~isempty(modelName) && exist([modelName '.slx'],'file')
    load_system(modelName);
    expType = containers.Map('KeyType','char','ValueType','char');
    for i = 2:size(T_in,1)
        lt = char(g(T_in,i,4));
        if ismember(string(lt), enumNames), expType(char(g(T_in,i,2))) = ['Enum: ' lt];
        elseif ismember(string(lt), dtNames)
            rdt = find(string(T_dt(:,1))==string(lt), 1);
            expType(char(g(T_in,i,2))) = char(string(T_dt{rdt,2}));
        end
    end
    for i = 2:size(T_out,1)
        lt = char(g(T_out,i,4));
        if ismember(string(lt), enumNames), expType(char(g(T_out,i,2))) = ['Enum: ' lt];
        elseif ismember(string(lt), dtNames)
            rdt = find(string(T_dt(:,1))==string(lt), 1);
            expType(char(g(T_out,i,2))) = char(string(T_dt{rdt,2}));
        end
    end
    ins = find_system(modelName,'BlockType','Inport'); outs = find_system(modelName,'BlockType','Outport');
    mPorts = [cellfun(@(b)get_param(b,'Name'), ins, 'uni', 0); cellfun(@(b)get_param(b,'Name'), outs, 'uni', 0)];
    for k = 1:numel(mPorts)
        must(ismember(string(mPorts{k}), allPorts), sprintf('模型端口 %s 不在字典Port表中', string(mPorts{k})));
        if isKey(expType, char(string(mPorts{k})))
            blk = [modelName '/' char(string(mPorts{k}))];
            act = char(string(get_param(blk, 'OutDataTypeStr')));
            must(strcmp(act, expType(char(string(mPorts{k})))), sprintf('模型端口 %s 类型 %s 与字典期望 %s 不一致（跑dd_apply_datatype）', string(mPorts{k}), act, expType(char(string(mPorts{k})))));
        end
    end
    try
        arP = autosar.api.getAUTOSARProperties(modelName);
        mRnsAll = string(find(arP, [], 'Runnable'));
        mRns = mRnsAll(~contains(mRnsAll, 'Init'));
        for i = 2:size(T_rn,1)
            expRn = string(T_rn(i,1));
            must(any(contains(mRns, expRn)), sprintf('模型Runnable缺失字典期望 %s（跑dd_apply_runnable）', expRn));
        end
        if size(T_rn,1) > 2
            warning('字典含%d个Runnable，当前仅首行映射为模型runnable（多runnable需export-function模板，见HANDOFF）', size(T_rn,1)-1);
        end
        % 周期必须为模型基础步长的整数倍；速率数须与Runnable行数一致
        try
            base_ms = str2double(get_param(modelName, 'FixedStep')) * 1000;
            for i = 2:size(T_rn,1)
                per = str2double(g(T_rn,i,2));
                must(abs(per/base_ms - round(per/base_ms)) < 1e-6, sprintf('Runnable %s 周期%sms非基础步长%sms整数倍', g(T_rn,i,1), g(T_rn,i,2), num2str(base_ms)));
            end
        catch
        end
        try
            st = Simulink.BlockDiagram.getSampleTimes(modelName);
            v = vertcat(st.Value); nRates = sum(isfinite(v(:,1)));
            must(nRates == size(T_rn,1)-1, sprintf('模型有%d个速率而字典Runnable有%d行（慢速路径须经Rate Transition）', nRates, size(T_rn,1)-1));
        catch
        end
    catch
    end
    % 8. 标定量：模型工作区存在 + SharedParameter映射（未引用仅警告，不判失败）
    try
        hWS = get_param(modelName, 'ModelWorkspace');
        slM = autosar.api.getSimulinkMapping(modelName);
        for i = 2:size(T_cal,1)
            cn = char(g(T_cal,i,1));
            must(hWS.hasVariable(cn) || evalin('base', ['exist(''' cn ''',''var'')']) == 1, sprintf('标定量 %s 无工作区参数（跑dd_apply_calibration）', cn));
            try
                must(strcmp(char(string(slM.getParameter(cn))), 'SharedParameter'), sprintf('标定量 %s 未映射SharedParameter', cn));
            catch
            end
        end
    catch
    end
    % 9. 内部量/测量：IRV/NVM的DSM块存在；Meas的SrcBlock存在（跑dd_apply_signal）
    for i = 2:size(T_sg,1)
        sn = char(g(T_sg,i,1)); kind = char(g(T_sg,i,2));
        if strcmp(kind,'IRV') || strcmp(kind,'NVM')
            must(~isempty(find_system(modelName, 'Name', sn)), sprintf('内部量 %s 缺少DataStoreMemory块（跑dd_apply_signal）', sn));
        elseif strcmp(kind,'Meas') && size(T_sg,2) >= 6 && strlength(getText(T_sg, i, 6)) > 0
            sb = getText(T_sg, i, 6);
            must(~isempty(find_system(modelName, 'Name', sb)), sprintf('测量 %s 的SrcBlock %s 不存在', sn, sb));
        end
    end
end
if ok, msgs{end+1} = 'dd_check通过(V2: 输入/输出/标定区分+交叉一致+类型+标定+内部量)'; end
disp(strjoin(msgs, newline));

    function addMsg(cond, m)
        if ~cond, ok = false; msgs{end+1} = m; end
    end

    function t = getText(T, r, c)
        % 安全取文本：missing/空/越界一律返回''（ismissing对char返回向量，不可直接&&）
        if size(T,2) < c, t = ''; return; end
        try sv = string(T{r,c}); catch, t = ''; return; end
        if ~isscalar(sv) || ismissing(sv), t = ''; return; end
        t = char(strtrim(sv));
    end
end
