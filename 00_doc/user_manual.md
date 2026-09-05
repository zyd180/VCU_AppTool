# VCU AUTOSAR 开发工具 — 使用手册

> 适用版本：见根目录 `VERSION`。先通读本手册第 1–2 节，再动手。

## 1. 安装与环境

1. MATLAB R2023a，装好 AUTOSAR Blockset、Embedded Coder、Simulink Test/Coverage、Requirements Toolbox。
2. MATLAB 里执行一次（每次新会话都要执行）：
   ```matlab
   addpath(genpath('E:\OpenCode\VCU_AppTool'));
   ```
3. 验收环境：`run_all('TrqArb')` 全绿即正常。

## 2. 核心概念（3 条铁律）

1. **Excel 是唯一手填入口**：`02_dd/<SWC>_dd.xlsx`。`.m`字典/模型映射/代码/ARXML/A2L/需求全部由脚本生成，**不许反向手改生成物**（手改下次运行即被覆盖）。
2. **命名即接口**：`In_`输入/`Out_`输出/`Cal_`标定/`Irv_`内部/`Nvm_`非易失/`Meas_`测量/`P_`端口/`If_`接口/`R_`任务/`En_`枚举。详见 `naming_spec.md`。
3. **检查先行**：任何报错先看 `dd_check` 输出，它会精确指出哪张表哪一行；模型侧问题看 Diagnostic Viewer。

## 3. 新建 SWC（标准流程）

```matlab
new_swc('BattIf');   % 生成 xlsx + _dd.m + 模板模型 + 需求骨架
```

1. 打开 `02_dd/BattIf_dd.xlsx`，按第 4 节填 **Input / Output / Calibration** 三张主表（Interface/Port 为对照视图，`dd_check`强制一致，勿单独改）。
2. 在模型里实现算法（模板 Out 已轮询挂 Cal 桩，直接替换连线即可；端口名/P_勿改）。
3. 多速率：Runnable 表加行（如 100ms）+ 慢速路径经 Rate Transition → 工具自动建多 runnable（见 5.3）。
4. 跑全链：`run_all('BattIf')`。绿了去各 `output/` 取产物；红了看第 6 节排错。

## 4. 字典填表指南（列定义）

| 表 | 列 | 说明 |
|---|---|---|
| Info | Item/Value | SWC名/版本/作者/变更记录 |
| DataType | Name/BaseType/Unit/Min/Max/Init/Desc | 逻辑类型→Simulink基类型（如 VehSpd→single） |
| Enum | EnumName/Value/Text/Desc | 按枚举名分组多行，生成 `En_*.m` 类 |
| Input | SignalName/Port/Interface/DataType/Unit/Min/Max/Init/Desc | SignalName `In_`开头，Port `P_`开头，Interface `If_`开头 |
| Output | 同上 | SignalName `Out_`开头 |
| Calibration | CalibName/DataType/Unit/Min/Max/Init/Desc | `Cal_`开头；未被模块引用的会被代码/ARXML裁剪（告警属正常） |
| Interface/Port | 对照视图 | 由 Input/Output 推导，保持一致即可 |
| Runnable | Runnable/Period_ms/TrigPort/AccessedPorts/Desc | `R_`开头；周期须为基础步长整数倍；AccessedPorts 填 `P_`端口分号分隔 |
| Signal_NVM | Name/Kind/DataType/Init/Desc/SrcBlock | Kind∈{IRV,NVM,Meas}；Meas 填 SrcBlock（被测块名），空则仅登记；IRV/NVM 无读写引用时代码裁剪、ARXML保留声明（告警属正常） |

## 5. 命令参考

| 命令 | 作用 | 何时用 |
|---|---|---|
| `create_dd_template('X')` | 生成空白字典 xlsx | 模板升级后重建（会覆写！有填写内容勿用） |
| `dd_excel2m('X')` | xlsx→`X_dd.m`+标定量进工作区 | 字典改动后（`run_all`已含，可单独跑） |
| `dd_check('X'[,'X'])` | 字典合法性（+模型一致性） | 随时；红了先修字典 |
| `create_swc_template('X')` | 按字典建端口模板模型 | 新SWC（`new_swc`已含） |
| `codegen_onekey('X')` | 配置→四套apply→slbuild→拷`.c/.h` | 单独出代码（`run_all`已含） |
| `arxml_gen/check('X')` | ARXML四件套+重导入校验 | 单独出ARXML（`run_all`已含） |
| `export_a2l_hook('X'[,,elf])` | A2L导出+内容/地址审计 | 单独出A2L；有目标ELF传第三参得真实地址 |
| `harness_gen('X')` | 顶层仿真 Harness | 闭环仿真 |
| `test_run('X')` | 仿真+覆盖率快跑 | 自测 |
| `req_gen/link/check/report('X')` | 需求骨架/链接/检查/报告 | 需求变更后；`req_gen`字典增行后须删`.slreqx`重建 |
| `check_all('X')` | 字典+Model Advisor | 提审前 |
| `run_all('X')` | 上述全链（req/acode/arxml/a2l/追溯） | **交付唯一入口**，红即停 |

## 6. 排错（按报错定位）

- `dd_check`报某某表：按信息修Excel对应行（重名/前缀/引用/范围/集合不一致）。
- 构建报端口/类型：确认模型端口名与字典Port表一致，跑 `dd_apply_datatype`（类型）/`dd_apply_interface`（映射）。
- `MapFile不存在`：A2L要真实地址必须先有目标ELF；无ELF即接受全0占位告警。
- `需求数与字典行数不一致`：字典增行了，删 `09_req/<SWC>_req.slreqx` 后重跑（手填需求内容请先备份）。
- 枚举类改完构建仍旧：`clear classes; rehash` 后重跑（MATLAB类缓存）。
- 切SWC工作：先存盘旧模型，再 `run` 对应 `<SWC>_dd.m`（Base工作区标定量会被覆盖）。
- 更多坑位见 `HANDOFF.md`（已知坑位节，meeting前必读）。

## 7. 交付清单（给集成方的输出）

`05_codegen/output/<SWC>/`（`.c/.h`）、`04_arxml/output/<SWC>/`（四件套+`<SWC>.arxml`）、
`08_cal/output/<SWC>/`（`.a2l`）、`09_req/output/<SWC>/`（需求报告），外加本工具版本号（`run_all`尾行打印）。
