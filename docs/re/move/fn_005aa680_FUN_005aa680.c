// FUN_005aa680  entry=005aa680  size=489 bytes

int __fastcall FUN_005aa680(int param_1)

{
  int iVar1;
  short sVar2;
  int *piVar3;
  uint uVar4;
  int iVar5;
  int iVar6;
  uint uVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  int iVar13;
  int local_48;
  int local_30;
  int local_28 [10];
  
  piVar3 = (int *)FUN_005ee0f0(0xa0000,*(undefined2 *)(param_1 + 0x34));
  iVar6 = *piVar3;
  iVar12 = piVar3[1];
  iVar5 = *(int *)(param_1 + 8);
  iVar1 = *(int *)(param_1 + 4);
  local_28[0] = 0x1f40000;
  local_28[1] = 0x1f40000;
  local_28[2] = 0x1f40000;
  local_28[3] = 0x1f40000;
  local_28[4] = 0x1f40000;
  local_30 = (*(int **)(param_1 + 0x184))[1];
  iVar9 = **(int **)(param_1 + 0x184);
  local_48 = 0;
  local_28[5] = 0;
  local_28[6] = 0;
  local_28[7] = 0;
  local_28[8] = 0;
  local_28[9] = 0;
  while (local_30 != 0) {
    local_30 = local_30 + -1;
    if ((iVar9 != param_1) &&
       ((uVar4 = (uint)*(short *)(param_1 + 0xb8 +
                                 (*(int *)(iVar9 + 0x2b8) * 0xb + *(int *)(iVar9 + 0x2c4)) * 2),
        uVar7 = (int)uVar4 >> 0x1f, iVar10 = (uVar4 ^ uVar7) - uVar7, iVar10 < 0x18e4 ||
        (*(int *)(*(int *)(param_1 + 0x18c) + 0x44c) == 2)))) {
      iVar11 = *(int *)(iVar9 + 4) - (iVar1 + iVar6);
      iVar13 = *(int *)(iVar9 + 8) - (iVar12 + iVar5);
      sVar2 = FUN_005ee080(iVar11,iVar13);
      iVar11 = FUN_005edfb0(iVar11,*(undefined4 *)(&DAT_006d31c8 + (sVar2 + 8 >> 4 & 0xfffU) * 4),
                            iVar13,*(undefined4 *)
                                    (&DAT_006d31c8 + (0x3ff8 - sVar2 >> 4 & 0xfffU) * 4));
      iVar8 = 0x4fa;
      iVar13 = 0;
      do {
        if (((iVar10 < iVar8) || (*(int *)(*(int *)(param_1 + 0x18c) + 0x44c) == 2)) &&
           (iVar11 < *(int *)((int)local_28 + iVar13))) {
          *(int *)((int)local_28 + iVar13) = iVar11;
          *(int *)((int)local_28 + iVar13 + 0x14) = iVar9;
        }
        iVar8 = iVar8 + 0x4fa;
        iVar13 = iVar13 + 4;
      } while (iVar8 < 0x1ddc);
    }
    iVar9 = iVar9 + 0x3bc;
  }
  iVar12 = 0;
  iVar6 = 0;
  do {
    if (0x112ffff < iVar6) break;
    iVar5 = 0;
    if (-1 < iVar6) {
      do {
        if (local_28[iVar5] < iVar6 / 5) {
          local_48 = local_28[iVar5 + 5];
        }
        iVar5 = iVar5 + 1;
      } while (iVar5 <= iVar12);
    }
    iVar12 = iVar12 + 1;
    iVar6 = iVar6 + 0x370000;
  } while (local_48 == 0);
  if (local_48 == 0) {
    iVar6 = 0;
    piVar3 = local_28 + 5;
    do {
      if (4 < iVar6) {
        return local_48;
      }
      local_48 = *piVar3;
      iVar6 = iVar6 + 1;
      piVar3 = piVar3 + 1;
    } while (local_48 == 0);
  }
  return local_48;
}


