try
    a = inputdlg('新SWC名（大驼峰，如 BattIf）:', 'VCU-新建SWC', 1, {'MySwc'});
    if ~isempty(a), new_swc(strtrim(a{1})); fprintf('new_swc完成: %s\n', strtrim(a{1})); end
catch ME
    errordlg(ME.message, 'VCU-新建SWC');
end
