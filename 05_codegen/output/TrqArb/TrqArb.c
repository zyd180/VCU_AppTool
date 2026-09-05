/*
 * File: TrqArb.c
 *
 * Code generated for Simulink model 'TrqArb'.
 *
 * Model version                  : 1.30
 * Simulink Coder version         : 9.9 (R2023a) 19-Nov-2022
 * C/C++ source code generated on : Sun Sep  6 00:46:57 2026
 *
 * Target selection: autosar.tlc
 * Embedded hardware selection: Intel->x86-64 (Windows64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "TrqArb.h"
#include <math.h>
#include "rtwtypes.h"
#include "TrqArb_private.h"

/* Model step function */
void TrqArb_Step(Rte_Instance self)
{
  float32 rtb_Gain;

  /* Gain: '<Root>/Gain' incorporates:
   *  Inport: '<Root>/P_VehSpd'
   */
  rtb_Gain = 1.5F * Rte_IRead_R_TrqArb_10ms_P_VehSpd_In_VehSpd(self);

  /* MinMax: '<Root>/Lim' incorporates:
   *  Constant: '<Root>/Cal_TrqMax'
   */
  *Rte_Pim_Meas_TrqOut(self) = fminf(rtb_Gain, Rte_CData_Cal_TrqMax(self));

  /* Outport: '<Root>/P_DrvTrqReq' */
  Rte_IWrite_R_TrqArb_10ms_P_DrvTrqReq_Out_DrvTrqReq(self, *Rte_Pim_Meas_TrqOut
    (self));
}

/* Model initialize function */
void TrqArb_Init(Rte_Instance self)
{
  /* (no initialization code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
