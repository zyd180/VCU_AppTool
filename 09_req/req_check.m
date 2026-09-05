function [ok, msgs] = req_check(SWCName, rootDir)
% req_check 需求追溯检查：数量与字典一致 + 每条需求至少1条实现链接
%   字典增行后数量对不上即失败，提示删.slreqx重gen（防静默过期）
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
msgs = {}; ok = true;
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
rsPath = fullfile(rootDir, '09_req', [SWCName '_req.slreqx']);
if ~exist(rsPath,'file'), ok = false; msgs{end+1} = sprintf('缺少需求集，先跑req_gen: %s', rsPath); disp(strjoin(msgs, newline)); return; end
expN = 0;
for s = {'Input','Output','Calibration','Runnable'}
    T = readcell(xlsx, 'Sheet', s{1}); expN = expN + size(T,1) - 1;
end
rs = slreq.load(rsPath);
reqs = rs.find('Type', 'Requirement');
if numel(reqs) ~= expN
    ok = false; msgs{end+1} = sprintf('需求数%d与字典行数%d不一致（删.slreqx后重跑req_gen）', numel(reqs), expN);
end
for k = 1:numel(reqs)
    try ins = reqs(k).inLinks(); catch, ins = []; end
    if isempty(ins), ok = false; msgs{end+1} = sprintf('需求 %s 无实现链接（跑req_link）', reqs(k).Id); end
end
rs.close();
if ok, msgs{end+1} = sprintf('req_check通过: %d条需求均有实现链接', numel(reqs)); end
disp(strjoin(msgs, newline));
end
