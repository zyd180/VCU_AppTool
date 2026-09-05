function rsPath = req_gen(SWCName, rootDir, overwrite)
% req_gen 字典驱动生成需求骨架 <SWC>_req.slreqx（仅缺失时生成，防覆写手填内容）
%   每Input/Output/Calibration/Runnable行一条需求，ID稳定：REQ_<SWC>_<IN|OUT|CAL|RUN>NN
%   用法: req_gen('TrqArb'); req_gen('TrqArb',rootDir,true) 强制重建
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath')); rootDir = fileparts(rootDir);
end
if nargin < 3, overwrite = false; end
reqDir = fullfile(rootDir, '09_req');
if ~exist(reqDir,'dir'), mkdir(reqDir); end
rsPath = fullfile(reqDir, [SWCName '_req.slreqx']);
if exist(rsPath,'file') && ~overwrite
    fprintf('需求集已存在，跳过生成（强制重建传true）：%s\n', rsPath);
    return;
end
if exist(rsPath,'file'), delete(rsPath); end
xlsx = fullfile(rootDir, '02_dd', [SWCName '_dd.xlsx']);
assert(exist(xlsx,'file'), '找不到字典 %s', xlsx);
T_in = readcell(xlsx, 'Sheet', 'Input');
T_out = readcell(xlsx, 'Sheet', 'Output');
T_cal = readcell(xlsx, 'Sheet', 'Calibration');
T_rn = readcell(xlsx, 'Sheet', 'Runnable');
rs = slreq.new(rsPath);
n = 0;
for r = 2:size(T_in,1)
    n = n + 1;
    rs.add('id', sprintf('REQ_%s_IN%02d', SWCName, r-1), 'summary', ...
        sprintf('[%s] 输入 %s（%s，%s，范围%s~%s）', char(string(T_in{r,2})), ...
        char(string(T_in{r,1})), char(string(T_in{r,4})), char(string(T_in{r,5})), ...
        char(string(T_in{r,6})), char(string(T_in{r,7}))));
end
for r = 2:size(T_out,1)
    rs.add('id', sprintf('REQ_%s_OUT%02d', SWCName, r-1), 'summary', ...
        sprintf('[%s] 输出 %s（%s，%s，范围%s~%s）', char(string(T_out{r,2})), ...
        char(string(T_out{r,1})), char(string(T_out{r,4})), char(string(T_out{r,5})), ...
        char(string(T_out{r,6})), char(string(T_out{r,7}))));
end
for r = 2:size(T_cal,1)
    rs.add('id', sprintf('REQ_%s_CAL%02d', SWCName, r-1), 'summary', ...
        sprintf('标定 %s（%s，%s，范围%s~%s，初值%s）', char(string(T_cal{r,1})), ...
        char(string(T_cal{r,2})), char(string(T_cal{r,3})), char(string(T_cal{r,4})), ...
        char(string(T_cal{r,5})), char(string(T_cal{r,6}))));
end
for r = 2:size(T_rn,1)
    rs.add('id', sprintf('REQ_%s_RUN%02d', SWCName, r-1), 'summary', ...
        sprintf('周期任务 %s（%sms，访问%s）', char(string(T_rn{r,1})), ...
        char(string(T_rn{r,2})), char(string(T_rn{r,4}))));
end
rs.save(); rs.close();
fprintf('需求骨架已生成: %s（%d条）\n', rsPath, n + (size(T_out,1)-1) + (size(T_cal,1)-1) + (size(T_rn,1)-1));
end
