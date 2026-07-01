// FUN_005edfa0  entry=005edfa0  size=15 bytes

uint FUN_005edfa0(int param_1,int param_2)

{
  return (uint)((longlong)param_1 * (longlong)param_2) >> 0x10 |
         (int)((ulonglong)((longlong)param_1 * (longlong)param_2) >> 0x20) << 0x10;
}


