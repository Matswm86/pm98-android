// FUN_005ee800  entry=005ee800  size=488 bytes

void __thiscall FUN_005ee800(int *param_1,uint *param_2,int *param_3)

{
  longlong lVar1;
  int iVar2;
  uint *puVar3;
  uint local_38 [4];
  uint local_28;
  uint local_24;
  uint local_20;
  uint local_1c;
  uint local_18;
  int local_14;
  int local_10;
  int local_c;
  int *local_8;
  
  local_8 = param_1;
  lVar1 = (longlong)param_1[1] * (longlong)param_3[3] + (longlong)*param_1 * (longlong)*param_3 +
          (longlong)param_1[2] * (longlong)param_3[6];
  local_38[0] = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  lVar1 = (longlong)param_1[1] * (longlong)param_3[4] + (longlong)*param_1 * (longlong)param_3[1] +
          (longlong)param_1[2] * (longlong)param_3[7];
  local_38[1] = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  lVar1 = (longlong)param_1[1] * (longlong)param_3[5] + (longlong)*param_1 * (longlong)param_3[2] +
          (longlong)param_1[2] * (longlong)param_3[8];
  local_38[2] = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  lVar1 = (longlong)param_1[4] * (longlong)param_3[3] + (longlong)param_1[3] * (longlong)*param_3 +
          (longlong)param_1[5] * (longlong)param_3[6];
  local_38[3] = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  lVar1 = (longlong)param_1[4] * (longlong)param_3[4] + (longlong)param_1[3] * (longlong)param_3[1]
          + (longlong)param_1[5] * (longlong)param_3[7];
  local_28 = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  lVar1 = (longlong)param_1[4] * (longlong)param_3[5] + (longlong)param_1[3] * (longlong)param_3[2]
          + (longlong)param_1[5] * (longlong)param_3[8];
  local_24 = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  lVar1 = (longlong)param_1[7] * (longlong)param_3[3] + (longlong)param_1[6] * (longlong)*param_3 +
          (longlong)param_1[8] * (longlong)param_3[6];
  local_20 = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  lVar1 = (longlong)param_1[7] * (longlong)param_3[4] + (longlong)param_1[6] * (longlong)param_3[1]
          + (longlong)param_1[8] * (longlong)param_3[7];
  local_1c = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  lVar1 = (longlong)param_1[7] * (longlong)param_3[5] + (longlong)param_1[6] * (longlong)param_3[2]
          + (longlong)param_1[8] * (longlong)param_3[8];
  local_18 = (uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10;
  lVar1 = (longlong)param_1[10] * (longlong)param_3[3] + (longlong)param_1[9] * (longlong)*param_3 +
          (longlong)param_1[0xb] * (longlong)param_3[6];
  local_14 = ((uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10) + param_3[9];
  lVar1 = (longlong)param_1[10] * (longlong)param_3[4] + (longlong)param_1[9] * (longlong)param_3[1]
          + (longlong)param_1[0xb] * (longlong)param_3[7];
  local_10 = ((uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10) + param_3[10];
  lVar1 = (longlong)param_1[10] * (longlong)param_3[5] + (longlong)param_1[9] * (longlong)param_3[2]
          + (longlong)param_1[0xb] * (longlong)param_3[8];
  local_c = ((uint)lVar1 >> 0x10 | (int)((ulonglong)lVar1 >> 0x20) << 0x10) + param_3[0xb];
  puVar3 = local_38;
  for (iVar2 = 0xc; iVar2 != 0; iVar2 = iVar2 + -1) {
    *param_2 = *puVar3;
    puVar3 = puVar3 + 1;
    param_2 = param_2 + 1;
  }
  return;
}


