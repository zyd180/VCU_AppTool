/*
 * File: BattIf.c
 *
 * Code generated for Simulink model 'BattIf'.
 *
 * Model version                  : 1.12
 * Simulink Coder version         : 9.9 (R2023a) 19-Nov-2022
 * C/C++ source code generated on : Sun Sep  6 00:28:06 2026
 *
 * Target selection: autosar.tlc
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "BattIf.h"
#include "BattIf_private.h"

/* Model step function */
void BattIf_Step(Rte_Instance self)
{
  /* Constant: '<Root>/Cal_TrqMax' */
  *Rte_Pim_Meas_TrqOut(self) = Rte_CData_Cal_TrqMax(self);

  /* Outport: '<Root>/P_DrvTrqReq' */
  Rte_IWrite_R_BattIf_10ms_P_DrvTrqReq_Out_DrvTrqReq(self, *Rte_Pim_Meas_TrqOut
    (self));
}

/* Model initialize function */
void BattIf_Init(Rte_Instance self)
{
  /* (no initialization code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
