function dd_apply_datatype(SWCName, rootDir, modelName)
% dd_apply_datatype 字典数据类型写进模型：Enum类生成 + Inport/Outport类型对齐
%   DataType页 VehSpd->single；Enum页 En_DrvMode->Enum类；Input/Output按DataType列对齐端口
%   用法: dd_apply_datatype('TrqArb')，幂等；内部算法类型不一致时警告并保留端口类型
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
if nargin < 3 || isempty(modelName), modelName = SWCName; end
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
assert(exist(xlsx,'file'), '找不到字典 %s', xlsx);
T_dt = readcell(xlsx, 'Sheet', 'DataType');
T_en = readcell(xlsx, 'Sheet', 'Enum');
T_in = readcell(xlsx, 'Sheet', 'Input');
T_out = readcell(xlsx, 'Sheet', 'Output');
slx = fullfile(rootDir, '03_model', [modelName '.slx']);
assert(exist(slx,'file'), '找不到模型 %s', slx);
if ~bdIsLoaded(modelName), open_system(slx); end
ddDir = fullfile(rootDir, '02_dd');
addpath(ddDir);

% 1. Enum类文件（按Enum页分组生成 En_X.m，StorageType uint8）
enNames = unique(string(T_en(2:end,1)));
for k = 1:numel(enNames)
    en = char(enNames(k));
    rows = find(string(T_en(:,1)) == enNames(k));
    rows(rows == 1) = [];
    vals = []; names = {};
    for r = rows'
        names{end+1} = char(string(T_en{r,3})); %#ok<AGROW>
        vals(end+1) = str2double(string(T_en{r,2})); %#ok<AGROW>
    end
    writeEnumClass(fullfile(ddDir, [en '.m']), en, names, vals);
end

% 2. 逻辑类型 -> Simulink类型字符串
baseOf = containers.Map('KeyType','char','ValueType','char');
for r = 2:size(T_dt,1)
    baseOf(char(string(T_dt{r,1}))) = char(string(T_dt{r,2}));
end
simType = @(logical) resolveType(char(string(logical)));
    function t = resolveType(logical)
        if ismember(string(logical), enNames), t = ['Enum: ' logical];
        elseif isKey(baseOf, logical), t = baseOf(logical);
        else, t = logical; end % Calibration页直接写single/double时透传
    end

% 3. 端口类型对齐
nOK = 0;
for r = 2:size(T_in,1)
    nOK = nOK + setPortType(char(string(T_in{r,2})), simType(T_in{r,4}));
end
for r = 2:size(T_out,1)
    nOK = nOK + setPortType(char(string(T_out{r,2})), simType(T_out{r,4}));
end
% 4. 一致性试探（不硬中断：内部算法 mismatch 留给用户修）
try
    set_param(modelName, 'SimulationCommand', 'update');
    fprintf('dd_apply_datatype完成: %s，%d个端口类型已对齐，update通过\n', modelName, nOK);
catch ME
    warning('端口类型已写但update未通过（内部模块类型需手工对齐）: %s', ME.message);
    fprintf('dd_apply_datatype完成: %s，%d个端口类型已对齐，update未通过见上警告\n', modelName, nOK);
end
save_system(modelName);

    function ok = setPortType(port, dtype)
        ok = false;
        blk = [modelName '/' port];
        try
            set_param(blk, 'OutDataTypeStr', dtype);
            ok = true;
        catch ME
            warning('端口 %s 类型设置跳过: %s', port, ME.message);
        end
    end
end

function writeEnumClass(fpath, en, names, vals)
fid = fopen(fpath, 'w');
fprintf(fid, 'classdef %s < Simulink.IntEnumType\n', en);
fprintf(fid, '  enumeration\n');
for k = 1:numel(names)
    fprintf(fid, '    %s(%d)\n', names{k}, vals(k));
end
fprintf(fid, '  end\n  methods (Static)\n');
fprintf(fid, '    function retVal = getDefaultValue(), retVal = %s.%s; end\n', en, names{1});
fprintf(fid, '    function retVal = getDescription(), retVal = ''%s from dd Enum sheet''; end\n', en);
fprintf(fid, '    function retVal = getDataScope(), retVal = ''Auto''; end\n');
fprintf(fid, '    function retVal = getHeaderFile(), retVal = ''Rte_Type.h''; end\n');
fprintf(fid, '    function retVal = addClassNameToEnumNames(), retVal = false; end\n');
fprintf(fid, '  end\nend\n');
fclose(fid);
rehash; % ponytail: 确保新类立即可用
end
