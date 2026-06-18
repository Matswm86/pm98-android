// FUN_005edfd0  entry=005edfd0  size=22 bytes

uint FUN_005edfd0(int param_1,int param_2,int param_3)

{
  longlong lVar1;
  
  lVar1 = (longlong)
          (int)((uint)((longlong)param_1 * (longlong)param_2) >> 0x10 |
               (int)((ulonglong)((longlong)param_1 * (longlong)param_2) >> 0x20) << 0x10) *
          (longlong)param_3;
  return (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
}


