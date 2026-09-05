function n = req_link(SWCName, rootDir)
% req_link 需求<->模型实现链接（幂等，已存在跳过）
%   IN->Inport块，OUT->Outport块，CAL->同名Constant/Gain块，RUN->模型本身
%   链接集 .slmx 默认落在模型同目录
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
rsPath = fullfile(rootDir, '09_req', [SWCName '_req.slreqx']);
assert(exist(rsPath,'file'), '先跑req_gen: %s', rsPath);
slx = fullfile(rootDir, '03_model', [SWCName '.slx']);
assert(exist(slx,'file'), '找不到模型 %s', slx);
if ~bdIsLoaded(SWCName), open_system(slx); end
T_in = readcell(xlsx, 'Sheet', 'Input');
T_out = readcell(xlsx, 'Sheet', 'Output');
T_cal = readcell(xlsx, 'Sheet', 'Calibration');
T_rn = readcell(xlsx, 'Sheet', 'Runnable');
rs = slreq.load(rsPath);
n = 0;
for r = 2:size(T_in,1)
    n = n + linkOne(sprintf('REQ_%s_IN%02d', SWCName, r-1), [SWCName '/' char(string(T_in{r,2}))]);
end
for r = 2:size(T_out,1)
    n = n + linkOne(sprintf('REQ_%s_OUT%02d', SWCName, r-1), [SWCName '/' char(string(T_out{r,2}))]);
end
for r = 2:size(T_cal,1)
    blk = [SWCName '/' char(string(T_cal{r,1}))];
    try get_param(blk, 'Handle'); dst = blk;
    catch, dst = SWCName; end % 未被引用的标定量链到SWC（归属不断，见HANDOFF）
    n = n + linkOne(sprintf('REQ_%s_CAL%02d', SWCName, r-1), dst);
end
for r = 2:size(T_rn,1)
    n = n + linkOne(sprintf('REQ_%s_RUN%02d', SWCName, r-1), SWCName);
end
slreq.saveAll(); rs.close();
fprintf('req_link完成: %s，新增%d条链接\n', SWCName, n);

    function added = linkOne(reqId, dst)
        added = false;
        reqs = rs.find('Type', 'Requirement', 'Id', reqId);
        if isempty(reqs), warning('需求 %s 不存在，跳过', reqId); return; end
        try h = get_param(dst, 'Handle'); catch, warning('目标 %s 不存在，跳过', dst); return; end
        % 幂等：同源链接去重只留一（source.id为SID去模型名前缀，见HANDOFF）
        try sid = Simulink.ID.getSID(h); catch, sid = ''; end
        expId = strrep(sid, SWCName, '');
        try ins = reqs(1).inLinks(); catch, ins = []; end
        keep = false;
        for k = 1:numel(ins)
            try s = ins(k).source; same = isequal(s.artifact, slx) && isequal(s.id, expId);
            catch, same = false; end
            if same
                if ~keep, keep = true; else, try ins(k).remove(); catch, end; end % remove非delete，见HANDOFF
            end
        end
        if keep, return; end
        slreq.createLink(h, reqs(1));
        added = true;
    end
end
