// FUN_005ac1a0  entry=005ac1a0  size=2713 bytes

void __fastcall FUN_005ac1a0(int param_1)

{
  uint *puVar1;
  bool bVar2;
  byte bVar3;
  char cVar4;
  char cVar5;
  short sVar6;
  int iVar7;
  int iVar8;
  undefined4 uVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  int iVar13;
  int iVar14;
  undefined4 uVar15;
  int iVar16;
  int *piVar17;
  undefined4 *puVar18;
  uint uVar19;
  uint uVar20;
  int iVar21;
  short sVar22;
  short sVar23;
  bool bVar24;
  short local_28;
  int local_24;
  int local_20;
  
  if ((param_1 != *(int *)(*(int *)(param_1 + 400) + 0x40)) &&
     (cVar4 = FUN_0058f100(), cVar4 != '\0')) goto LAB_005acc29;
  iVar13 = *(int *)(param_1 + 0xa0);
  puVar1 = (uint *)(param_1 + 0xa0);
  iVar14 = *(int *)(*(int *)(param_1 + 400) + 4);
  iVar11 = *(int *)(*(int *)(param_1 + 400) + 8);
  iVar12 = *(int *)(param_1 + 0xa4);
  if (*(int *)(*(int *)(param_1 + 0x18c) + 0x44c) == 4) {
LAB_005ac2b0:
    local_20 = 0x500000;
  }
  else {
    cVar4 = FUN_00590c10(*(int *)(param_1 + 0x18c) + 0x1828);
    if (((cVar4 == '\0') ||
        (uVar19 = (int)*puVar1 >> 0x1f,
        (int)((*puVar1 ^ uVar19) - uVar19) <=
        *(int *)(*(int *)(param_1 + 0x18c) + 0x1820) + -0x108000)) ||
       (uVar19 = (int)*(uint *)(param_1 + 0xa4) >> 0x1f,
       0x1428f4 < (int)((*(uint *)(param_1 + 0xa4) ^ uVar19) - uVar19))) {
      bVar24 = false;
    }
    else {
      bVar24 = true;
    }
    if ((bVar24) &&
       (((-1 < (int)*puVar1) - 1 & 0xfffffffe) + 1 !=
        ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
      bVar24 = true;
    }
    else {
      bVar24 = false;
    }
    if (bVar24) goto LAB_005ac2b0;
    if ((*(int *)(param_1 + 0x40) == 0x13) || (*(int *)(param_1 + 0x40) == 0x37)) {
      local_20 = 0x140000;
    }
    else {
      local_20 = 0x260000;
    }
  }
  bVar24 = *(int *)(*(int *)(param_1 + 400) + 0x4c) == 0;
  cVar4 = FUN_00590c10(*(int *)(param_1 + 0x18c) + 0x1828);
  if (((cVar4 == '\0') ||
      (uVar19 = (int)*puVar1 >> 0x1f,
      (int)((*puVar1 ^ uVar19) - uVar19) <= *(int *)(*(int *)(param_1 + 0x18c) + 0x1820) + -0x108000
      )) || (uVar19 = (int)*(uint *)(param_1 + 0xa4) >> 0x1f,
            0x1428f4 < (int)((*(uint *)(param_1 + 0xa4) ^ uVar19) - uVar19))) {
    bVar2 = false;
  }
  else {
    bVar2 = true;
  }
  if ((!bVar2) ||
     (bVar3 = 1,
     ((-1 < (int)*puVar1) - 1 & 0xfffffffe) + 1 ==
     ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
    bVar3 = 0;
  }
  if (bVar24) {
    iVar21 = *(int *)(param_1 + 0x3a0);
  }
  else {
    iVar21 = *(int *)(param_1 + 0x394);
  }
  iVar21 = 100 - iVar21;
  if (*(int *)(*(int *)(param_1 + 0x18c) + 0x44c) == 6) {
    iVar21 = iVar21 / 3;
  }
  iVar8 = *(int *)(*(int *)(param_1 + 400) + 0x4c);
  if (iVar8 == 0) {
    iVar10 = *(int *)(param_1 + 0x54);
  }
  else {
    iVar10 = *(int *)(param_1 + 0x58);
  }
  if (iVar10 < 4) {
    local_24 = 4;
  }
  else if (iVar8 == 0) {
    local_24 = *(int *)(param_1 + 0x54);
  }
  else {
    local_24 = *(int *)(param_1 + 0x58);
  }
  iVar10 = (int)(((-(uint)bVar24 & 0x3333) + 0x6666) * iVar21) / 100;
  iVar8 = iVar10 * 2 + 1;
  if (iVar8 < 0x8000) {
    iVar7 = FUN_005ec250();
    iVar8 = (int)(iVar7 * iVar8 + (iVar7 * iVar8 >> 0x1f & 0x7fffU)) >> 0xf;
  }
  else {
    iVar7 = FUN_005ec250();
    iVar7 = ((int)(iVar8 + (iVar8 >> 0x1f & 0xffU)) >> 8) * iVar7;
    iVar8 = (int)(iVar7 + (iVar7 >> 0x1f & 0x7fU)) >> 7;
  }
  uVar9 = ftol((iVar8 - iVar10) + 0x10000);
  iVar8 = FUN_005edfa0(uVar9);
  cVar4 = *(char *)(param_1 + 0x5e);
  if (cVar4 == '\0') {
    iVar10 = FUN_005ec250();
    bVar2 = true;
    if (((int)(iVar10 * 0x500 + (iVar10 * 0x500 >> 0x1f & 0x7fU)) >> 7) + 0xf0000 <= iVar8)
    goto LAB_005ac49d;
  }
  else {
LAB_005ac49d:
    bVar2 = false;
  }
  if ((cVar4 == '\0') || ((!bVar24 && (local_20 <= iVar8)))) {
    iVar10 = iVar8;
    if (!bVar2) {
      iVar10 = (0x10 - local_24) * 0x3851;
      iVar10 = FUN_005edf90(iVar8,((int)(iVar10 + (iVar10 >> 0x1f & 0xfU)) >> 4) + 0x175c2);
    }
  }
  else {
    uVar19 = -(uint)bVar3 & 0x20000;
    if (uVar19 < 0x8000) {
      iVar10 = FUN_005ec250();
      iVar10 = iVar8 + ((int)(iVar10 * uVar19 + ((int)(iVar10 * uVar19) >> 0x1f & 0x7fffU)) >> 0xf);
    }
    else {
      iVar10 = FUN_005ec250();
      iVar10 = ((int)uVar19 >> 8) * iVar10;
      iVar10 = iVar8 + ((int)(iVar10 + (iVar10 >> 0x1f & 0x7fU)) >> 7);
    }
  }
  local_24 = iVar10;
  iVar11 = FUN_005ee080(iVar13 - iVar14,iVar12 - iVar11);
  iVar14 = ((short)((-(ushort)bVar24 & 0x160c) + 0x2d8) * iVar21) / 100;
  iVar13 = iVar14 * 2 + 1;
  if (iVar13 < 0x8000) {
    iVar12 = FUN_005ec250();
    local_20 = (int)(iVar12 * iVar13 + (iVar12 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf;
  }
  else {
    iVar12 = FUN_005ec250();
    iVar12 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar12;
    local_20 = (int)(iVar12 + (iVar12 >> 0x1f & 0x7fU)) >> 7;
  }
  local_20 = (iVar11 - iVar14) + local_20;
  if (cVar4 == '\0') {
    if (bVar2) {
      local_28 = 0x271c;
    }
    else {
      if (bVar24) {
        sVar23 = 0;
      }
      else {
        iVar13 = MulDiv(iVar8 + -0xb0000,0x5b0,0x500000);
        sVar23 = (short)iVar13;
      }
      iVar14 = (iVar21 * 0x4fa) / 100;
      iVar13 = iVar14 * 2 + 1;
      if (iVar13 < 0x8000) {
        iVar11 = FUN_005ec250();
        sVar22 = (short)((int)(iVar11 * iVar13 + (iVar11 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf);
      }
      else {
        iVar11 = FUN_005ec250();
        iVar11 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar11;
        sVar22 = (short)((int)(iVar11 + (iVar11 >> 0x1f & 0x7fU)) >> 7);
      }
      sVar6 = FUN_005ee080(iVar8,*(int *)(param_1 + 0xa8) - *(int *)(*(int *)(param_1 + 400) + 0xc))
      ;
      local_28 = sVar6 + 0x71c + sVar22 + (sVar23 - (short)iVar14);
    }
  }
  else {
    if (bVar24) {
      iVar13 = *(int *)(param_1 + 0x58);
      if (iVar13 < 2) {
        iVar13 = 2;
      }
      sVar23 = ((short)iVar13 + 1) * 0x16c;
    }
    else {
      sVar23 = 0x1e94;
    }
    iVar14 = (int)(((-(uint)bVar24 & 0x889) + 0x5b0) * iVar21) / 100;
    iVar13 = iVar14 * 2 + 1;
    if (iVar13 < 0x8000) {
      iVar11 = FUN_005ec250();
      sVar22 = (short)((int)(iVar11 * iVar13 + (iVar11 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf);
    }
    else {
      iVar11 = FUN_005ec250();
      iVar11 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar11;
      sVar22 = (short)((int)(iVar11 + (iVar11 >> 0x1f & 0x7fU)) >> 7);
    }
    iVar13 = MulDiv(iVar8,(int)(short)((-(ushort)bVar24 & 0xf555) + 0xe39),0x500000);
    local_28 = ((sVar23 - (short)iVar14) + sVar22) - (short)iVar13;
  }
  if (bVar24) {
    iVar13 = FUN_005ec250();
    if ((int)(iVar13 * 1000 + (iVar13 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar21 * 6) {
      iVar13 = (iVar21 * 0x11c7) / 100 + 0x71c;
      if (iVar13 < 0x8000) {
        iVar14 = FUN_005ec250();
        sVar23 = (short)((int)(iVar14 * iVar13 + (iVar14 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf);
      }
      else {
        iVar14 = FUN_005ec250();
        iVar14 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar14;
        sVar23 = (short)((int)(iVar14 + (iVar14 >> 0x1f & 0x7fU)) >> 7);
      }
      local_28 = local_28 + sVar23;
    }
    iVar13 = FUN_005ec250();
    if ((int)(iVar13 * 1000 + (iVar13 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar21 * 6) {
      iVar14 = (iVar21 * 0x11c7) / 100 + 0xaab;
      iVar13 = iVar14 * 2 + 1;
      if (iVar13 < 0x8000) {
        iVar11 = FUN_005ec250();
        iVar13 = (int)(iVar11 * iVar13 + (iVar11 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf;
      }
      else {
        iVar11 = FUN_005ec250();
        iVar11 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar11;
        iVar13 = (int)(iVar11 + (iVar11 >> 0x1f & 0x7fU)) >> 7;
      }
      local_20 = local_20 + (iVar13 - iVar14);
    }
    if (local_28 < 0x16d) {
      local_28 = 0x16c;
    }
    if (local_24 < 0xf0000) {
      if (0x1dde < local_28) {
        local_28 = 0x1dde;
      }
    }
    else if (local_24 < 0x140000) {
      if (0x216c < local_28) {
        local_28 = 0x216c;
      }
    }
    else if (0x238e < local_28) {
      local_28 = 0x238e;
    }
  }
  if (*(int *)(param_1 + 700) == 0) {
    cVar5 = FUN_00590c10(*(int *)(param_1 + 0x18c) + 0x1828);
    if (((cVar5 == '\0') ||
        (uVar19 = *(uint *)(param_1 + 4), uVar20 = (int)uVar19 >> 0x1f,
        (int)((uVar19 ^ uVar20) - uVar20) <=
        *(int *)(*(int *)(param_1 + 0x18c) + 0x1820) + -0x108000)) ||
       (uVar19 = (int)*(uint *)(param_1 + 8) >> 0x1f,
       0x1428f4 < (int)((*(uint *)(param_1 + 8) ^ uVar19) - uVar19))) {
      bVar24 = false;
    }
    else {
      bVar24 = true;
    }
    if ((bVar24) &&
       (((-1 < (int)*(uint *)(param_1 + 4)) - 1 & 0xfffffffe) + 1 ==
        ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
      bVar24 = true;
    }
    else {
      bVar24 = false;
    }
    if (((bVar24) && (cVar4 != '\0')) && (*(int *)(param_1 + 0x40) != 0x37)) {
      iVar13 = FUN_005ec250();
      local_28 = local_28 + 0x222 +
                 (short)((int)(iVar13 * 0x38e + (iVar13 * 0x38e >> 0x1f & 0x7fffU)) >> 0xf);
    }
  }
  uVar9 = *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - local_28 >> 4 & 0xfffU) * 4);
  iVar14 = *(int *)(&DAT_006d31c8 + (local_28 + 8 >> 4 & 0xfffU) * 4);
  uVar15 = FUN_005edfb0(*(int *)(*(int *)(param_1 + 400) + 0xc) - *(int *)(param_1 + 0xa8),iVar14,
                        local_24,uVar9);
  FUN_005edfa0(iVar14 * 2,uVar15);
  FUN_005edfd0(local_24,local_24,0xb2);
  iVar16 = ftol();
  iVar13 = *(int *)(param_1 + 400);
  iVar11 = local_20;
  iVar12 = FUN_005ec250(local_20);
  piVar17 = (int *)FUN_005ee0f0(((int)(iVar12 * 0xb3 + (iVar12 * 0xb3 >> 0x1f & 0x7fU)) >> 7) +
                                -0x5999 + iVar8,iVar11);
  iVar11 = *(int *)(iVar13 + 8);
  iVar12 = *(int *)(iVar13 + 0xc);
  iVar8 = piVar17[1];
  iVar10 = piVar17[2];
  iVar7 = *(int *)(param_1 + 400);
  *(int *)(iVar7 + 0x84) = *piVar17 + *(int *)(iVar13 + 4);
  *(int *)(iVar7 + 0x88) = iVar11 + iVar8;
  *(int *)(iVar7 + 0x8c) = iVar12 + iVar10;
  iVar11 = MulDiv(0x9999,*(int *)(param_1 + 0x70),15000);
  iVar13 = MulDiv(0x9999,100 - iVar21,100);
  iVar13 = iVar11 + 0x13332 + iVar13;
  if ((int)(iVar13 + (iVar13 >> 0x1f & 3U)) >> 2 <= iVar16) {
    iVar11 = MulDiv(0x9999,*(int *)(param_1 + 0x70),15000);
    iVar13 = MulDiv(0x9999,100 - iVar21,100);
    iVar13 = iVar11 + 0x13332 + iVar13;
    iVar16 = (int)(iVar13 + (iVar13 >> 0x1f & 3U)) >> 2;
  }
  if (bVar2) {
    uVar9 = FUN_005edfa0(iVar14,iVar16 * 2);
    puVar18 = (undefined4 *)FUN_005ee0f0(uVar9,local_20);
    iVar13 = *(int *)(param_1 + 400);
    *(undefined4 *)(iVar13 + 0x20) = *puVar18;
    *(undefined4 *)(iVar13 + 0x24) = puVar18[1];
    *(undefined4 *)(iVar13 + 0x28) = puVar18[2];
  }
  else {
    uVar15 = FUN_005edfa0(iVar14,iVar16,local_20);
    puVar18 = (undefined4 *)FUN_005ee0f0(uVar15,local_20);
    iVar13 = *(int *)(param_1 + 400);
    *(undefined4 *)(iVar13 + 0x20) = *puVar18;
    *(undefined4 *)(iVar13 + 0x24) = puVar18[1];
    *(undefined4 *)(iVar13 + 0x28) = puVar18[2];
    uVar9 = FUN_005edfa0(uVar9,iVar16);
    *(undefined4 *)(*(int *)(param_1 + 400) + 0x28) = uVar9;
  }
  FUN_005ab5a0();
  iVar13 = *(int *)(*(int *)(param_1 + 400) + 0x70);
  if (iVar13 < 5) {
    iVar13 = 4;
  }
  *(int *)(*(int *)(param_1 + 400) + 0x70) = iVar13;
LAB_005acc29:
  *(undefined4 *)(param_1 + 0x54) = 0;
  *(undefined4 *)(param_1 + 0x58) = 0;
  return;
}


