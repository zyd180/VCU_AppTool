function cb_req(fig, action)
% cb_req 需求页：gen|link|check|report
try
    [swc, rootDir] = vcu_cur(fig);
    switch action
        case 'gen'
            req_gen(swc, rootDir); vcu_log(fig, '需求骨架就绪');
        case 'link'
            n = req_link(swc, rootDir); vcu_log(fig, sprintf('链接完成，新增%d条', n));
        case 'check'
            [ok, msgs] = req_check(swc, rootDir);
            if ok, st = '通过'; else, st = '失败'; end
            vcu_log(fig, sprintf('检查%s: %s', st, strjoin(msgs, ' | ')));
        case 'report'
            p = req_report(swc, rootDir); vcu_log(fig, ['报告: ' p]);
    end
catch ME
    vcu_log(fig, ['失败: ' ME.message]);
end
end
