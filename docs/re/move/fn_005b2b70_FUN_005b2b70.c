// FUN_005b2b70  entry=005b2b70  size=955 bytes

undefined4 __fastcall FUN_005b2b70(int param_1)

{
  bool bVar1;
  int iVar2;
  uint uVar3;
  int *piVar4;
  int iVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  bool local_19;
  undefined4 local_18;
  int local_14;
  
  iVar10 = 2;
  local_19 = *(int *)(param_1 + 0x13c) == 2;
  iVar2 = 0;
  if (local_19) goto LAB_005b2e50;
  iVar2 = *(int *)(param_1 + 0x2c8);
  if (iVar2 == 9) {
LAB_005b2bc0:
    iVar10 = 1;
  }
  else {
    if ((iVar2 == 0xc) || (iVar2 == 0xe)) {
      bVar1 = true;
    }
    else {
      bVar1 = false;
    }
    if (bVar1) goto LAB_005b2bc0;
  }
  iVar7 = *(int *)(param_1 + 0x3a4);
  iVar8 = *(int *)(param_1 + 4);
  iVar9 = *(int *)(param_1 + 0x14c);
  iVar2 = FUN_005ec250();
  iVar2 = (int)(iVar2 * 1000 + (iVar2 * 1000 >> 0x1f & 0x7fffU)) >> 0xf;
  if (iVar2 < (int)(((-(uint)(((-1 < iVar8) - 1 & 0xfffffffe) + 1 !=
                             ((-1 < iVar7) - 1 & 0xfffffffe) + 1) & 0xfa) + 0x2ee) - iVar9 / 2) /
              iVar10) {
    iVar10 = 0;
    iVar7 = 0x3e80000;
    iVar2 = **(int **)(param_1 + 0x188);
    iVar8 = (*(int **)(param_1 + 0x188))[1];
    while (local_14 = iVar8 + -1, iVar8 != 0) {
      iVar8 = *(int *)(iVar2 + 0x2c4) + *(int *)(iVar2 + 0x2b8) * 0xb;
      uVar3 = (uint)*(short *)(param_1 + 0xb8 + iVar8 * 2);
      uVar6 = (int)uVar3 >> 0x1f;
      if ((int)((uVar3 ^ uVar6) - uVar6) < 0x2000) {
        if (iVar2 == 0) {
          iVar8 = 0xc80000;
        }
        else {
          iVar8 = *(int *)(param_1 + 0xe4 + iVar8 * 4);
        }
        if (iVar8 < iVar7) {
          iVar7 = iVar8;
          iVar10 = iVar2;
        }
      }
      iVar2 = iVar2 + 0x3bc;
      iVar8 = local_14;
    }
    iVar2 = -1;
    if (((iVar10 != 0) &&
        (iVar2 = *(int *)(iVar10 + 0x2c4) + *(int *)(iVar10 + 0x2b8) * 0xb,
        *(int *)(param_1 + 0xe4 + iVar2 * 4) < 0x4c000)) &&
       (uVar3 = (uint)*(short *)(param_1 + 0xb8 + iVar2 * 2), uVar6 = (int)uVar3 >> 0x1f,
       iVar2 = (uVar3 ^ uVar6) - uVar6, iVar2 < 0x2000)) {
      iVar7 = *(int *)(param_1 + 0x37c);
      iVar8 = *(int *)(iVar10 + 0x37c);
      iVar2 = FUN_005ec250();
      iVar2 = (int)(iVar2 * 1000 + (iVar2 * 1000 >> 0x1f & 0x7fffU)) >> 0xf;
      if (iVar2 < (int)(((iVar7 <= iVar8) - 1 & 400) + 400)) {
        local_19 = true;
        *(undefined4 *)(param_1 + 0x144) = 0;
        iVar2 = FUN_005ec250();
        *(undefined4 *)(param_1 + 0x13c) = 2;
        *(int *)(param_1 + 0x148) =
             ((int)(iVar2 * 0x32 + (iVar2 * 0x32 >> 0x1f & 0x7fffU)) >> 0xf) + 0x3c;
        FUN_00590aa0(*(int *)(iVar10 + 4) - *(int *)(param_1 + 4),
                     *(int *)(iVar10 + 8) - *(int *)(param_1 + 8),
                     *(int *)(iVar10 + 0xc) - *(int *)(param_1 + 0xc));
        iVar2 = FUN_005ee080(local_18,local_14);
        iVar10 = FUN_005ec250();
        iVar7 = FUN_005ec250();
        piVar4 = (int *)FUN_005ee0f0(0x140000,((-(uint)((int)(iVar7 * 1000 +
                                                             (iVar7 * 1000 >> 0x1f & 0x7fffU)) >>
                                                        0xf < 500) & 0x471c) - 0x2e39) +
                                              iVar2 + ((int)(iVar10 * 0x1557 +
                                                            (iVar10 * 0x1557 >> 0x1f & 0x7fffU)) >>
                                                      0xf));
        iVar10 = piVar4[1];
        iVar2 = piVar4[2] + *(int *)(param_1 + 0xc);
        *(int *)(param_1 + 0x158) = *(int *)(param_1 + 4) + *piVar4;
        *(int *)(param_1 + 0x15c) = iVar10 + *(int *)(param_1 + 8);
        *(int *)(param_1 + 0x160) = iVar2;
        goto LAB_005b2e50;
      }
    }
    local_19 = false;
  }
LAB_005b2e50:
  iVar2 = CONCAT31((int3)((uint)iVar2 >> 8),local_19);
  if (local_19 != false) {
    iVar2 = *(int *)(param_1 + 0x218);
    iVar10 = *(int *)(param_1 + 0x160);
    iVar7 = iVar2;
    if (iVar2 <= iVar10) {
      iVar7 = iVar10;
    }
    iVar8 = *(int *)(param_1 + 0x224);
    if ((iVar7 <= iVar8) && (iVar8 = iVar2, iVar2 <= iVar10)) {
      iVar8 = iVar10;
    }
    iVar2 = *(int *)(param_1 + 0x214);
    iVar10 = *(int *)(param_1 + 0x15c);
    iVar7 = iVar2;
    if (iVar2 <= iVar10) {
      iVar7 = iVar10;
    }
    iVar9 = *(int *)(param_1 + 0x220);
    if ((iVar7 <= iVar9) && (iVar9 = iVar2, iVar2 <= iVar10)) {
      iVar9 = iVar10;
    }
    iVar2 = *(int *)(param_1 + 0x210);
    iVar10 = *(int *)(param_1 + 0x158);
    iVar7 = iVar2;
    if (iVar2 <= iVar10) {
      iVar7 = iVar10;
    }
    iVar5 = *(int *)(param_1 + 0x21c);
    if ((iVar7 <= iVar5) && (iVar5 = iVar10, iVar10 < iVar2)) {
      iVar5 = iVar2;
    }
    FUN_00590aa0(iVar5,iVar9,iVar8);
    FUN_005a89c0(&local_18,0x5a);
    iVar2 = *(int *)(param_1 + 0x144);
    *(int *)(param_1 + 0x144) = iVar2 + 1;
    if (iVar2 == *(int *)(param_1 + 0x148)) {
      *(undefined4 *)(param_1 + 0x13c) = 0;
    }
  }
  return CONCAT31((int3)((uint)iVar2 >> 8),local_19);
}


