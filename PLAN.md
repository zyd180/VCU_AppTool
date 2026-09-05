# VCU 应用层 AUTOSAR Simulink 开发工具 — 计划与进展

> 环境：MATLAB R2023a + AUTOSAR Blockset 3.1 + Embedded Coder + Classic 4.4（默认）
> 试点SWC：TrqArb（扭矩仲裁）| 单一数据源：Excel手填 → .m/模型/arxml全生成
> 更新方式：每完成一期勾选复选框并追加“进展记录”。

工作流：需求(.slreqx) → Excel字典 → .m字典 → AUTOSAR模板模型 → 检查 → 代码(.c/.h) → ARXML → RTE/集成 → SIL测试 → 报告

## 目录结构

```text
VCU_AppTool/
  README.md                总览+5分钟上手   CHANGELOG.md  版本历史   VERSION  当前版本
  PLAN.md                  本文件（计划+进展）
  HANDOFF.md               交接坑位
  00_doc/naming_spec.md    命名/建模规范   user_manual.md 使用手册
  01_template/             ert_autosar_config.m, create_swc_template.m
  02_dd/                   create_dd_template.m, dd_excel2m.m, dd_check.m, dd_apply_*.m, TrqArb_dd.xlsx/.m
  03_model/                各SWC模型（如 TrqArb.slx，链接集*.slmx）
  04_arxml/                arxml_gen.m, arxml_check.m, output/
  05_codegen/              codegen_onekey.m, output/
  06_harness/              harness_gen.m
  07_test/                 test_run.m
  08_cal/                  export_a2l_hook.m, output/
  09_req/                   req_gen.m, req_link.m, req_check.m, req_report.m, output/
  tools/                   new_swc.m, check_all.m, run_all.m
```

## SWC划分（应用层）

DrvModeMngt / TrqArb / PwrMngt / BattIf / ChrgCtrl / ThermCtrl / VehSpdEst / DiagMngt。先跑通TrqArb。

## P0 规范冻结 [x]
- [x] 目录建好；命名规范 `00_doc/naming_spec.md`（V2：Input/Output/Calibration分表冻结）
- [x] Excel模板列定义冻结（10 sheets：Info/DataType/Enum/Input/Output/Calibration/Interface/Port/Runnable/Signal_NVM，主入口为Input/Output/Calibration）
- [x] `create_dd_template.m` 可一键生成 `SWCName_dd.xlsx`
- 验收：`create_dd_template('TrqArb')` 生成 xlsx

## P1 字典工具 [x]（V2已优化：Input/Output/Calibration显式分表）
- [x] `dd_excel2m.m`：xlsx → `SWCName_dd.m`（DD.Input/DD.Output/DD.Calibration + 兼容DD.Parameter + Simulink.Parameter）
- [x] `dd_check.m`：In_/Out_/Cal_/P_/If_前缀 + DataType/Enum引用 + 跨表重名 + Min<Max + Interface/Port对照一致 + Runnable全行(R_前缀/唯一/周期数值/端口引用)+周期为基础步长整数倍 + 模型端口/类型一致（含dd_apply_datatype期望值比对）+ Signal_NVM(Kind/前缀/类型/Init/块命名空间冲突) + 模型DSM/SrcBlock/Runnable存在性（多行 warn export-function缺口）
- [x] `dd_apply_signal.m`：Signal_NVM→IRV/NVM建DataStoreMemory并映射ArTypedPerInstanceMemory(NVM带NeedsNVRAMAccess→NV-BLOCK-NEEDS)/Meas按SrcBlock打TestPoint并映射ArTypedPerInstanceMemory，已接入codegen_onekey
- [x] `dd_apply_datatype.m`：Enum页→En_*.m类（Rte_Type.h/Auto）+ Input/Output按DataType/BaseType对齐Inport/Outport类型，已接入codegen_onekey
- 验收：`dd_excel2m('TrqArb')` + `dd_check('TrqArb','TrqArb')` 通过；DataElement Type=Float/En_DrvMode，arxml含COMPU-METHOD

