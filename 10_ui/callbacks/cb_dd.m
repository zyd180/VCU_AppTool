function cb_dd(fig, action)
% cb_dd 字典页：open|gen|check
try
    [swc, rootDir] = vcu_cur(fig);
    switch action
        case 'open'
            xlsx = fullfile(rootDir, '02_dd', [swc '_dd.xlsx']);
            assert(exist(xlsx,'file'), '字典不存在');
            winopen(xlsx); vcu_log(fig, ['已打开 ' swc '_dd.xlsx']);
        case 'gen'
            dd_excel2m(swc, rootDir); vcu_log(fig, '转.m完成');
        case 'check'
            [ok, msgs] = dd_check(swc, rootDir);
            if ok, st = '通过'; else, st = '失败'; end
            vcu_log(fig, sprintf('检查%s: %s', st, strjoin(msgs, ' | ')));
    end
catch ME
    vcu_log(fig, ['失败: ' ME.message]);
end
end
