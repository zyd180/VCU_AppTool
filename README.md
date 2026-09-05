# VCU 应用层 AUTOSAR Simulink 开发工具

Classic Platform AUTOSAR 4.4 应用层 SWC 的 Simulink 建模→代码→ARXML→A2L→需求追溯全链工具。
单一数据源：**Excel 数据字典手填**，`.m`字典/模型映射/代码/ARXML/A2L/需求骨架全部由脚本生成。

## 环境要求

MATLAB R2023a + AUTOSAR Blockset + Embedded Coder + Simulink Test/Coverage + Requirements Toolbox。

## 5 分钟上手

```matlab
addpath(genpath('E:\OpenCode\VCU_AppTool'));
new_swc('MySwc');        % 新建SWC全套：字典+模型+需求骨架
% 去 02_dd/MySwc_dd.xlsx 填 Input/Output/Calibration，再回来：
run_all('MySwc');        % 全链：检查→代码→ARXML→A2L→需求链接
req_report('MySwc');     % 需求报告（可选）
```

产物位置：代码 `05_codegen/output/<SWC>/`、ARXML `04_arxml/output/<SWC>/`、
A2L `08_cal/output/<SWC>/`、需求 `09_req/<SWC>_req.slreqx`。

## 目录

```text
00_doc/       naming_spec.md（命名建模规范） user_manual.md（使用手册）
01_template/  建模模板与 ERT/AUTOSAR 统一配置
02_dd/        数据字典：Excel模板生成 / excel2m / 检查 / 四套apply映射
03_model/     各 SWC 模型（TrqArb/BattIf/DemoSwc）
04_arxml/     ARXML 生成与校验        05_codegen/  一键代码生成
06_harness/   仿真 Harness 生成        07_test/     仿真+覆盖率快跑
08_cal/       A2L 导出+地址审计        09_req/      需求骨架/链接/检查/报告
tools/        new_swc / run_all / check_all
```

## 文档索引

- 使用手册：`00_doc/user_manual.md`（从填字典到交付，手把手）
- 命名与建模规范：`00_doc/naming_spec.md`
- 计划与进展：`PLAN.md`；交接坑位：`HANDOFF.md`；变更历史：`CHANGELOG.md`

## 版本管理

SemVer（`VERSION`文件为准，当前见 `CHANGELOG.md` 顶部）：
- `x.y.z`：主版本（工作流/字典结构不兼容变更）`. `次版本（新能力，向后兼容）`. `修订（修bug）`
- 每个版本打 annotated tag `v<VER>`；基线：`git log --oneline`
- 发版流程：更新`VERSION`+`CHANGELOG` → 全量`run_all`回归（TrqArb+BattIf）→ commit → `git tag -a v<VER> -m ...`