## P2 模板+代码生成 [x]
- [x] `create_swc_template.m`：按字典Input/Output/Calibration建端口+Cal桩（Out轮询挂Cal常量，用户替换为真实算法），新建即调dd_apply_interface
- [x] `ert_autosar_config.m`：统一solver/ERT/autosar.tlc/报告选项
- [x] `02_dd/dd_apply_interface.m`：字典Interface/DataElement真正写进模型（接口If_*重命名+元素In_*/Out_*重命名+mapInport/mapOutport，幂等；多速率自动切Explicit+incremental拾取新端口）
- [x] `02_dd/dd_apply_runnable.m`：字典Runnable表N行写进模型（周期升序↔Periodic:D1..DN，单速率兼容Periodic；runnable重命名/新建+mapFunction+TimingEvent重命名/新建+Period对齐+RateTransition参数固化，幂等）
- [x] `codegen_onekey.m`：load dd → config → check → apply_interface → apply_datatype → apply_runnable → apply_calibration → apply_signal → slbuild → 拷贝.c/.h到output
- 验收：`codegen_onekey('TrqArb')` 产出 `TrqArb.c/.h`，ARXML含If_VehSpd/If_DrvMode/If_DrvTrqReq

## P3 ARXML生成校验 [x]
- [x] `arxml_gen.m`：autosar.api.create/exportARXML，输出到 `04_arxml/output/SWCName.arxml`
- [x] `arxml_check.m`：XML良构 + 关键词（PORT/INTERFACE/RUNNABLE）+ MATLAB可重导入
- 验收：`arxml_gen('TrqArb')` + `arxml_check('TrqArb')` 通过

## P4 落地件 [x]
- [x] `tools/new_swc.m`：一键新建SWC全套文件（含req骨架）；`check_all.m`：字典+模型Advisor；`run_all.m`：全链CI（含req_gen/link/check）
- [x] `09_req/`：字典驱动需求骨架（REQ_SWC_IN/OUT/CAL/RUN，仅缺失生成）+实现链接（IN→Inport/OUT→Outport/CAL→同名块或SWC/RUN→模型，幂等）+req_check（数量一致+逐条有链）+req_report（.docx直落output）
- [x] `harness_gen.m`：顶层Harness+Dataset激励；BSW桩说明
- [x] `08_cal/export_a2l_hook.m`：coder.asap2.export完整导出到08_cal/output/SWC/SWC.a2l + 内容校验（ARXML在场Cal→CHARACTERISTIC、有SrcBlock Meas→MEASUREMENT）
- [x] `02_dd/dd_apply_calibration.m`：Calibration→模型工作区+Constant/Gain按名引用+SharedParameter映射（未引用警告），已接入codegen_onekey
- 验收：`new_swc('DemoSwc')` + `run_all('TrqArb')` 通过；Cal_TrqMax进.c/datatype.arxml/component.arxml

## 常用命令（根目录加path后）

```matlab
addpath(genpath('E:\OpenCode\VCU_AppTool'));
create_dd_template('TrqArb'); dd_excel2m('TrqArb'); dd_check('TrqArb');
create_swc_template('TrqArb'); codegen_onekey('TrqArb'); arxml_gen('TrqArb'); arxml_check('TrqArb');
new_swc('MySwc'); run_all('TrqArb');
```

## 仓库说明
- 本仓库根即项目根（`README.md`/`VERSION`在根目录），无包装层；本地路径 `E:\OpenCode\VCU_AppTool`。
- 历史：2026-09-06前远端曾套 `VCU_AppTool/` 一层，已拍平（force-push），旧 tag v0.1.0/v0.2.0 随旧历史作废，现仅 `v0.3.0`；`E:\OpenCode` 外层仓库已解绑远端，仅作本地工作区容器。
1. Classic 4.4（默认）vs 4.2 — 默认4.4; 2. 试点TrqArb — 默认是; 3. RTE用Vector DaVinci还是仅MATLAB闭环 — 默认仅MATLAB闭环+可导入检查。

## 暂缓项（留档，条件具备再启）
- **厂商RTE冒烟**（暂缓于2026-09-06）：需Vector DaVinci/ISOLAR等外部工具，当前无license。重启条件：任一工具可用。届时动作：将`04_arxml/output/<SWC>/`四件套导入，做组件+接口+数据类型+实现一致性检查，问题回流为`dd_check`/`arxml_check`规则。过渡措施：MATLAB重导入（`arxml.importer`四件套）+ XML良构+关键词已在`arxml_check`覆盖。

