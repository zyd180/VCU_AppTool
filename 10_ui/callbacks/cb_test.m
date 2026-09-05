function cb_test(fig, action)
% cb_test 测试页：harness|run
try
    [swc, rootDir] = vcu_cur(fig);
    switch action
        case 'harness'
            h = harness_gen(swc, rootDir); vcu_log(fig, ['Harness: ' h]);
        case 'run'
            vcu_log(fig, '覆盖率快跑开始...');
            test_run(swc, rootDir); vcu_log(fig, '快跑完成');
    end
catch ME
    vcu_log(fig, ['失败: ' ME.message]);
end
end
