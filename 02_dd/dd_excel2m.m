function mPath = dd_excel2m(SWCName, rootDir)
% dd_excel2m Excel字典 -> SWCName_dd.m（V2：Input/Output/Calibration显式分表）
%   主入口：Input / Output / Calibration；兼容老表：Parameter(无Calibration页时回退)
if nargin < 2 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath'));
    rootDir = fileparts(rootDir);
end
ddDir = fullfile(rootDir, '02_dd');
xlsx = fullfile(ddDir, [SWCName '_dd.xlsx']);
assert(exist(xlsx,'file'), '找不到字典Excel: %s，先跑create_dd_template', xlsx);

rd = @(s) readcell(xlsx, 'Sheet', s);
hasSheet = @(s) any(strcmpi(sheetnames(xlsx), s));
T_dt = rd('DataType'); T_if = rd('Interface'); T_pt = rd('Port');
T_rn = rd('Runnable'); T_sg = rd('Signal_NVM');
if hasSheet('Input'), T_in = rd('Input'); else, T_in = {'SignalName','Port','Interface','DataType','Unit','Min','Max','Init','Desc'}; end
if hasSheet('Output'), T_out = rd('Output'); else, T_out = {'SignalName','Port','Interface','DataType','Unit','Min','Max','Init','Desc'}; end
if hasSheet('Calibration'), T_cal = rd('Calibration'); else, T_cal = rd('Parameter'); end

mPath = fullfile(ddDir, [SWCName '_dd.m']);
fid = fopen(mPath, 'w');
fprintf(fid, '%%%% %s_dd 数据字典V2（由dd_excel2m自动生成，勿手改，去改xlsx的Input/Output/Calibration）\n', SWCName);
fprintf(fid, '%%%% 生成时间: %s\n', char(datetime('now')));
fprintf(fid, 'DD = struct(); DD.SWCName = ''%s'';\n', SWCName);
dumpCell(fid, 'DD.Input', T_in);
dumpCell(fid, 'DD.Output', T_out);
dumpCell(fid, 'DD.Calibration', T_cal);
dumpCell(fid, 'DD.DataType', T_dt);
dumpCell(fid, 'DD.Interface', T_if);
dumpCell(fid, 'DD.Port', T_pt);
dumpCell(fid, 'DD.Runnable', T_rn);
dumpCell(fid, 'DD.Signal', T_sg);
% 兼容老代码：DD.Parameter = DD.Calibration（列名CalibName vs Name差异仅首列名不同）
fprintf(fid, 'DD.Parameter = DD.Calibration;\n');
fprintf(fid, ['%%%% 在Base Workspace创建标定量对象（源：Calibration表）\n' ...
    'for kDd = 2:size(DD.Calibration,1)\n' ...
    '  nm = string(DD.Calibration{kDd,1}); dt = string(DD.Calibration{kDd,2});\n' ...
    '  p = Simulink.Parameter; p.Value = str2double(string(DD.Calibration{kDd,6}));\n' ...
    '  p.DataType = char(dt); p.Min = str2double(string(DD.Calibration{kDd,4})); p.Max = str2double(string(DD.Calibration{kDd,5}));\n' ...
    '  p.RTWInfo.StorageClass = ''Model default''; assignin(''base'', char(nm), p);\n' ...
    'end\n']);
fprintf(fid, '%%%% 校验钩子: dd_check(''%s'')\n', SWCName);
fclose(fid);
fprintf('已生成: %s\n', mPath);
end

function dumpCell(fid, varName, C)
fprintf(fid, '%s = {\n', varName);
for r = 1:size(C,1)
    fprintf(fid, '  ');
    for c = 1:size(C,2)
        v = C{r,c};
        if ismissing(v), v = ''; end
        if isnumeric(v), v = num2str(v); else, v = char(string(v)); end
        v = strrep(v, '''', '''''');
        fprintf(fid, '''%s''', v);
        if c < size(C,2), fprintf(fid, ', '); end
    end
    if r < size(C,1), fprintf(fid, ';'); end
    fprintf(fid, '\n');
end
fprintf(fid, '};\n');
end
