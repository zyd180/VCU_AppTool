try
    swc = bdroot;
    export_a2l_hook(swc);
catch ME
    errordlg(ME.message, 'VCU-A2L');
end
