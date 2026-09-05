try
    swc = bdroot;
    test_run(swc);
catch ME
    errordlg(ME.message, 'VCU-测试');
end
