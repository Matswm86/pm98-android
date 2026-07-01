// FUN_005ee5c0  entry=005ee5c0  size=163 bytes

void __thiscall FUN_005ee5c0(int *param_1,int *param_2,int *param_3)

{
  int iVar1;
  int iVar2;
  longlong lVar3;
  longlong lVar4;
  longlong lVar5;
  
  lVar3 = (longlong)param_1[1] * (longlong)param_3[3] + (longlong)*param_1 * (longlong)*param_3 +
          (longlong)param_1[2] * (longlong)param_3[6];
  lVar4 = (longlong)param_1[1] * (longlong)param_3[4] + (longlong)*param_1 * (longlong)param_3[1] +
          (longlong)param_1[2] * (longlong)param_3[7];
  iVar1 = param_3[10];
  lVar5 = (longlong)param_1[1] * (longlong)param_3[5] + (longlong)*param_1 * (longlong)param_3[2] +
          (longlong)param_1[2] * (longlong)param_3[8];
  iVar2 = param_3[0xb];
  *param_2 = ((uint)lVar3 >> 0x10 | (int)((ulonglong)lVar3 >> 0x20) << 0x10) + param_3[9];
  param_2[1] = ((uint)lVar4 >> 0x10 | (int)((ulonglong)lVar4 >> 0x20) << 0x10) + iVar1;
  param_2[2] = ((uint)lVar5 >> 0x10 | (int)((ulonglong)lVar5 >> 0x20) << 0x10) + iVar2;
  return;
}


