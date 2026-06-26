// FUN_005aafd0  entry=005aafd0  size=1485 bytes

uint __thiscall FUN_005aafd0(int param_1,char param_2)

{
  short sVar1;
  bool bVar2;
  undefined4 uVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  int iVar7;
  uint uVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  int *piVar12;
  int iVar13;
  int local_24;
  int local_18;
  int local_14;
  int local_10;
  undefined1 local_c [12];
  
  iVar7 = *(int *)(param_1 + 400);
  if ((*(int *)(iVar7 + 0x54) == *(int *)(param_1 + 0x2b8)) ||
     (iVar4 = *(int *)(iVar7 + 0x40), iVar4 == 0)) {
LAB_005ab09a:
    bVar2 = false;
    piVar12 = (int *)(iVar7 + 0x174);
  }
  else {
    if (*(int *)(iVar4 + 700) == 0) {
LAB_005ab069:
      bVar2 = false;
    }
    else {
      iVar4 = *(int *)(iVar4 + 0x40);
      if ((iVar4 == 8) || (iVar4 == 9)) {
        bVar2 = true;
      }
      else {
        bVar2 = false;
      }
      if (bVar2) goto LAB_005ab069;
      if ((iVar4 == 6) || (iVar4 == 7)) {
        bVar2 = true;
      }
      else {
        bVar2 = false;
      }
      if (bVar2) goto LAB_005ab069;
      if ((iVar4 == 0x15) || (iVar4 == 0x14)) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if (!bVar2) goto LAB_005ab069;
      bVar2 = true;
    }
    if (!bVar2) goto LAB_005ab09a;
    bVar2 = true;
    uVar3 = FUN_005b1230(local_c,0x18);
    FUN_005a1700(&local_18,uVar3);
    piVar12 = &local_18;
  }
  local_14 = piVar12[1] - *(int *)(param_1 + 8);
  local_18 = *piVar12 - *(int *)(param_1 + 4);
  local_10 = piVar12[2] - *(int *)(param_1 + 0xc);
  iVar4 = FUN_005ee080(local_18,local_14);
  sVar1 = *(short *)(param_1 + 0x34);
  iVar5 = ftol();
  iVar7 = *(int *)(*(int *)(param_1 + 0x184) + 0x31c);
  if (iVar7 == 0) {
    iVar13 = *(int *)(param_1 + 900) << 1;
    iVar7 = iVar13 / 3;
    uVar6 = -(iVar13 >> 0x1f);
  }
  else if (iVar7 == 1) {
    iVar7 = *(int *)(param_1 + 900);
    uVar6 = 0;
  }
  else {
    iVar7 = *(int *)(param_1 + 900) + 100;
    uVar6 = iVar7 - (iVar7 >> 0x1f);
    iVar7 = iVar7 / 2;
  }
  iVar13 = *(int *)(param_1 + 400);
  if (((0x3332 < *(int *)(iVar13 + 0xc)) ||
      (((uVar6 = *(uint *)(iVar13 + 0x40), uVar6 != 0 && (*(int *)(uVar6 + 700) == 0)) ||
       (*(int *)(iVar13 + 0x4c) == param_1)))) ||
     ((uVar8 = (uint)(short)((short)iVar4 - sVar1), uVar6 = (int)uVar8 >> 0x1f,
      uVar6 = (uVar8 ^ uVar6) - uVar6, 0x1554 < (int)uVar6 ||
      (uVar6 = (-(uint)(param_2 != '\0') & 0x20000) + 0x18000, (int)uVar6 <= iVar5)))) {
    return uVar6 & 0xffffff00;
  }
  iVar13 = (iVar7 * 0xd999) / 100;
  if (iVar13 < 0x8000) {
    iVar9 = FUN_005ec250();
    iVar13 = (int)(iVar9 * iVar13 + (iVar9 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf;
  }
  else {
    iVar9 = FUN_005ec250();
    iVar9 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar9;
    iVar13 = (int)(iVar9 + (iVar9 >> 0x1f & 0x7fU)) >> 7;
  }
  iVar13 = iVar13 + 0x18000;
  local_24 = iVar5;
  if (iVar13 < iVar5) {
    iVar9 = *(int *)(param_1 + 0x68);
    iVar11 = (iVar7 * iVar9) / 200;
    if (iVar11 < 0x8000) {
      iVar10 = FUN_005ec250();
      iVar11 = (int)(iVar10 * iVar11 + (iVar10 * iVar11 >> 0x1f & 0x7fffU)) >> 0xf;
    }
    else {
      iVar10 = FUN_005ec250();
      iVar10 = ((int)(iVar11 + (iVar11 >> 0x1f & 0xffU)) >> 8) * iVar10;
      iVar11 = (int)(iVar10 + (iVar10 >> 0x1f & 0x7fU)) >> 7;
    }
    iVar10 = iVar5;
    if ((iVar9 + iVar11) * 0x20 < iVar5) {
      iVar9 = *(int *)(param_1 + 0x68);
      iVar11 = (iVar7 * iVar9) / 200;
      if (iVar11 < 0x8000) {
        iVar10 = FUN_005ec250();
        iVar11 = (int)(iVar10 * iVar11 + (iVar10 * iVar11 >> 0x1f & 0x7fffU)) >> 0xf;
      }
      else {
        iVar10 = FUN_005ec250();
        iVar10 = ((int)(iVar11 + (iVar11 >> 0x1f & 0xffU)) >> 8) * iVar10;
        iVar11 = (int)(iVar10 + (iVar10 >> 0x1f & 0x7fU)) >> 7;
      }
      iVar10 = (iVar11 + iVar9) * 0x20;
    }
    local_24 = iVar13;
    if (iVar13 <= iVar10) {
      iVar13 = *(int *)(param_1 + 0x68);
      iVar9 = (iVar7 * iVar13) / 200;
      if (iVar9 < 0x8000) {
        iVar11 = FUN_005ec250();
        iVar9 = (int)(iVar11 * iVar9 + (iVar11 * iVar9 >> 0x1f & 0x7fffU)) >> 0xf;
      }
      else {
        iVar11 = FUN_005ec250();
        iVar11 = ((int)(iVar9 + (iVar9 >> 0x1f & 0xffU)) >> 8) * iVar11;
        iVar9 = (int)(iVar11 + (iVar11 >> 0x1f & 0x7fU)) >> 7;
      }
      local_24 = iVar5;
      if ((iVar13 + iVar9) * 0x20 < iVar5) {
        iVar5 = *(int *)(param_1 + 0x68);
        iVar13 = (iVar7 * iVar5) / 200;
        if (iVar13 < 0x8000) {
          iVar9 = FUN_005ec250();
          iVar13 = (int)(iVar9 * iVar13 + (iVar9 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf;
        }
        else {
          iVar9 = FUN_005ec250();
          iVar9 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar9;
          iVar13 = (int)(iVar9 + (iVar9 >> 0x1f & 0x7fU)) >> 7;
        }
        local_24 = (iVar13 + iVar5) * 0x20;
      }
    }
  }
  iVar13 = ((100 - *(int *)(param_1 + 0x390)) * (100 - iVar7) * 0xaab) / 10000;
  iVar5 = iVar13 * 2 + 1;
  if (iVar5 < 0x8000) {
    iVar9 = FUN_005ec250();
    iVar5 = (int)(iVar9 * iVar5 + (iVar9 * iVar5 >> 0x1f & 0x7fffU)) >> 0xf;
  }
  else {
    iVar9 = FUN_005ec250();
    iVar9 = ((int)(iVar5 + (iVar5 >> 0x1f & 0xffU)) >> 8) * iVar9;
    iVar5 = (int)(iVar9 + (iVar9 >> 0x1f & 0x7fU)) >> 7;
  }
  iVar4 = iVar4 + (iVar5 - iVar13);
  if (DAT_006d31c4 == '\0') {
    piVar12 = (int *)(*(int *)(param_1 + 0x3b8) + 0x90);
    *piVar12 = *piVar12 + 1;
  }
  if (0x28000 < local_24) {
    iVar5 = FUN_005ec250();
    uVar3 = 9;
    if ((int)(iVar5 * 1000 + (iVar5 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar7 * 7)
    goto LAB_005ab4c1;
  }
  uVar3 = 8;
LAB_005ab4c1:
  FUN_005a5430(uVar3);
  if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180a) != '\0') {
    FUN_00590f00();
  }
  piVar12 = (int *)FUN_005ee0f0((int)(local_24 + (local_24 >> 0x1f & 0x1fU)) >> 5,iVar4);
  *(int *)(param_1 + 0x20) = *piVar12;
  *(int *)(param_1 + 0x24) = piVar12[1];
  *(int *)(param_1 + 0x28) = piVar12[2];
  *(undefined4 *)(param_1 + 0x80) = 1;
  *(undefined4 *)(param_1 + 0x84) = 0x2c;
  *(short *)(param_1 + 0x66) = (short)iVar4;
  *(int *)(param_1 + 0x94) = *(int *)(param_1 + 4) + *(int *)(param_1 + 0x20) * 0x2c;
  *(int *)(param_1 + 0x98) = *(int *)(param_1 + 8) + *(int *)(param_1 + 0x24) * 0x2c;
  *(int *)(param_1 + 0x9c) = *(int *)(param_1 + 0xc) + *(int *)(param_1 + 0x28) * 0x2c;
  if (bVar2) {
    uVar3 = *(undefined4 *)(*(int *)(param_1 + 400) + 0x40);
  }
  else {
    uVar3 = 0;
  }
  *(undefined4 *)(param_1 + 0xac) = uVar3;
  *(undefined1 *)(param_1 + 0x60) = 0;
  *(undefined1 *)(param_1 + 0x62) = 0;
  return CONCAT31((int3)((uint)uVar3 >> 8),1);
}


