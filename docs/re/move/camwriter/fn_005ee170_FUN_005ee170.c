// FUN_005ee170  entry=005ee170  size=78 bytes

void __thiscall FUN_005ee170(int *param_1,uint *param_2,int param_3)

{
  int iVar1;
  int iVar2;
  
  iVar1 = param_1[1];
  iVar2 = param_1[2];
  *param_2 = (uint)((longlong)*param_1 * (longlong)param_3) >> 0x10 |
             (int)((ulonglong)((longlong)*param_1 * (longlong)param_3) >> 0x20) << 0x10;
  param_2[1] = (uint)((longlong)iVar1 * (longlong)param_3) >> 0x10 |
               (int)((ulonglong)((longlong)iVar1 * (longlong)param_3) >> 0x20) << 0x10;
  param_2[2] = (uint)((longlong)iVar2 * (longlong)param_3) >> 0x10 |
               (int)((ulonglong)((longlong)iVar2 * (longlong)param_3) >> 0x20) << 0x10;
  return;
}


