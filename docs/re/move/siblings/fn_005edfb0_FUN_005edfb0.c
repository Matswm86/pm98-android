// FUN_005edfb0  entry=005edfb0  size=31 bytes

uint FUN_005edfb0(int param_1,int param_2,int param_3,int param_4)

{
  longlong lVar1;
  
  lVar1 = (longlong)param_3 * (longlong)param_4 + (longlong)param_1 * (longlong)param_2;
  return (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
}


