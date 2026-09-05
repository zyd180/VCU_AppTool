function cb_cal(fig)
% cb_cal A2L导出（ELF路径框可选填）
try
    [swc, rootDir] = vcu_cur(fig);
    f = findobj(fig, 'Tag', 'ElfPath');
    elf = strtrim(char(f.Value));
    vcu_log(fig, '导出A2L...');
    if isempty(elf)
        p = export_a2l_hook(swc, rootDir);
    else
        p = export_a2l_hook(swc, rootDir, elf);
    end
    vcu_log(fig, ['A2L完成: ' p]);
catch ME
    vcu_log(fig, ['失败: ' ME.message]);
end
end
