try
    swc = bdroot;
    run_all(swc);
catch ME
    errordlg(ME.message, 'VCU-全链');
end
