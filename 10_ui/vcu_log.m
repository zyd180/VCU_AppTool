function vcu_log(fig, msg)
% vcu_log 统一日志：界面TextArea追加 + 落10_ui/vcu_tool.log
%   用法: vcu_log(fig, '开始生成...')
if ~isvalid(fig), return; end
line = sprintf('[%s] %s', char(datetime('now','Format','HH:mm:ss')), msg);
try
    ta = findobj(fig, 'Tag', 'VCULog');
    ta.Value = [ta.Value; {line}];
    scroll(ta, 'bottom');
catch, end
try
    rootDir = fig.UserData.rootDir;
    fid = fopen(fullfile(rootDir, '10_ui', 'vcu_tool.log'), 'a');
    fprintf(fid, '%s\n', line);
    fclose(fid);
catch, end
end
