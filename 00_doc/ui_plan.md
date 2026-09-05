# VCU工具 UI界面 + Simulink工具栏装载 — 计划与项目架构

> 状态：计划（待评审后开工）。后端全部就绪，本计划只做表现层，不动任何 `dd_*`/`run_all` 逻辑。

## 1. 技术路线（已调研，R2023a 可用）

| 部位 | 方案 | 依据 |
|---|---|---|
| 完整UI | 纯代码 uifigure 应用 `10_ui/vcu_app.m`（多页签），打包 `.mlappinstall` 进 MATLAB Apps 页 | 原定App Designer `.mlapp`，因二进制不可diff/不可脚本验证，改纯代码实现，页面与回调分离不变 |
| Simulink工具栏 | 自定义 **VCU 选项卡**：`slCreateToolstripComponent("vcu")` + `slCreateToolstripTab`，按钮回调调后端函数/打开App，`slReloadToolstripConfig` 生效，默认跨会话持久 | Since R2021b，R2023a可用 |
| 不做 | 往 Simulink 自带 APPS 页塞图标 | MathWorks官方确认不可行 |

UI 与后端解耦：界面只做参数收集+调用+日志展示，所有逻辑仍走现有函数（单一数据源不断）。

## 2. 项目架构（新增 `10_ui/`，其余不动）

```text
10_ui/
  vcu_app.m              主界面（uifigure，7页签；回调只组参调后端）
  callbacks/             按钮回调（每页1个.m，只组参+调后端+写日志，不写逻辑）
    cb_new_swc.m  cb_dd.m  cb_model.m  cb_gen.m
    cb_arxml.m    cb_cal.m cb_req.m    cb_test.m
  vcu_log.m              统一日志（TextArea追加+写10_ui/vcu_tool.log）
  vcu_swc_list.m         扫描03_model}{*}.slx列SWC下拉（唯一模型发现入口）
  resources/             Simulink工具栏组件（slCreateToolstripComponent生成）
    sl_toolstrip_plugins.json  （勿手改）
    json/vcuTab.json            选项卡布局（Section/Column/Button）
    json/vcuTab_actions.json    自定义动作→回调（含打开App）
    icons/                      按钮图标（16px png，自绘三色块，勿用外部图）
  install_toolstrip.m    一键装载：建component+tab+reload（幂等，已存在跳过）
  uninstall_toolstrip.m  卸载：slDestroyToolstripComponent
  package_app.m          打包.mlappinstall（含版本号=VERSION）
```

工具栏 VCU 选项卡布局（1 tab × 4 section）：

```text
[新建] 新建SWC… ｜ [字典] 模板|转.m|检查 ｜ [生成] 配置|一键代码|ARXML|A2L ｜ [验证] Harness|测试|需求报告|打开App
```

另嵌入2个内置动作：仿真运行、模型顾问（prepopulated tab已有现成action名，照抄）。

## 3. App页面（7页，对应工作流）

1. **新建**：SWC名输入→调`new_swc`→刷新下拉
2. **字典**：选SWC→打开Excel/转.m/检查（文本框显示`dd_check`结果）
3. **建模**：打开模型/打开模板库/应用全部映射（`dd_apply_*`四连）
4. **生成**：一键代码（显示产物列表）、ARXML生成校验、A2L导出（含ELF路径可选框）
5. **需求**：生成骨架/链接/检查/报告（报告按钮打开output）
6. **测试**：Harness生成/覆盖率快跑（显示覆盖率数字）
7. **关于**：工具版本（读VERSION）/git hash/环境检查（toolbox缺失标红）

## 4. 分期（共4期，每期独立可验）

- **U1 App壳+日志+SWC下拉**：`VCU_App.mlapp`可打开，7页空壳，日志/下拉/版本页可用。验收：App内看到版本号+SWC列表。
- **U2 回调全接通**：8个回调逐个调通后端并实测，`package_app.m`打包向导（R2023a无纯脚本打包API，校验文件+开对话框手动两步；主分发走U3工具栏）。验收：App内点完全链（TrqArb）与命令行结果一致。
- **U3 工具栏装载**：`install_toolstrip.m` + JSON布局 + 自定义动作，Simulink里出现VCU选项卡，按钮与App等价。验收：新开Simulink+任意模型，VCU页可见可用；`uninstall`干净卸载。
- **U4 收尾**：图标、中文tooltip、异常弹窗（后端warning/error转UI红字不断连）、README/手册补UI章节、打版。

## 5. 约束与风险

- R2023a无`slUpdateToolstripComponent`（R2023b+才有），改JSON后用全量`slReloadToolstripConfig`。
- UI全纯代码（`.mlapp`二进制不可diff、不可脚本验证，已弃用）：`vcu_app.m`只摆控件，逻辑全在`callbacks/*.m`与后端函数。
- 团队MATLAB版本须统一R2023a（toolstrip JSON跨大版本不保证兼容），记入手册。
- 预估：U1半天，U2两天，U3一天，U4一天。
