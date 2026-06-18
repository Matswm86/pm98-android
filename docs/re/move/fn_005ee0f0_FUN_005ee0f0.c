// FUN_005ee0f0  entry=005ee0f0  size=114 bytes

uint * __thiscall FUN_005ee0f0(uint *param_1,int param_2,short param_3)

{
  int iVar1;
  int iVar2;
  
  iVar1 = *(int *)(&DAT_006d31c8 + (param_3 + 8 >> 4 & 0xfffU) * 4);
  iVar2 = *(int *)(&DAT_006d31c8 + (0x3ff8 - param_3 >> 4 & 0xfffU) * 4);
  param_1[2] = 0;
  *param_1 = (uint)((longlong)param_2 * (longlong)iVar1) >> 0x10 |
             (int)((ulonglong)((longlong)param_2 * (longlong)iVar1) >> 0x20) << 0x10;
  param_1[1] = (uint)((longlong)param_2 * (longlong)iVar2) >> 0x10 |
               (int)((ulonglong)((longlong)param_2 * (longlong)iVar2) >> 0x20) << 0x10;
  return param_1;
}


