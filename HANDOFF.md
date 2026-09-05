# 交接注记（给下一个模型 / 接手人）

> 基线状态：TrqArb + BattIf `run_all` 全绿。先读 `PLAN.md`，再跑 `run_all('TrqArb')` 验收环境。

## 已知坑位（正常现象，勿“修复”）
1. `exist(xxx.slx,'file')` 返回 **4** 不是 2，断言须用 `exist(...)` 非零判断。
2. 枚举类（`02_dd/En_*.m`）改完必须 `clear classes` + `rehash`，否则构建仍用缓存定义。
3. 枚举类 AUTOSAR 构建要求：`getHeaderFile()='Rte_Type.h'` 且 `getDataScope()='Auto'`（Exported会构建失败）。
4. ARXML 交付是 **4件套**（component/datatype/interface/implementation），`arxml.importer` 必须传全部文件，单component文件重导入必失败。
5. `mapParameter` 有效值是 `Auto/SharedParameter/ConstantMemory`（`CalPRM`非法）；参数须在**模型工作区**（Base工作区的不认）。
6. 未被模块引用的Cal（如Cal_TrqRate）会被代码/ARXML裁剪，`dd_apply_calibration`与`export_a2l_hook`两处告警是**预期行为**。
7. `codegen_onekey` 开头 `close_system(model,0)` 会**丢弃未保存的手改**，跑前先存盘。
8. `TrqArb_Step` 残留在ARXML属正常：它是runnable `R_TrqArb_10ms` 的SYMBOL（代码符号），不是映射失败。
9. `dd_apply_*.m` 均幂等，可重复跑；`DD`/标定量在Base工作区分SWC互相覆盖，切换SWC先跑对应`SWC_dd.m`。

## 未做事项
- 各SWC示例字典内容雷同，真实SWC需各自填写信号；`DemoSwc`是旧固定模板产物。
- 厂商RTE冒烟：见PLAN“暂缓项”，需DaVinci/ISOLAR license。
- A2L真实地址：能力就绪（MapFile透传+全0审计），缺目标链ELF。
- 跨runnable IRV显式传递（`mapDataTransfer`）：R2023a率式下无程序化入口，详见PLAN 2026-09-06探针结论；workaround为GUI Update后按名映射；当前DSM+ArTypedPerInstanceMemory为单runnable内等效。

## 多速率用法（2026-09-05已落地，TmpExp/TmpCtl双划痕验证）
- 字典Runnable加行（如100ms）+ 模型慢速路径经Rate Transition → 跑`run_all`即得N个runnable/N个TimingEvent。
- 工具自动处理：multitasking按需开（多行才开，单速率不动）、`Periodic:D1..DN`映射、端口切Explicit、新端口incremental拾取、RT参数固化。
- 更早的“折叠进单runnable”结论作废：当时探针RT块被误删，模型实际已退化为单速率，特此纠正。

## 本次新增坑位（Signal_NVM）
10. `ismissing`对char返回逐字符向量，不可与`&&`连用——取文本统一走`getText`（dd_apply_signal/dd_check内嵌）。
11. Meas映射不可用`StaticMemory`（多实例SWC构建失败），须用`ArTypedPerInstanceMemory`。
12. Signal_NVM的DataType列允许基类型（single/double…，与Calibration一致），仅限逻辑名会误杀。
13. DSM无人读写/Meas无SrcBlock时仅警告：ARXML保留声明、代码裁剪，属预期行为（同Cal_TrqRate先例）。
14. `coder.asap2.export`须本会话构建后调用（run_all顺序天然满足）；单独跑先`codegen_onekey`，否则报“未编译”错。
15. slreq坑：Requirement属性是`Id`（`id`小写报错）；删链用`remove()`（`delete()`静默无效，重复堆积）；幂等判据走需求侧`inLinks.source`（artifact+SID去模型名前缀）；报告用`reportPath`+`openReport=false`直落output（默认落根且文件被锁删不掉，见.gitignore）。
16. 多速率三机制（缺一即退化单Periodic）：`EnableMultiTasking=on`（工具多行自动开）+ 离散多速率（RT实现）+ 映射时D1..DN；另`find(slMap,"DataTransfers")`在R2023a恒空，跨runnable显式IRV走GUI，见PLAN。
