// FUN_005ee540  entry=005ee540  size=124 bytes

void __thiscall FUN_005ee540(int *param_1,uint *param_2,int *param_3)

{
  longlong lVar1;
  longlong lVar2;
  longlong lVar3;
  
  lVar1 = (longlong)param_1[1] * (longlong)param_3[2] - (longlong)param_1[2] * (longlong)param_3[1];
  lVar2 = (longlong)param_1[2] * (longlong)*param_3 - (longlong)*param_1 * (longlong)param_3[2];
  lVar3 = (longlong)*param_1 * (longlong)param_3[1] - (longlong)param_1[1] * (longlong)*param_3;
  *param_2 = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  param_2[1] = (uint)lVar2 >> 0x10 | (int)((ulonglong)lVar2 >> 0x20) << 0x10;
  param_2[2] = (uint)lVar3 >> 0x10 | (int)((ulonglong)lVar3 >> 0x20) << 0x10;
  return;
}


