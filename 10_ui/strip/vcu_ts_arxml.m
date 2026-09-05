try
    swc = bdroot;
    arxml_gen(swc); arxml_check(swc);
catch ME
    errordlg(ME.message, 'VCU-ARXML');
end
