function cb_new_swc(fig)
% cb_new_swc 新建SWC全套（等价new_swc）
try
    f = findobj(fig, 'Tag', 'NewSwcName');
    name = strtrim(char(f.Value));
    assert(~isempty(name), 'SWC名为空');
    rootDir = fig.UserData.rootDir;
    vcu_log(fig, ['新建SWC: ' name]);
    new_swc(name, rootDir);
    d = findobj(fig, 'Tag', 'SWCDrop');
    d.Items = vcu_swc_list(rootDir); d.Value = name;
    vcu_log(fig, '新建完成');
catch ME
    vcu_log(fig, ['失败: ' ME.message]);
end
end
