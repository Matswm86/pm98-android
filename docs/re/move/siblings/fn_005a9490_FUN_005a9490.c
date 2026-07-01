// FUN_005a9490  entry=005a9490  size=4062 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __fastcall FUN_005a9490(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  bool bVar5;
  bool bVar6;
  char cVar7;
  short sVar8;
  int *piVar9;
  int iVar10;
  undefined4 uVar11;
  undefined4 *puVar12;
  int *piVar13;
  uint *puVar14;
  undefined2 extraout_var;
  int iVar15;
  int iVar16;
  int iVar17;
  undefined2 extraout_var_00;
  undefined2 extraout_var_01;
  uint uVar18;
  undefined2 extraout_var_02;
  uint uVar19;
  uint uVar20;
  undefined2 extraout_var_03;
  undefined2 extraout_var_04;
  undefined2 uVar21;
  uint *puVar22;
  undefined4 uVar23;
  int local_104;
  int local_100;
  int local_fc;
  uint local_f8;
  int *local_f4;
  short *local_f0;
  int local_ec;
  int local_e8;
  undefined4 local_e4;
  undefined4 local_e0;
  undefined1 local_d8 [24];
  uint local_c0 [6];
  int local_a8;
  uint local_a4;
  int local_a0;
  
  iVar10 = *(int *)(param_1 + 400);
  iVar17 = *(int *)(iVar10 + 0x40);
  if (param_1 == iVar17) {
    local_fc = *(int *)(iVar10 + 0xc) - *(int *)(param_1 + 0xc);
    local_100 = *(int *)(iVar10 + 8) - *(int *)(param_1 + 8);
    local_104 = *(int *)(iVar10 + 4) - *(int *)(param_1 + 4);
    piVar9 = (int *)FUN_005ee670(CONCAT22((short)((uint)local_fc >> 0x10),
                                          -*(short *)(param_1 + 0x34)));
    uVar18 = (int)(*piVar9 - 0x4cccU) >> 0x1f;
    iVar10 = (*piVar9 - 0x4cccU ^ uVar18) - uVar18;
    if (0x10000 < iVar10) {
      if ((*(int *)(param_1 + 0x40) == 8) || (*(int *)(param_1 + 0x40) == 9)) {
        bVar5 = false;
      }
      else {
        bVar5 = true;
      }
      if ((bVar5) && (*(int *)(param_1 + 700) != 0)) {
        FUN_0058ed50(param_1);
        return;
      }
    }
    if (*(int *)(param_1 + 0x68) != 0) {
      return;
    }
    if (iVar10 < 0x6667) {
      return;
    }
    iVar10 = *(int *)(param_1 + 400);
    sVar8 = FUN_005ee080(*(undefined4 *)(iVar10 + 0x20),*(undefined4 *)(iVar10 + 0x24));
    FUN_00436fb0(*(undefined4 *)(&DAT_006d31c8 + (sVar8 + 8 >> 4 & 0xfffU) * 4),
                 *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar8 >> 4 & 0xfffU) * 4));
    iVar10 = FUN_005edfb0(*(undefined4 *)(iVar10 + 0x20),local_e4,*(undefined4 *)(iVar10 + 0x24),
                          local_e0);
    if (iVar10 < 0x8001) {
      FUN_005ee1c0(0xe666);
      uVar11 = FUN_005ee0f0(0x4ccc,CONCAT22(extraout_var_00,*(undefined2 *)(param_1 + 0x34)));
      FUN_005a1700(&local_e4,uVar11);
      uVar23 = 0x10;
      uVar11 = 1;
      FUN_00590ae0(local_d8,*(int *)(param_1 + 400) + 4);
      uVar11 = FUN_005ee290(uVar11,uVar23);
      FUN_005a1700(&local_104,uVar11);
      iVar10 = *(int *)(param_1 + 400);
      *(int *)(iVar10 + 4) = local_104;
      *(int *)(iVar10 + 8) = local_100;
      *(int *)(iVar10 + 0xc) = local_fc;
      return;
    }
    iVar10 = *(int *)(param_1 + 400);
    *(undefined4 *)(iVar10 + 0x20) = 0;
    *(undefined4 *)(iVar10 + 0x24) = 0;
    *(undefined4 *)(iVar10 + 0x28) = 0;
    uVar11 = FUN_005ee0f0(0x4ccc,CONCAT22(extraout_var_02,*(undefined2 *)(param_1 + 0x34)));
    FUN_005a1700(&local_104,uVar11);
    iVar10 = *(int *)(param_1 + 400);
    iVar17 = DAT_00664fe4 << 2;
    *(undefined4 *)(iVar10 + 0x68) = 1;
    *(int *)(iVar10 + 0x6c) = iVar17;
    *(int *)(iVar10 + 0x9c) = local_104;
    *(int *)(iVar10 + 0xa0) = local_100;
    *(int *)(iVar10 + 0xa4) = local_fc;
    if (*(int *)(param_1 + 700) == 0) {
      return;
    }
    FUN_005a5430(0xb);
    return;
  }
  if (((iVar17 != 0) && (*(int *)(iVar17 + 700) == 0)) && (cVar7 = FUN_005b0a60(), cVar7 != '\0')) {
    return;
  }
  iVar10 = *(int *)(param_1 + 400);
  piVar9 = (int *)(param_1 + 4);
  uVar18 = *(int *)(param_1 + 4) - *(int *)(iVar10 + 4);
  uVar19 = (int)uVar18 >> 0x1f;
  if ((((int)((uVar18 ^ uVar19) - uVar19) < 0x1e0000) &&
      (uVar18 = *(int *)(param_1 + 8) - *(int *)(iVar10 + 8), uVar19 = (int)uVar18 >> 0x1f,
      (int)((uVar18 ^ uVar19) - uVar19) < 0x1e0000)) &&
     (uVar18 = *(int *)(param_1 + 0xc) - *(int *)(iVar10 + 0xc), uVar19 = (int)uVar18 >> 0x1f,
     (int)((uVar18 ^ uVar19) - uVar19) < 0x1e0000)) {
    bVar5 = true;
  }
  else {
    bVar5 = false;
  }
  if (!bVar5) {
    return;
  }
  iVar10 = *(int *)(param_1 + 0x40);
  if ((iVar10 < 0) || (3 < iVar10)) {
    bVar5 = false;
  }
  else {
    bVar5 = true;
  }
  if (((!bVar5) && (iVar10 != 0xb)) && (iVar10 != 0x1c)) {
    return;
  }
  if ((DAT_00674430 & 1) == 0) {
    DAT_00674430 = DAT_00674430 | 1;
    DAT_006744a8 = 0x17fff;
    DAT_006744ac = 0;
    DAT_006744b0 = 0x1e147;
    DAT_006744b4 = 0x4ccc;
    _DAT_006744b8 = 0;
    _DAT_006744bc = 0x18000;
    _DAT_006744c0 = 0x9998;
    _DAT_006744c4 = 0;
    _DAT_006744c8 = 0xb333;
    _DAT_006744cc = 0x2b332;
    _DAT_006744d0 = 0;
    _DAT_006744d4 = 0xcccc;
    _DAT_006744d8 = 0x9998;
    _DAT_006744dc = 0;
    _DAT_006744e0 = 0;
    FUN_00605ff0(&DAT_005aa480);
  }
  if ((DAT_00674430 & 2) == 0) {
    DAT_00674430 = DAT_00674430 | 2;
    DAT_006742f0 = 0x11999;
    DAT_006742f4 = 0x8000;
    DAT_006742f8 = 0x5eb8;
    _DAT_006742fc = 0x8000;
    DAT_00674300 = 0x8000;
    _DAT_00674304 = 0x8000;
    _DAT_00674308 = 0x8000;
    _DAT_0067430c = 0x8000;
    _DAT_00674310 = 0x8000;
    _DAT_00674314 = 0x9999;
    _DAT_00674318 = 0x8000;
    _DAT_0067431c = 0x4000;
    _DAT_00674320 = 0xb333;
    _DAT_00674324 = 0x8000;
    _DAT_00674328 = 0x4ccc;
    FUN_00605ff0(&DAT_005aa470);
  }
  iVar10 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
  if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1)) {
    iVar10 = -iVar10;
  }
  FUN_00590aa0(iVar10,0,0);
  puVar12 = (undefined4 *)FUN_00590ae0(local_d8,piVar9);
  uVar11 = FUN_005ee080(*puVar12,puVar12[1]);
  sVar8 = (short)uVar11 - *(short *)(param_1 + 0x34);
  iVar10 = CONCAT22((short)((uint)uVar11 >> 0x10),sVar8);
  puVar12 = (undefined4 *)FUN_00590ae0(local_d8,piVar9);
  iVar17 = FUN_005ee080(*puVar12,puVar12[1]);
  iVar16 = CONCAT22(extraout_var_01,*(undefined2 *)(param_1 + 0x34));
  iVar17 = iVar17 - iVar16;
  local_e8 = iVar10 - iVar17;
  bVar5 = false;
  local_f8 = 0x10;
  local_ec = (int)(short)((short)iVar17 - sVar8) / 2 + iVar16 + iVar10;
  puVar22 = local_c0;
  do {
    piVar13 = (int *)((int)puVar22 + *(int *)(param_1 + 400) + (0x114 - (int)local_c0));
    local_fc = piVar13[2] - *(int *)(param_1 + 0xc);
    local_100 = piVar13[1] - *(int *)(param_1 + 8);
    local_104 = *piVar13 - *piVar9;
    puVar14 = (uint *)FUN_005ee670(CONCAT22((short)((uint)local_fc >> 0x10),
                                            -*(short *)(param_1 + 0x34)));
    *puVar22 = *puVar14;
    uVar18 = puVar14[2];
    puVar22[1] = puVar14[1];
    puVar22[2] = uVar18;
    local_f8 = local_f8 + -1;
    puVar22 = puVar22 + 3;
  } while (local_f8 != 0);
  iVar10 = 0;
  if (*(int *)(*(int *)(param_1 + 400) + 0x40) != 0) {
    return;
  }
  if (*(int *)(*(int *)(param_1 + 400) + 0x70) != 0) {
    return;
  }
  local_f8 = 0;
  if (((*(int *)(param_1 + 0x40) != 0xb) && (*(int *)(param_1 + 0x54) != 0)) &&
     (uVar18 = 0, *(int *)(param_1 + 700) != 0)) {
    local_f8 = 0;
    local_f4 = &DAT_006655c8;
    local_f0 = &DAT_00665600;
    do {
      if (0x3b < iVar10) break;
      local_e4 = CONCAT22((short)(uVar18 >> 0x10),*local_f0 + -0x8000);
      if ((&DAT_006655e0)[local_f8] == '\0') {
LAB_005a9a91:
        uVar18 = local_f8;
        iVar17 = *local_f4;
        uVar19 = local_c0[iVar17 * 3] - *(int *)((int)&DAT_006744a8 + iVar10);
        uVar20 = (int)uVar19 >> 0x1f;
        if ((((int)((uVar19 ^ uVar20) - uVar20) < *(int *)((int)&DAT_006742f0 + iVar10)) &&
            (uVar19 = local_c0[iVar17 * 3 + 1] - *(int *)((int)&DAT_006744ac + iVar10),
            uVar20 = (int)uVar19 >> 0x1f,
            (int)((uVar19 ^ uVar20) - uVar20) < *(int *)((int)&DAT_006742f4 + iVar10))) &&
           (uVar19 = local_c0[iVar17 * 3 + 2] - *(int *)((int)&DAT_006744b0 + iVar10),
           uVar20 = (int)uVar19 >> 0x1f,
           (int)((uVar19 ^ uVar20) - uVar20) < *(int *)((int)&DAT_006742f8 + iVar10))) {
          bVar6 = true;
        }
        else {
          bVar6 = false;
        }
        if (bVar6) {
          sVar8 = *local_f0;
          if ((((0 < sVar8) &&
               (uVar19 = (int)(short)local_e8 >> 0x1f,
               (int)(((int)(short)local_e8 ^ uVar19) - uVar19) < (int)sVar8)) ||
              ((sVar8 < 0 &&
               (uVar19 = (int)(short)local_e8 >> 0x1f,
               (int)(short)local_e4 < (int)(((int)(short)local_e8 ^ uVar19) - uVar19))))) ||
             (sVar8 == 0)) {
            local_fc = 0;
            local_104 = (*(int *)(&DAT_006655e8 + local_f8 * 4) -
                        *(int *)((int)&DAT_006744a8 + iVar10)) + local_c0[iVar17 * 3];
            local_100 = local_c0[iVar17 * 3 + 1] - *(int *)((int)&DAT_006744ac + iVar10);
            FUN_005ee670(CONCAT22((short)((uint)*(int *)((int)&DAT_006744ac + iVar10) >> 0x10),
                                  *(undefined2 *)(param_1 + 0x34)));
            if (*local_f0 < 0) {
              local_ec = CONCAT22(local_ec._2_2_,*(undefined2 *)(param_1 + 0x34));
            }
            iVar17 = *(int *)(&DAT_006655b0 + uVar18 * 4);
            if (iVar17 == 5) {
              uVar21 = *(undefined2 *)(param_1 + 0x34);
              *(undefined2 *)(param_1 + 0x34) = (undefined2)local_ec;
              *piVar9 = *piVar9 + local_104;
              *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + local_100;
              *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + local_fc;
              FUN_005aa870(1);
              *piVar9 = *piVar9 - local_104;
              *(int *)(param_1 + 8) = *(int *)(param_1 + 8) - local_100;
              *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) - local_fc;
              *(undefined2 *)(param_1 + 0x34) = uVar21;
            }
            else {
              if ((iVar17 == 0x19) && ((short)local_e8 < 0)) {
                iVar17 = 0x1a;
              }
              FUN_005a5430(iVar17);
            }
            bVar5 = true;
            iVar17 = *local_f4;
            *(undefined4 *)(param_1 + 0x80) = 1;
            *(int *)(param_1 + 0x84) = iVar17 << 2;
            *(int *)(param_1 + 0x94) = *piVar9 + local_104;
            *(undefined2 *)(param_1 + 0x66) = (undefined2)local_ec;
            iVar17 = *(int *)(param_1 + 400);
            *(int *)(param_1 + 0x98) = *(int *)(param_1 + 8) + local_100;
            *(int *)(param_1 + 0x9c) = *(int *)(param_1 + 0xc) + local_fc;
            *(undefined4 *)(param_1 + 0x7c) = *(undefined4 *)(iVar17 + 0x80);
            if ((*(int *)(iVar17 + 0x4c) == param_1) && (*(int *)(iVar17 + 0x44) != param_1)) {
              *(undefined4 *)(iVar17 + 0x4c) = 0;
              if ((DAT_006d31c4 == '\0') &&
                 (iVar17 = *(int *)(*(int *)(param_1 + 400) + 0x50), iVar17 != 0)) {
                iVar17 = *(int *)(iVar17 + 0x3b8);
                iVar16 = *(int *)(iVar17 + 0x88);
                if (iVar16 != 0) {
                  *(int *)(iVar17 + 0x88) = iVar16 + -1;
                  piVar13 = (int *)(*(int *)(*(int *)(*(int *)(param_1 + 400) + 0x50) + 0x3b8) +
                                   0x84);
                  *piVar13 = *piVar13 + 1;
                }
              }
              *(int *)(*(int *)(param_1 + 400) + 0x5c) = *local_f4 * 4 + 1;
            }
          }
        }
      }
      else {
        cVar7 = FUN_0058fb50(piVar9);
        if ((cVar7 == '\0') ||
           (((-1 < *piVar9) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
          bVar6 = false;
        }
        else {
          bVar6 = true;
        }
        if (bVar6) goto LAB_005a9a91;
      }
      local_f8 = local_f8 + 1;
      uVar18 = local_f8 & 0xffffff00;
      iVar10 = iVar10 + 0xc;
      local_f0 = local_f0 + 1;
      local_f4 = local_f4 + 1;
    } while (!bVar5);
  }
  iVar10 = *(int *)(param_1 + 400);
  sVar8 = FUN_005ee080(*(undefined4 *)(iVar10 + 0x20),*(undefined4 *)(iVar10 + 0x24));
  iVar17 = FUN_005edfb0(*(undefined4 *)(iVar10 + 0x20),
                        *(undefined4 *)(&DAT_006d31c8 + (sVar8 + 8 >> 4 & 0xfffU) * 4),
                        *(undefined4 *)(iVar10 + 0x24),
                        *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar8 >> 4 & 0xfffU) * 4));
  iVar10 = *(int *)(param_1 + 400);
  if ((int)(((-(uint)(*(int *)(iVar10 + 0x4c) != param_1) & 0xfffffffe) + 8) * 0x9999) / 10 < iVar17
     ) {
LAB_005aa274:
    if (((!bVar5) &&
        (((int)local_c0[2] < 0x1b333 &&
         (iVar17 = (local_c0[1] ^ (int)local_c0[1] >> 0x1f) - ((int)local_c0[1] >> 0x1f),
         iVar17 < 0x8001)))) &&
       (iVar16 = (local_c0[0] ^ (int)local_c0[0] >> 0x1f) - ((int)local_c0[0] >> 0x1f),
       iVar16 < 0x4ccd)) {
      if ((int)local_c0[2] < 0x16668) {
        if ((iVar17 < 0x5556) && (iVar16 < 0x3333)) {
          sVar8 = FUN_005ee080(*(undefined4 *)(iVar10 + 0x20),*(undefined4 *)(iVar10 + 0x24));
          iVar10 = FUN_005edfb0(*(undefined4 *)(iVar10 + 0x20),
                                *(undefined4 *)(&DAT_006d31c8 + (sVar8 + 8 >> 4 & 0xfffU) * 4),
                                *(undefined4 *)(iVar10 + 0x24),
                                *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar8 >> 4 & 0xfffU) * 4))
          ;
          if (iVar10 < 0x6b85) {
            cVar7 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180a);
          }
          else {
            cVar7 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180a);
          }
          if (cVar7 != '\0') {
            FUN_00590f00();
          }
          iVar10 = FUN_005ec250();
          FUN_005ee670(((int)(iVar10 * 0x1c72 + (iVar10 * 0x1c72 >> 0x1f & 0x7fffU)) >> 0xf) +
                       0x71c7);
          uVar11 = 0x6666;
        }
        else {
          if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180a) != '\0') {
            FUN_00590f00();
          }
          iVar10 = FUN_005ec250();
          FUN_005ee670(((int)(iVar10 * 0x1c72 + (iVar10 * 0x1c72 >> 0x1f & 0x7fffU)) >> 0xf) +
                       -0xe39);
          uVar11 = 0x8ccc;
        }
      }
      else {
        if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180a) != '\0') {
          FUN_00590f00();
        }
        iVar10 = FUN_005ec250();
        FUN_005ee7c0(((int)(iVar10 * 0x38e + (iVar10 * 0x38e >> 0x1f & 0x7fffU)) >> 0xf) + 0x222);
        uVar11 = 0xa666;
      }
      FUN_005ee1c0(uVar11);
      FUN_0058ed80(param_1);
    }
    return;
  }
  if (((*(int *)(iVar10 + 0x20) == 0) && (*(int *)(iVar10 + 0x24) == 0)) &&
     (*(int *)(iVar10 + 0x28) == 0)) {
    bVar6 = true;
  }
  else {
    bVar6 = false;
  }
  if (!bVar6) {
    puVar12 = (undefined4 *)FUN_00590ae0(local_d8,piVar9);
    sVar8 = FUN_005ee080(*puVar12,puVar12[1]);
    uVar18 = (uint)(short)(sVar8 - *(short *)(param_1 + 0x34));
    uVar19 = (int)uVar18 >> 0x1f;
    if ((0x38e4 < (int)((uVar18 ^ uVar19) - uVar19)) &&
       (iVar10 = *(int *)(param_1 + 400),
       uVar18 = (uint)(short)(*(short *)(iVar10 + 0x34) - *(short *)(param_1 + 0x34)),
       uVar19 = (int)uVar18 >> 0x1f, (int)((uVar18 ^ uVar19) - uVar19) < 0x11c7)) goto LAB_005aa274;
  }
  if (*(int *)(param_1 + 700) == 0) {
    return;
  }
  if ((((bVar5) || (0x1e665 < (int)local_c0[2])) ||
      (0x8000 < (int)((local_c0[1] ^ (int)local_c0[1] >> 0x1f) - ((int)local_c0[1] >> 0x1f)))) ||
     (uVar18 = (int)(local_c0[0] - 0x4ccc) >> 0x1f,
     0x4ccb < (int)((local_c0[0] - 0x4ccc ^ uVar18) - uVar18))) {
    if (bVar5) {
      return;
    }
    if (*(int *)(param_1 + 0x40) == 0xb) {
      return;
    }
    if (0xd998 < local_a0) {
      return;
    }
    if (0x8000 < (int)((local_a4 ^ (int)local_a4 >> 0x1f) - ((int)local_a4 >> 0x1f))) {
      return;
    }
    uVar18 = (int)(local_a8 - 0x4cccU) >> 0x1f;
    if (0x4ccb < (int)((local_a8 - 0x4cccU ^ uVar18) - uVar18)) {
      return;
    }
    iVar10 = *(int *)(param_1 + 400);
    sVar8 = FUN_005ee080(*(undefined4 *)(iVar10 + 0x20),*(undefined4 *)(iVar10 + 0x24));
    iVar10 = FUN_005edfb0(*(undefined4 *)(iVar10 + 0x20),
                          *(undefined4 *)(&DAT_006d31c8 + (sVar8 + 8 >> 4 & 0xfffU) * 4),
                          *(undefined4 *)(iVar10 + 0x24),
                          *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar8 >> 4 & 0xfffU) * 4));
    if (iVar10 < 0x23d8) {
      return;
    }
    FUN_005a5430(0xb);
    return;
  }
  iVar10 = *(int *)(param_1 + 400);
  iVar17 = *(int *)(iVar10 + 0x4c);
  if ((iVar17 == 0) || (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) != 0)) goto LAB_005a9ff5;
  if (iVar17 == param_1) {
    if (((DAT_006d31c4 == '\0') && (*(int *)(iVar10 + 0x44) != param_1)) &&
       (*(int *)(iVar10 + 0x50) != 0)) {
      iVar10 = *(int *)(*(int *)(iVar10 + 0x50) + 0x3b8);
      iVar17 = *(int *)(iVar10 + 0x88);
      if (iVar17 != 0) {
        *(int *)(iVar10 + 0x88) = iVar17 + -1;
        piVar13 = (int *)(*(int *)(*(int *)(*(int *)(param_1 + 400) + 0x50) + 0x3b8) + 0x84);
        *piVar13 = *piVar13 + 1;
      }
    }
    if (*(char *)(*(int *)(param_1 + 400) + 0x62) == '\0') goto LAB_005a9ff5;
    if (param_1 == 0) {
      iVar10 = 0xc80000;
    }
    else {
      uVar18 = *(int *)(param_1 + 0x3a4) + *piVar9;
      uVar19 = (int)uVar18 >> 0x1f;
      iVar10 = (uVar18 ^ uVar19) - uVar19;
    }
    if ((0x24ffff < iVar10) ||
       (iVar10 = FUN_005ec250(),
       299 < (int)(iVar10 * 1000 + (iVar10 * 1000 >> 0x1f & 0x7fffU)) >> 0xf)) goto LAB_005a9ff5;
    uVar11 = FUN_005ec240();
    if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
      FUN_004eab20();
    }
  }
  else {
    if (((*(int *)(param_1 + 0x2b8) == *(int *)(iVar17 + 0x2b8)) ||
        (*(char *)(iVar10 + 0x62) != '\0')) ||
       (iVar10 = FUN_005ec250(),
       199 < (int)(iVar10 * 1000 + (iVar10 * 1000 >> 0x1f & 0x7fffU)) >> 0xf)) goto LAB_005a9ff5;
    uVar11 = FUN_005ec240();
    if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
      FUN_004eac50();
    }
  }
  FUN_005ec230(uVar11);
