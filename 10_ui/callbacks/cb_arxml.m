function cb_arxml(fig)
% cb_arxml ARXML生成+校验
try
    [swc, rootDir] = vcu_cur(fig);
    vcu_log(fig, '生成ARXML...');
    p = arxml_gen(swc, rootDir);
    arxml_check(swc, rootDir);
    vcu_log(fig, ['ARXML完成: ' p]);
catch ME
    vcu_log(fig, ['失败: ' ME.message]);
end
end
