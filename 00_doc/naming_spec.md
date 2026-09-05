# 命名与建模规范（冻结V2：字典显式分表）

## 字典分表（Excel手填主入口）
- `Input`：输入信号，`In_<Name>`，列：SignalName/Port(P_)/Interface(If_)/DataType/Unit/Min/Max/Init/Desc。
- `Output`：输出信号，`Out_<Name>`，列同上。
- `Calibration`：标定量，`Cal_<Name>`，列：CalibName/DataType/Unit/Min/Max/Init/Desc。
- `Interface`/`Port`为对照视图（由Input/Output推导），`dd_check`强制双向一致，勿单独手改。
- 跨Input/Output/Calibration信号名全局唯一；Runnable.AccessedPorts只能引用Port表端口。

## 建模
- 求解器：定步长离散，基础步长=最快Runnable周期；模板Target `autosar.tlc`。
- 接口：只用Sender-Receiver（周期）+ Server-Call（诊断/标定服务）；Dto/总线用 `Simulink.Bus`，不许MUX散线跨SWC。
- Runnable：一个周期=一行，命名 `R_<SWC>_<10ms>`；周期用TimingEvent，不许用异步中断直接驱动应用逻辑。
- 多速率：慢速路径须经Rate Transition（工具自动固化Integrity on/Deterministic off）；第i快周期↔入口函数`Periodic:D{i}`；多速率模型端口自动切Explicit（单速率保持Implicit），勿手改。
- 数据：所有增益/查表/阈值必须是 `Simulink.Parameter`（标定量进Parameter表）；状态必须有初值/Min/Max。
- AUTOSAR映射：Inport→RPort(SR Require)，Outport→PPort(SR Provide)，Cal→Component Parameter，IRV→InterRunnableVar；映射由脚本固化，禁止手点后不回写字典。
