try
    vcu_app();
catch ME
    errordlg(ME.message, 'VCU-打开App');
end
