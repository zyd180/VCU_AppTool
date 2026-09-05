try
    swc = bdroot;
    dd_check(swc); req_check(swc);
catch ME
    errordlg(ME.message, 'VCU-检查');
end
