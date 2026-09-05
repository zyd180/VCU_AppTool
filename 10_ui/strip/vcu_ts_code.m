try
    swc = bdroot;
    codegen_onekey(swc);
catch ME
    errordlg(ME.message, 'VCU-一键代码');
end
