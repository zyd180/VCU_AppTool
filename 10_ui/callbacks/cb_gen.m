function cb_gen(fig)
% cb_gen 一键代码（等价codegen_onekey，耗时数分钟）
try
    [swc, rootDir] = vcu_cur(fig);
    vcu_log(fig, ['开始生成代码: ' swc]);
    outDir = codegen_onekey(swc, rootDir);
    vcu_log(fig, ['代码完成: ' outDir]);
catch ME
    vcu_log(fig, ['失败: ' ME.message]);
end
end
