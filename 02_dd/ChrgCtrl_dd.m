%% ChrgCtrl_dd 数据字典V2（由dd_excel2m自动生成，勿手改，去改xlsx的Input/Output/Calibration）
%% 生成时间: 2026-09-06 02:16:19
DD = struct(); DD.SWCName = 'ChrgCtrl';
DD.Input = {
  'SignalName', 'Port', 'Interface', 'DataType', 'Unit', 'Min', 'Max', 'Init', 'Desc';
  'In_VehSpd', 'P_VehSpd', 'If_VehSpd', 'VehSpd', 'km/h', '0', '300', '0', 'vehicle speed input';
  'In_DrvMode', 'P_DrvMode', 'If_DrvMode', 'En_DrvMode', 'none', '0', '2', '1', 'driver mode input'
};
DD.Output = {
  'SignalName', 'Port', 'Interface', 'DataType', 'Unit', 'Min', 'Max', 'Init', 'Desc';
  'Out_DrvTrqReq', 'P_DrvTrqReq', 'If_DrvTrqReq', 'DrvTrqReq', 'Nm', '-500', '2000', '0', 'torque request output'
};
DD.Calibration = {
  'CalibName', 'DataType', 'Unit', 'Min', 'Max', 'Init', 'Desc';
  'Cal_TrqMax', 'single', 'Nm', '0', '2000', '1500', 'max torque cal';
  'Cal_TrqRate', 'single', 'Nm/s', '0', '5000', '2000', 'torque rate limit cal'
};
DD.DataType = {
  'Name', 'BaseType', 'Unit', 'Min', 'Max', 'Init', 'Desc';
  'VehSpd', 'single', 'km/h', '0', '300', '0', 'vehicle speed';
  'DrvTrqReq', 'single', 'Nm', '-500', '2000', '0', 'driver torque request'
};
DD.Interface = {
  'Interface', 'IFType', 'DataType', 'Dim', 'Desc';
  'If_VehSpd', 'SR', 'VehSpd', '1', 'from Input In_VehSpd';
  'If_DrvMode', 'SR', 'En_DrvMode', '1', 'from Input In_DrvMode';
  'If_DrvTrqReq', 'SR', 'DrvTrqReq', '1', 'from Output Out_DrvTrqReq'
};
DD.Port = {
  'Port', 'Dir', 'Interface', 'SignalName', 'Desc';
  'P_VehSpd', 'In', 'If_VehSpd', 'In_VehSpd', 'require speed';
  'P_DrvMode', 'In', 'If_DrvMode', 'In_DrvMode', 'require mode';
  'P_DrvTrqReq', 'Out', 'If_DrvTrqReq', 'Out_DrvTrqReq', 'provide torque'
};
DD.Runnable = {
  'Runnable', 'Period_ms', 'TrigPort', 'AccessedPorts', 'Desc';
  'R_ChrgCtrl_10ms', '10', 'TimingEvent', 'P_VehSpd;P_DrvMode;P_DrvTrqReq', 'main runnable'
};
DD.Signal = {
  'Name', 'Kind', 'DataType', 'Init', 'Desc', 'SrcBlock';
  'Irv_TrqLim', 'IRV', 'DrvTrqReq', '0', 'internal torque limit', '';
  'Meas_TrqOut', 'Meas', 'DrvTrqReq', '0', 'measurement for cal', ''
};
DD.Parameter = DD.Calibration;
%% 在Base Workspace创建标定量对象（源：Calibration表）
for kDd = 2:size(DD.Calibration,1)
  nm = string(DD.Calibration{kDd,1}); dt = string(DD.Calibration{kDd,2});
  p = Simulink.Parameter; p.Value = str2double(string(DD.Calibration{kDd,6}));
  p.DataType = char(dt); p.Min = str2double(string(DD.Calibration{kDd,4})); p.Max = str2double(string(DD.Calibration{kDd,5}));
  p.RTWInfo.StorageClass = 'Model default'; assignin('base', char(nm), p);
end
%% 校验钩子: dd_check('ChrgCtrl')
