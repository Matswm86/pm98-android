// FUN_005ee500  entry=005ee500  size=57 bytes

uint __thiscall FUN_005ee500(int *param_1,int *param_2)

{
  longlong lVar1;
  
  lVar1 = (longlong)param_1[1] * (longlong)param_2[1] + (longlong)*param_1 * (longlong)*param_2 +
          (longlong)param_1[2] * (longlong)param_2[2];
  return (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
}