LAB_005a9ff5:
  FUN_0058eca0(param_1);
  if (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 0) {
    uVar11 = FUN_005ec240();
    if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
      FUN_004e9630(*(undefined4 *)(param_1 + 0x2c0),0);
    }
    FUN_005ec230(uVar11);
  }
  if ((int)local_c0[2] < 0xf332) {
    iVar10 = *(int *)(param_1 + 400);
    sVar8 = FUN_005ee080(*(undefined4 *)(iVar10 + 0x20),*(undefined4 *)(iVar10 + 0x24));
    iVar10 = FUN_005edfb0(*(undefined4 *)(iVar10 + 0x20),
                          *(undefined4 *)(&DAT_006d31c8 + (sVar8 + 8 >> 4 & 0xfffU) * 4),
                          *(undefined4 *)(iVar10 + 0x24),
                          *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar8 >> 4 & 0xfffU) * 4));
    if ((0x2666 < iVar10) || (0x8000 < *(int *)(*(int *)(param_1 + 400) + 0xc))) {
      uVar21 = extraout_var_03;
      if (*(int *)(param_1 + 0x40) != 0xb) {
        FUN_005a5430(0xb);
        uVar21 = extraout_var_04;
      }
      piVar13 = (int *)FUN_005ee0f0(0x4ccc,CONCAT22(uVar21,*(undefined2 *)(param_1 + 0x34)));
      iVar10 = *piVar9;
      iVar17 = *piVar13;
      iVar16 = piVar13[1];
      iVar1 = *(int *)(param_1 + 8);
      iVar2 = piVar13[2];
      iVar3 = *(int *)(param_1 + 0xc);
      iVar4 = *(int *)(param_1 + 400);
      iVar15 = DAT_00664fe4 - *(int *)(param_1 + 0x2c);
      *(undefined4 *)(iVar4 + 0x68) = 1;
      *(int *)(iVar4 + 0x6c) = iVar15 * 4;
      *(int *)(iVar4 + 0x9c) = iVar10 + iVar17;
      *(int *)(iVar4 + 0xa0) = iVar16 + iVar1;
      *(int *)(iVar4 + 0xa4) = iVar2 + iVar3;
    }
  }
  else {
    FUN_005a5430(0xd);
    piVar13 = (int *)FUN_005ee0f0(0x4ccc,CONCAT22(extraout_var,*(undefined2 *)(param_1 + 0x34)));
    iVar17 = *piVar13;
    iVar16 = *piVar9;
    iVar1 = *(int *)(param_1 + 0xc);
    iVar2 = piVar13[1];
    iVar3 = piVar13[2];
    iVar4 = *(int *)(param_1 + 8);
    iVar10 = DAT_00664fec * 4;
    iVar15 = *(int *)(param_1 + 400);
    *(undefined4 *)(iVar15 + 0x68) = 1;
    *(int *)(iVar15 + 0x6c) = iVar10;
    *(int *)(iVar15 + 0x9c) = iVar17 + iVar16;
    *(int *)(iVar15 + 0xa0) = iVar4 + iVar2;
    *(int *)(iVar15 + 0xa4) = iVar3 + iVar1;
  }
  iVar10 = *(int *)(param_1 + 400);
  *(undefined4 *)(iVar10 + 0x20) = 0;
  *(undefined4 *)(iVar10 + 0x24) = 0;
  *(undefined4 *)(iVar10 + 0x28) = 0;
  return;
}


