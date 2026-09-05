function ert_autosar_config(model)
% ert_autosar_config 统一求解器/ERT/AUTOSAR配置（幂等，可重复跑）
if ~bdIsLoaded(model), load_system(model); end
set_param(model, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
    'FixedStep', '0.01', 'StopTime', '10', 'SystemTargetFile', 'autosar.tlc');
set_param(model, 'TargetLang', 'C', 'GenerateReport', 'on', ...
    'CodeInterfacePackaging', 'Reusable function');
try set_param(model, 'AutosarSchemaVersion', '4.4'); catch, end
% ERT内存/效率常用项（不锁死硬件，按需在模型里覆盖）
try set_param(model, 'SupportContinuousTime', 'off'); catch, end
try set_param(model, 'SupportNonInlinedSFcns', 'off'); catch, end
save_system(model);
fprintf('已配置 %s (autosar.tlc/定步长离散/4.4)\n', model);
end
