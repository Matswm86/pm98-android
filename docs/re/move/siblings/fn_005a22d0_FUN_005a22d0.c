// FUN_005a22d0  entry=005a22d0  size=474 bytes

void __fastcall FUN_005a22d0(int param_1)

{
  bool bVar1;
  short sVar2;
  undefined2 uVar3;
  int iVar4;
  uint uVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  bool bVar9;
  bool bVar10;
  
  if (*(int *)(param_1 + 0x3bc) == 1) {
    iVar8 = *(int *)(param_1 + 4);
    iVar4 = *(int *)(param_1 + 0x18c);
    bVar1 = iVar8 < 0x40000;
    iVar6 = *(int *)(iVar4 + 0x1820) + -0x40000;
    bVar10 = SBORROW4(iVar8,iVar6);
    iVar7 = iVar8 - iVar6;
    bVar9 = iVar8 == iVar6;
  }
  else {
    iVar4 = *(int *)(param_1 + 0x18c);
    iVar8 = *(int *)(param_1 + 4);
    bVar1 = iVar8 < 0x40000 - *(int *)(iVar4 + 0x1820);
    bVar10 = SBORROW4(iVar8,-0x40000);
    iVar7 = iVar8 + 0x40000;
    bVar9 = iVar8 == -0x40000;
  }
  iVar6 = *(int *)(iVar4 + 0x1618) - *(int *)(param_1 + 8);
  iVar8 = *(int *)(iVar4 + 0x1614) - iVar8;
  sVar2 = FUN_005ee080(iVar8,iVar6);
  iVar4 = FUN_005edfb0(iVar8,*(undefined4 *)(&DAT_006d31c8 + (sVar2 + 8 >> 4 & 0xfffU) * 4),iVar6,
                       *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar2 >> 4 & 0xfffU) * 4));
  iVar8 = *(int *)(param_1 + 0x18c);
  if (iVar4 < 0x30000) {
    if (*(int *)(param_1 + 4) < *(int *)(iVar8 + 0x1614)) {
LAB_005a23b1:
      if (bVar1) goto LAB_005a23db;
      iVar4 = *(int *)(param_1 + 0x3c0) + -0x28f;
    }
    else {
joined_r0x005a23c8:
      if (!bVar9 && bVar10 == iVar7 < 0) goto LAB_005a23db;
      iVar4 = *(int *)(param_1 + 0x3c0) + 0x28f;
    }
    *(int *)(param_1 + 0x3c0) = iVar4;
  }
  else {
    uVar5 = *(int *)(iVar8 + 0x1614) - *(int *)(param_1 + 4);
    if (0x40000 < (int)((uVar5 ^ (int)uVar5 >> 0x1f) - ((int)uVar5 >> 0x1f))) {
      if ((int)uVar5 < 0) goto LAB_005a23b1;
      goto joined_r0x005a23c8;
    }
  }
LAB_005a23db:
  iVar4 = *(int *)(param_1 + 0x3c0);
  if (iVar4 < 1) {
    *(int *)(param_1 + 0x3c0) = iVar4 + 0xa3;
    if (iVar4 + 0xa3 < 1) goto LAB_005a240d;
  }
  else {
    *(int *)(param_1 + 0x3c0) = iVar4 + -0xa3;
    if (-1 < iVar4 + -0xa3) goto LAB_005a240d;
  }
  *(undefined4 *)(param_1 + 0x3c0) = 0;
LAB_005a240d:
  iVar4 = *(int *)(param_1 + 0x3c0);
  if (0x1554 < iVar4) {
    iVar4 = 0x1555;
  }
  *(int *)(param_1 + 0x3c0) = iVar4;
  if (iVar4 < -0x1554) {
    iVar4 = -0x1555;
  }
  *(int *)(param_1 + 0x3c0) = iVar4;
  iVar7 = *(int *)(param_1 + 4) + iVar4;
  *(int *)(param_1 + 4) = iVar7;
  if (iVar4 == 0) {
    uVar3 = FUN_005ee080(*(int *)(iVar8 + 0x1614) - iVar7,
                         *(int *)(iVar8 + 0x1618) - *(int *)(param_1 + 8));
    *(undefined2 *)(param_1 + 0x34) = uVar3;
  }
  else if (iVar4 < 0) {
    *(undefined2 *)(param_1 + 0x34) = 0x8000;
  }
  else {
    *(undefined2 *)(param_1 + 0x34) = 0;
  }
  if (*(int *)(param_1 + 0x3c0) != 0) {
    FUN_005a5430(0x43);
    FUN_005a50c0();
    return;
  }
  FUN_005a5430(0x42);
  FUN_005a50c0();
  return;
}


