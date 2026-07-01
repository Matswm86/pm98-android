// FUN_005b59f0  entry=005b59f0  size=885 bytes

void __fastcall FUN_005b59f0(int param_1)

{
  undefined4 uVar1;
  bool bVar2;
  short sVar3;
  undefined2 uVar4;
  short sVar5;
  int iVar6;
  undefined4 uVar7;
  int *piVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  
  iVar9 = *(int *)(param_1 + 8);
  iVar6 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1618);
  iVar11 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1614) - *(int *)(param_1 + 4);
  iVar10 = iVar6 - iVar9;
  iVar9 = ((((iVar9 <= iVar6) - 1 & 0x80000) - 0x40000) + iVar6) - iVar9;
  sVar3 = FUN_005ee080(iVar11,iVar9);
  iVar6 = FUN_005edfb0(iVar11,*(undefined4 *)(&DAT_006d31c8 + (sVar3 + 8 >> 4 & 0xfffU) * 4),iVar9,
                       *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar3 >> 4 & 0xfffU) * 4));
  if (iVar6 < 0x80001) {
    sVar3 = FUN_005ee080(iVar11,iVar10);
    iVar9 = FUN_005edfb0(iVar11,*(undefined4 *)(&DAT_006d31c8 + (sVar3 + 8 >> 4 & 0xfffU) * 4),
                         iVar10,*(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar3 >> 4 & 0xfffU) * 4))
    ;
    if (iVar9 < 0x30000) {
      iVar9 = *(int *)(param_1 + 0x18c);
      if (((*(int *)(iVar9 + 0x1630) == 0) && (*(int *)(iVar9 + 0x1634) == 0)) &&
         (*(int *)(iVar9 + 0x1638) == 0)) {
        bVar2 = true;
      }
      else {
        bVar2 = false;
      }
      if (!bVar2) {
        sVar3 = FUN_005ee080(iVar11,iVar10);
        sVar5 = FUN_005ee080(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1630),
                             *(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1634));
        iVar9 = *(int *)(param_1 + 0x18c);
        if ((short)((sVar3 - sVar5) + -0x8000) < 1) {
          iVar6 = *(int *)(iVar9 + 0x1630);
          uVar7 = *(undefined4 *)(iVar9 + 0x1638);
          *(undefined4 *)(param_1 + 0x3c0) = *(undefined4 *)(iVar9 + 0x1634);
          *(int *)(param_1 + 0x3c4) = -iVar6;
        }
        else {
          uVar1 = *(undefined4 *)(iVar9 + 0x1630);
          uVar7 = *(undefined4 *)(iVar9 + 0x1638);
          *(int *)(param_1 + 0x3c0) = -*(int *)(iVar9 + 0x1634);
          *(undefined4 *)(param_1 + 0x3c4) = uVar1;
        }
        *(undefined4 *)(param_1 + 0x3c8) = uVar7;
      }
      *(int *)(param_1 + 0x3bc) = *(int *)(param_1 + 0x3bc) + 0x147;
    }
  }
  else {
    *(int *)(param_1 + 0x3c0) = iVar11;
    *(int *)(param_1 + 0x3c4) = iVar9;
    *(undefined4 *)(param_1 + 0x3c8) = 0;
    *(int *)(param_1 + 0x3bc) = *(int *)(param_1 + 0x3bc) + 0x147;
  }
  *(undefined4 *)(param_1 + 0x3c8) = 0;
  iVar9 = *(int *)(param_1 + 0x3bc) + -0xa3;
  *(int *)(param_1 + 0x3bc) = iVar9;
  if (iVar9 < 0) {
    *(undefined4 *)(param_1 + 0x3bc) = 0;
  }
  iVar9 = *(int *)(param_1 + 0x3bc);
  if (0x1bba < iVar9) {
    iVar9 = 0x1bbb;
  }
  *(int *)(param_1 + 0x3bc) = iVar9;
  if (((*(int *)(param_1 + 0x3c0) == 0) && (*(int *)(param_1 + 0x3c4) == 0)) &&
     (*(int *)(param_1 + 0x3c8) == 0)) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  if (!bVar2) {
    uVar7 = FUN_005ee080(*(undefined4 *)(param_1 + 0x3c0),*(undefined4 *)(param_1 + 0x3c4));
    piVar8 = (int *)FUN_005ee0f0(*(undefined4 *)(param_1 + 0x3bc),uVar7);
    *(int *)(param_1 + 4) = *(int *)(param_1 + 4) + *piVar8;
    *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + piVar8[1];
    *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + piVar8[2];
  }
  iVar9 = *(int *)(param_1 + 0x18c);
  iVar6 = *(int *)(iVar9 + 0x1820) + -0x58000;
  if (iVar6 < *(int *)(param_1 + 4)) {
    *(int *)(param_1 + 4) = iVar6;
    if ((*(short *)(param_1 + 0x34) < 0x1555) && (-0x1555 < *(short *)(param_1 + 0x34))) {
      *(undefined4 *)(param_1 + 0x3bc) = 0;
    }
  }
  iVar6 = 0x58000 - *(int *)(iVar9 + 0x1820);
  if (*(int *)(param_1 + 4) < iVar6) {
    *(int *)(param_1 + 4) = iVar6;
    if ((0x6aab < *(short *)(param_1 + 0x34)) && (*(short *)(param_1 + 0x34) < -0x6aab)) {
      *(undefined4 *)(param_1 + 0x3bc) = 0;
    }
  }
  iVar6 = *(int *)(iVar9 + 0x1824) + -0x58000;
  if (iVar6 < *(int *)(param_1 + 8)) {
    *(int *)(param_1 + 8) = iVar6;
    if ((0x2aab < *(short *)(param_1 + 0x34)) && (*(short *)(param_1 + 0x34) < 0x5555)) {
      *(undefined4 *)(param_1 + 0x3bc) = 0;
    }
  }
  iVar9 = 0x58000 - *(int *)(iVar9 + 0x1824);
  if (*(int *)(param_1 + 8) < iVar9) {
    *(int *)(param_1 + 8) = iVar9;
    if ((-0x5555 < *(short *)(param_1 + 0x34)) && (*(short *)(param_1 + 0x34) < -0x2aab)) {
      *(undefined4 *)(param_1 + 0x3bc) = 0;
    }
  }
  if (*(int *)(param_1 + 0x3bc) != 0) {
    iVar10 = *(int *)(param_1 + 0x3c4);
    iVar11 = *(int *)(param_1 + 0x3c0);
  }
  uVar4 = FUN_005ee080(iVar11,iVar10);
  *(undefined2 *)(param_1 + 0x34) = uVar4;
  iVar9 = *(int *)(param_1 + 0x3bc);
  if (iVar9 == 0) {
    uVar7 = 0x38;
  }
  else if (iVar9 < 0x93e) {
    uVar7 = 0x39;
  }
  else if (iVar9 < 0x127c) {
    uVar7 = 0x3a;
  }
  else {
    uVar7 = 0x3b;
  }
  FUN_005a5430(uVar7);
  FUN_005a50c0();
  return;
}


