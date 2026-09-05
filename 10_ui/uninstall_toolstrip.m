function uninstall_toolstrip()
% uninstall_toolstrip 干净卸载VCU工具栏
slDestroyToolstripComponent("vcu");
fprintf('VCU工具栏已卸载\n');
end
