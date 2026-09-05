function repPath = req_report(SWCName, rootDir)
% req_report 需求报告（含追溯）输出到 09_req/output/
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
rsPath = fullfile(rootDir, '09_req', [SWCName '_req.slreqx']);
assert(exist(rsPath,'file'), '先跑req_gen: %s', rsPath);
outDir = fullfile(rootDir, '09_req', 'output', SWCName);
if ~exist(outDir,'dir'), mkdir(outDir); end
rs = slreq.load(rsPath);
opts = slreq.getReportOptions();
dst = fullfile(outDir, [SWCName '_req_report.docx']);
opts.reportPath = dst; opts.openReport = false; % 直接落位，不弹Word
repPath = slreq.generateReport(rs, opts);
rs.close();
fprintf('需求报告已生成: %s\n', repPath);
end
