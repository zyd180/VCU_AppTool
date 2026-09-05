/*
 * File: ChrgCtrl.c
 *
 * Code generated for Simulink model 'ChrgCtrl'.
 *
 * Model version                  : 1.7
 * Simulink Coder version         : 9.9 (R2023a) 19-Nov-2022
 * C/C++ source code generated on : Sun Sep  6 02:15:32 2026
 *
 * Target selection: autosar.tlc
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "ChrgCtrl.h"
#include <math.h>
#include "rtwtypes.h"
#include "Rte_Type.h"
#include "ChrgCtrl_private.h"

/* Model step function */
void ChrgCtrl_Step(Rte_Instance self)
{
  float32 rtb_Gain;
  boolean rtb_Compare;

  /* Gain: '<S1>/Gain' incorporates:
   *  Inport: '<Root>/P_VehSpd'
   */
  rtb_Gain = 1.5F * Rte_IRead_R_ChrgCtrl_10ms_P_VehSpd_In_VehSpd(self);

  /* RelationalOperator: '<S2>/Compare' incorporates:
   *  Constant: '<S2>/Constant'
   *  Inport: '<Root>/P_DrvMode'
   */
  rtb_Compare = (Rte_IRead_R_ChrgCtrl_10ms_P_DrvMode_In_DrvMode(self) == ECO);

  /* Switch: '<S1>/Switch' incorporates:
   *  Constant: '<S1>/Cal_TrqMax'
   *  MinMax: '<S1>/Lim'
   */
  if (rtb_Compare) {
    rtb_Gain = fminf(rtb_Gain, Rte_CData_Cal_TrqMax(self));
  }

  /* Outport: '<Root>/P_DrvTrqReq' incorporates:
   *  Switch: '<S1>/Switch'
   */
  Rte_IWrite_R_ChrgCtrl_10ms_P_DrvTrqReq_Out_DrvTrqReq(self, rtb_Gain);
}

/* Model initialize function */
void ChrgCtrl_Init(Rte_Instance self)
{
  /* (no initialization code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
