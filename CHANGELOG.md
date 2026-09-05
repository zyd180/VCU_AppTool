# 更新日志（Keep a Changelog 口径，按版本倒序）

## [0.4.1] - 2026-09-06
### 修正
- 工具栏按钮标签统一两行（字典转.m/字典检查/生成arxml/导出A2L/测试快跑）
- 列宽固定方案回退（R2023a行为不可控，`width`不再使用）

## [0.4.0] - 2026-09-06
### 新增
- 完整UI `10_ui/vcu_app.m`（uifigure 7页：新建/字典/建模/生成/需求/测试/关于，日志同步写文件）
- `callbacks/`8回调全接通后端；`package_app.m`打包向导
- Simulink工具栏VCU选项卡（新建/字典/生成/验证四组，作用当前模型；`install/uninstall_toolstrip`）
### 说明
- `.mlapp`改纯代码实现（二进制不可diff/不可脚本验证）；R2023a无纯脚本`.mlappinstall`打包API

## [0.3.0] - 2026-09-06
### 新增
- 真多runnable（率式）：`dd_apply_runnable`重写N行（周期升序↔`Periodic:D1..DN`），runnable/事件新建，RT参数固化，多速率自动开multitasking+端口切Explicit+incremental拾取新端口
- 需求追溯 `09_req/`四件套：`req_gen`字典驱动骨架、`req_link`实现链接（幂等）、`req_check`（数量+逐条有链）、`req_report`；已接入`new_swc`与`run_all`
- `export_a2l_hook`：可选`MapFile`透传 + `ECU_ADDRESS`全0审计
- `dd_check`：Runnable全行校验（前缀/唯一/周期/基础步长整数倍/速率数==行数）、Signal_NVM合法性+模型一致性
### 修正
- `run_all`对`req_check`失败硬中断（此前追溯过期仍报通过）
### 验证
- TmpExp/TmpCtl划痕：双runnable+双事件（0.01/0.1s）全绿后清理；TrqArb/BattIf回归全绿

## [0.2.0] - 2026-09-05
### 新增
- `dd_apply_signal`：Signal_NVM→DSM(IRV/NVM，NVM带NVRAM→`NV-BLOCK-NEEDS`)/Meas(TestPoint+映射)，`Signal_NVM`表新增`SrcBlock`列
- `coder.asap2.export`完整A2L导出+内容校验（`08_cal/output/`）
- 跨runnable IRV探针结论：R2023a率式下无程序化入口，留档（见PLAN）
### 验证
- TrqArb/BattIf `run_all`全绿；NVM经TmpSig划痕验证后清理

## [0.1.0] - 2026-09-05
### 新增
- 项目骨架：目录、`PLAN.md`、命名建模规范、Excel字典V2（10表，主入口Input/Output/Calibration）
- `dd_excel2m`/`dd_check`、`create_swc_template`（字典驱动端口）、`ert_autosar_config`
- 四套映射：`dd_apply_interface`（接口/元素名）、`dd_apply_datatype`（基类型/枚举类）、`dd_apply_runnable`（单速率）、`dd_apply_calibration`（SharedParameter）
- `codegen_onekey`、`arxml_gen`/`arxml_check`（四件套+重导入）、`harness_gen`、`test_run`、`new_swc`/`check_all`/`run_all`
### 验证
- TrqArb首个SWC全链通过；`new_swc('BattIf')`复用性得证