## 进展记录
- 2026-09-05：建目录 + 本PLAN初版。MATLAB R2023a/AUTOSAR Blockset 3.1已确认。
- 2026-09-05：P0-P4全部实跑通过。TrqArb全链：xlsx→.m→.slx→.c/.h(05_codegen/output/TrqArb)→arxml 4件套(04_arxml/output/TrqArb，重导入/Components/TrqArb通过)→run_all通过；DemoSwc验证new_swc通过；test_run仿真+覆盖率通过。修复3处：.m多行cell字面量、exist(.slx)=4断言、arxml 4件套导入。
- 2026-09-05：字典V2优化：Input/Output/Calibration显式分表（10 sheets，主入口三表+Interface/Port对照视图），dd_excel2m产出DD.Input/Output/Calibration（兼容DD.Parameter），dd_check新增前缀/跨表重名/对照一致/Runnable引用检查；TrqArb+DemoSwc已重生成并run_all回归通过。
- 2026-09-05：字典Interface真正映射进AUTOSAR端口：新增dd_apply_interface（接口重命名If_*+元素重命名In_*/Out_*+mapInport/mapOutport，幂等），已接入create_swc_template/codegen_onekey；TrqArb验证接口3个+元素3个全对齐，ARXML含If_VehSpd/If_DrvMode/If_DrvTrqReq，重导入通过。遗留：DataElement的Type仍为默认类型，未按字典BaseType做完整DataTypeMapping。
- 2026-09-05：数据类型完整映射落地：新增dd_apply_datatype（Enum页生成En_*.m：Rte_Type.h+Auto+uint8；Input/Output按DataType/Enum对齐端口single/Enum: En_DrvMode；模板内部Gain/Lim/Constant同步single），DataElement Type=Float/En_DrvMode，datatype.arxml含En_DrvMode/ECO/COMPU-METHOD，codegen+arxml+run_all回归通过；dd_check新增模型端口类型比对。
- 2026-09-05：Runnable周期映射落地：新增dd_apply_runnable（Step重命名R_TrqArb_10ms+mapFunction Periodic+事件重命名Event_R_TrqArb_10ms+Period 0.01s，幂等；多行仅映射第一行并警告），已接入codegen_onekey；ARXML含R_TrqArb_10ms/Event_R_TrqArb_10ms（残留TrqArb_Step仅为 runnable SYMBOL，属正常），.c含R_TrqArb_10ms入口，run_all全绿；dd_check新增Runnable名比对。
- 2026-09-05：标定量映射落地：新增dd_apply_calibration（Calibration→模型工作区+同名Constant/Gain引用+SharedParameter映射；Base→模型工作区拷贝StorageClass置Auto；未引用Cal警告），模板Constant改引用Cal_TrqMax；Cal_TrqMax进.c/datatype.arxml/component.arxml，Cal_TrqRate未被引用正确裁剪并两处告警；export_a2l_hook新增ARXML覆盖率检查；dd_check新增标定工作区+映射检查；run_all全绿。
- 2026-09-05：模板字典驱动+第二个SWC：create_swc_template改按字典建端口（Inport/Outport/Cal常量桩，Out轮询挂Cal），new_swc('BattIf')+run_all('BattIf')一次跑通（代码+ARXML 5件+重导入/Components/BattIf），TrqArb回归全绿，复用性得证。注意各SWC示例字典内容仍相同，真实SWC需各自填写信号。
- 2026-09-05：Signal_NVM映射落地：新增dd_apply_signal（IRV/NVM→DataStoreMemory+ArTypedPerInstanceMemory，NVM带NeedsNVRAMAccess→NV-BLOCK-NEEDS；Meas→SrcBlock输出TestPoint+addSignal+mapSignal；SrcBlock空/DSM无人读写仅警告，参照Cal先例），Signal_NVM表新增SrcBlock列；TrqArb(Meas→Lim)/BattIf(Meas→Cal_TrqMax)全绿，Meas/Irv均进component.arxml；NVM经TmpSig划痕验证（NV-BLOCK-NEEDS落盘）后清理；dd_check新增Signal_NVM合法性+模型一致性。修过3处：ismissing对char返回向量不可&&（抽getText）、Meas用StaticMemory多实例构建失败改ArTypedPerInstanceMemory、Signal_NVM基类型single被check误杀。
- 2026-09-05：完整A2L导出落地：export_a2l_hook改调coder.asap2.export（输出08_cal/output/SWC/SWC.a2l）+内容校验（ARXML在场Cal、有SrcBlock Meas）；TrqArb/BattIf run_all全绿，.a2l含Cal_TrqMax/Meas_TrqOut，未引用量正确缺席。前提：本会话刚构建过（run_all天然满足），单独跑须先codegen_onekey。
- 2026-09-05：多速率探针结论（未进模板）：率式多速率会被折叠进单runnable（构建证实仅1个RUNNABLE-ENTITY），且慢速端口Implicit读写构建失败、必须Explicit；真多runnable须export-function（FCS逐个映射）新模板。配套落地：dd_check Runnable全行校验（R_前缀/唯一/周期数值/周期为基础步长整数倍/模型存在性，多行warn指HANDOFF），正向TrqArb/BattIf通过，负向TmpNeg划痕验证（坏前缀/缺runnable均判失败）后清理。
- 2026-09-05：真多runnable落地（率式，无需FCS）：dd_apply_runnable重写N行（周期升序↔Periodic:D1..DN，单速率兼容Periodic；runnable新建用Runnables属性、事件新建用Events+Category TimingEvent）+dd_apply_interface多速率自动切Explicit+incremental拾取新端口+RT参数固化(Integrity on/Deterministic off)；TmpExp划痕（10ms+100ms经Rate Transition）run_all全绿，ARXML含双runnable/双事件（0.01/0.1s），TrqArb/BattIf单速率回归全绿；dd_check新增速率数==Runnable行数。修过3处：FCS探针连线连错Inport（须连Trigger柄；后证伪FCS不需要）、新增端口未映射（incremental）、RT默认Deterministic on构建失败。划痕已清理。
- 2026-09-06：需求追溯落地：09_req四件套（req_gen字典驱动骨架/req_link实现链接/req_check数量+逐条有链/req_report直落output），已接入new_swc与run_all；TrqArb/BattIf各6条需求6条链接全绿。修过4处：Requirement属性是Id非id、删链用remove非delete（delete静默无效致重复堆积）、去重判据走inLinks.source（artifact+SID后缀）、报告用reportPath直落（根目录docx被锁删不掉，已进gitignore）。
- 2026-09-06：A2L地址审计落地：export_a2l_hook新增可选MapFile透传+ECU_ADDRESS全0审计（占位告警并指重导命令）；实测本环境无可链接二进制（AUTOSAR target不产.exe），当前.a2l地址确为全0占位，真实地址须目标ELF——能力已就绪，缺目标链。
- 2026-09-06：跨runnable IRV显式传递探针结论（未落地，止损）：约20组探针证实R2023a率式下`mapDataTransfer`无程序化入口——`find(slMap,"DataTransfers")`恒空（新版才返string数组），RT直连Outport/子系统边界/D1真信号/具名信号线/信号对象/映射重建/slbuild后均报"does not exist"；官方流程依赖Code Mappings编辑器Update按钮（无等效API）+ demo自带预建IRV/传输。已验证：模式串须是`Implicit`/`Explicit`（非Send/Receive后缀）、IRV须先`arProps.add(ib,'IRV',name)`。 workaround：GUI Update一次后按名映射；工具侧保持DSM+ArTypedPerInstanceMemory等效方案。划痕TmpIrv2/TmpCtl已清理。
- 2026-09-06：文档与版本管理落地：新增README/CHANGELOG/使用手册（00_doc/user_manual.md）/VERSION(0.3.0)，run_all打印工具版本；版本策略SemVer写入README（发版=更新VERSION+CHANGELOG→双SWC回归→commit→tag）。
- 2026-09-06：UI计划定稿（00_doc/ui_plan.md）：App Designer改纯代码uifigure（10_ui/vcu_app.m，二进制不可验证），Simulink工具栏走官方custom tab路线；U1完成（7页壳+日志+SWC下拉+关于页环境检查），实测通过。修过3处R2023a坑：findobj链式赋值非法、ver须ver()、string不支持*。
