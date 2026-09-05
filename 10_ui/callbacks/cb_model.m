function cb_model(fig, action)
% cb_model 建模页：open|apply（四套映射连跑，不构建）
try
    [swc, rootDir] = vcu_cur(fig);
    slx = fullfile(rootDir, '03_model', [swc '.slx']);
    assert(exist(slx,'file'), '模型不存在，先新建SWC');
    switch action
        case 'open'
            open_system(slx); vcu_log(fig, ['已打开 ' swc]);
        case 'apply'
            open_system(slx);
            dd_apply_interface(swc, rootDir, swc);
            dd_apply_datatype(swc, rootDir, swc);
            dd_apply_runnable(swc, rootDir, swc);
            dd_apply_calibration(swc, rootDir, swc);
            dd_apply_signal(swc, rootDir, swc);
            vcu_log(fig, '全部映射已应用');
    end
catch ME
    vcu_log(fig, ['失败: ' ME.message]);
end
end
