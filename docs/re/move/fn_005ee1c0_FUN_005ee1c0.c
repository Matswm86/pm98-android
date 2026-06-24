// FUN_005ee1c0  entry=005ee1c0  size=61 bytes

uint * __thiscall FUN_005ee1c0(uint *param_1,int param_2)

{
  *param_1 = (uint)((longlong)(int)*param_1 * (longlong)param_2) >> 0x10 |
             (int)((ulonglong)((longlong)(int)*param_1 * (longlong)param_2) >> 0x20) << 0x10;
  param_1[1] = (uint)((longlong)(int)param_1[1] * (longlong)param_2) >> 0x10 |
               (int)((ulonglong)((longlong)(int)param_1[1] * (longlong)param_2) >> 0x20) << 0x10;
  param_1[2] = (uint)((longlong)(int)param_1[2] * (longlong)param_2) >> 0x10 |
               (int)((ulonglong)((longlong)(int)param_1[2] * (longlong)param_2) >> 0x20) << 0x10;
  return param_1;
}


