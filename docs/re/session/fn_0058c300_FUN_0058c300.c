// FUN_0058c300  entry=0058c300  size=235 bytes

void __thiscall FUN_0058c300(int *param_1,uint param_2,uint param_3,uint param_4,uint param_5)

{
  int iVar1;
  
  if ((0xf < param_2) && (9 < param_3)) {
    if (param_1[4] != 0) {
      param_1[4] = param_2 / 0x1e + param_1[4];
    }
    param_1[5] = param_1[5] + param_3 / 0x12;
    if (param_1[6] != 0) {
      param_1[6] = param_2 / 0x1e + param_1[6];
    }
    param_1[7] = param_1[7] + param_3 / 0x12;
  }
  FUN_0058c270(param_2,param_3,param_4,param_5);
  param_1[3] = -param_1[3];
  *param_1 = *param_1 + -(param_4 >> 1);
  param_1[1] = -(-(param_5 >> 1) + param_1[1]);
  iVar1 = -(param_4 >> 1) + param_4 / (param_2 * 2);
  param_1[4] = param_1[4] + iVar1;
  param_1[6] = param_1[6] + iVar1;
  iVar1 = -(param_5 >> 1) + param_5 / (param_3 * 2);
  param_1[5] = -(iVar1 + param_1[5]);
  param_1[7] = -(iVar1 + param_1[7]);
  return;
}


