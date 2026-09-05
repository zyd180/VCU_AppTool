function dd_apply_signal(SWCName, rootDir, modelName)
% dd_apply_signal 字典Signal_NVM写进模型（幂等）
%   IRV -> DataStoreMemory块 + mapDataStore ArTypedPerInstanceMemory
%   NVM -> DataStoreMemory块 + mapDataStore ArTypedPerInstanceMemory + NeedsNVRAMAccess
%   Meas -> SrcBlock输出打TestPoint + addSignal + mapSignal StaticMemory/ShortName
%   SrcBlock为空或目标不存在仅警告（参照Cal_TrqRate先例，不中断）
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
if nargin < 3 || isempty(modelName), modelName = SWCName; end
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
assert(exist(xlsx,'file'), '找不到字典 %s', xlsx);
T = readcell(xlsx, 'Sheet', 'Signal_NVM');
T_dt = readcell(xlsx, 'Sheet', 'DataType');
slx = fullfile(rootDir, '03_model', [modelName '.slx']);
assert(exist(slx,'file'), '找不到模型 %s', slx);
if ~bdIsLoaded(modelName), open_system(slx); end
baseOf = containers.Map('KeyType','char','ValueType','char');
for r = 2:size(T_dt,1), baseOf(char(string(T_dt{r,1}))) = char(string(T_dt{r,2})); end
nDSM = 0; nMeas = 0; y = 300;
for r = 2:size(T,1)
    nm = char(string(T{r,1})); kind = char(string(T{r,2}));
    dt = resolveType(char(string(T{r,3})));
    init = cellToStr(T{r,4});
    src = getText(T, r, 6);
    switch kind
        case {'IRV','NVM'}
            blk = [modelName '/' nm];
            if isempty(find_system(modelName, 'Name', nm))
                add_block('simulink/Signal Routing/Data Store Memory', blk, ...
                    'DataStoreName', nm, 'OutDataTypeStr', dt, ...
                    'InitialValue', init, 'Position', [30 y 200 y+30]);
                y = y + 50;
            else
                set_param(blk, 'OutDataTypeStr', dt, 'InitialValue', init);
            end
            nDSM = nDSM + 1;
        case 'Meas'
            if isempty(src)
                warning('测量 %s 未填SrcBlock，仅登记（代码/ARXML将无此测量）', nm);
            else
                nMeas = nMeas + mapMeas(nm, src);
            end
        otherwise
            warning('Signal_NVM %s Kind=%s 非法（IRV/NVM/Meas），跳过', nm, kind);
    end
end
set_param(modelName, 'SimulationCommand', 'update');
slMap = autosar.api.getSimulinkMapping(modelName);
for r = 2:size(T,1)
    nm = char(string(T{r,1})); kind = char(string(T{r,2}));
    if strcmp(kind,'IRV') || strcmp(kind,'NVM')
        try
            h = get_param([modelName '/' nm], 'Handle');
            if strcmp(kind,'IRV')
                slMap.mapDataStore(h, 'ArTypedPerInstanceMemory');
            else
                slMap.mapDataStore(h, 'ArTypedPerInstanceMemory', 'NeedsNVRAMAccess', true);
            end
        catch ME
            warning('内部量 %s 映射跳过: %s', nm, ME.message(1:min(160,numel(ME.message))));
        end
    end
end
save_system(modelName);
fprintf('dd_apply_signal完成: %s，%d个DSM(IRV/NVM)+%d个测量已处理\n', modelName, nDSM, nMeas);
checkWired();

    function checkWired()
        % DSM无人读写仅警告（参照Cal_TrqRate先例）：ARXML保留声明，代码裁剪
        try
            readers = find_system(modelName, 'BlockType', 'DataStoreRead');
            writers = find_system(modelName, 'BlockType', 'DataStoreWrite');
            used = {};
            for b = [readers(:); writers(:)]'
                try used{end+1} = get_param(b, 'DataStoreName'); catch, end
            end
            for r = 2:size(T,1)
                k = char(string(T{r,2}));
                if (strcmp(k,'IRV') || strcmp(k,'NVM')) && ~ismember(string(T{r,1}), string(used))
                    warning('内部量 %s 无DataStoreRead/Write引用，代码将裁剪（ARXML保留声明）', string(T{r,1}));
                end
            end
        catch
        end
    end

    function t = resolveType(logical)
        try
            T_en = readcell(xlsx, 'Sheet', 'Enum');
            if ismember(string(logical), string(T_en(2:end,1))), t = ['Enum: ' logical]; return; end
        catch, end
        if isKey(baseOf, logical), t = baseOf(logical); else, t = logical; end
    end

    function s = cellToStr(v)
        if isnumeric(v), s = num2str(v);
        else, s = getText(v); if isempty(s), s = '0'; end
        end
    end

    function t = getText(varargin)
        % getText(T,r,c) 或 getText(v)：安全取文本，missing/空一律返回''
        if nargin == 3
            T = varargin{1}; r = varargin{2}; c = varargin{3};
            if size(T,2) < c, t = ''; return; end
            v = T{r,c};
        else
            v = varargin{1};
        end
        try sv = string(v); catch, t = ''; return; end
        if ~isscalar(sv) || ismissing(sv), t = ''; return; end
        t = char(strtrim(sv));
    end

    function hit = mapMeas(nm, src)
        hit = false;
        try
            ph = get_param([modelName '/' src], 'PortHandles');
            if isempty(ph.Outport), warning('测量 %s 的SrcBlock %s 无输出端口', nm, src); return; end
            outPh = ph.Outport(1);
            set_param(outPh, 'TestPoint', 'on');
            set_param(modelName, 'SimulationCommand', 'update');
            sMap = autosar.api.getSimulinkMapping(modelName);
            try sMap.addSignal(outPh); catch, end % 已存在则跳过
            sMap.mapSignal(outPh, 'ArTypedPerInstanceMemory', 'ShortName', nm);
            % ponytail: 不用StaticMemory——多实例SWC不支持，会构建失败
            hit = true;
        catch ME
            warning('测量 %s 映射跳过: %s', nm, ME.message(1:min(160,numel(ME.message))));
        end
    end
end
