try
    swc = bdroot;
    dd_excel2m(swc); fprintf('字典转.m完成: %s\n', swc);
catch ME
    errordlg(ME.message, 'VCU-字典转.m');
end
