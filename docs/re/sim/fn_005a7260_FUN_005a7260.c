// FUN_005a7260  entry=005a7260  size=5114 bytes
// callers/callees expanded one level from seeds

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

uint __fastcall FUN_005a7260(int param_1)

{
  byte *pbVar1;
  int iVar2;
  char cVar3;
  short sVar4;
  uint uVar5;
  uint uVar6;
  int iVar7;
  int *piVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  undefined4 uVar13;
  int iVar14;
  int *piVar15;
  int iVar16;
  int iVar17;
  undefined4 *puVar18;
  uint uVar19;
  undefined2 extraout_var;
  int iVar20;
  uint uVar21;
  int iVar22;
  uint uVar23;
  int iVar24;
  int iVar25;
  bool bVar26;
  int *local_160;
  char local_159;
  int local_158;
  int local_154;
  int local_150;
  int *local_14c;
  int local_148;
  int local_144;
  int *local_140;
  uint local_138;
  int *local_128;
  int local_124;
  int local_120;
  int local_11c;
  int local_118;
  int local_114;
  int local_110;
  int local_10c;
  int local_108;
  undefined4 local_f8;
  undefined4 local_f4;
  undefined4 local_f0;
  int local_ec;
  int local_e8;
  undefined1 local_d8 [12];
  undefined1 local_cc [12];
  int aiStack_c0 [48];
  
  if ((*(int *)(param_1 + 0x40) == 0x1d) && (*(int *)(param_1 + 0x48) == 0)) {
    *(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x19dc) = 10000;
  }
  if ((*(int *)(*(int *)(param_1 + 0x18c) + 0x448) != 6) ||
     (((iVar7 = *(int *)(param_1 + 0x40), iVar7 != 0x1f && (iVar7 != 0x21)) &&
      ((iVar7 != 0x1d || (*(int *)(param_1 + 0x48) < 1)))))) goto LAB_005a73dd;
  if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
     (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
    bVar26 = false;
  }
  else {
    bVar26 = true;
  }
  if ((bVar26) && (*(char *)(param_1 + 0x5c) != '\0')) {
    bVar26 = true;
  }
  else {
    bVar26 = false;
  }
  if (bVar26) {
    iVar7 = *(int *)(param_1 + 0x184);
    uVar21 = (uint)(*(int *)(param_1 + 4) < 0);
    uVar5 = (uint)(ushort)(*(short *)(param_1 + 0x34) + 0x4000);
    if (*(char *)(iVar7 + 0x210) != '\0') {
      uVar5 = uVar5 - 0x80;
    }
    if (*(char *)(iVar7 + 0x212) != '\0') {
      uVar5 = uVar5 + 0x80;
    }
    sVar4 = *(short *)(&DAT_006654ba + uVar21 * 4);
    uVar19 = CONCAT22((short)((uint)iVar7 >> 0x10),sVar4);
    uVar23 = uVar5;
    if (sVar4 <= (short)uVar5) {
      uVar23 = uVar19;
    }
    uVar6 = (uint)*(ushort *)(&DAT_006654b8 + uVar21 * 4);
    if (((short)*(ushort *)(&DAT_006654b8 + uVar21 * 4) <= (short)uVar23) &&
       (uVar6 = uVar5, sVar4 <= (short)uVar5)) {
      uVar6 = uVar19;
    }
    FUN_005a8f20(uVar6 - 0x4000);
    if ((*(char *)(*(int *)(param_1 + 0x184) + 0x215) != '\0') ||
       ((*(int *)(param_1 + 0x48) == 0 &&
        (iVar7 = FUN_005ec250(), (int)(iVar7 * 1000 + (iVar7 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 300
        )))) {
      *(undefined4 *)(param_1 + 0x48) = 0;
      if (*(int *)(param_1 + 0x40) != 0x1d) {
        FUN_005aad30();
      }
      goto LAB_005a73dd;
    }
    if (((*(char *)(*(int *)(param_1 + 0x184) + 0x214) == '\0') && (*(int *)(param_1 + 0x48) != 0))
       || (*(undefined4 *)(param_1 + 0x48) = 0, *(int *)(param_1 + 0x40) == 0x1d))
    goto LAB_005a73dd;
  }
  else {
    if (*(int *)(param_1 + 0x40) == 0x1d) goto LAB_005a73dd;
    *(undefined4 *)(param_1 + 0x6c) = 0;
    iVar7 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
    if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1)) {
      iVar7 = -iVar7;
    }
    FUN_00590aa0(iVar7,0,0);
    FUN_005a8bc0(&local_f8);
    if (*(int *)(param_1 + 0x48) != 0) goto LAB_005a73dd;
    iVar7 = FUN_005ec250();
    if ((int)(iVar7 * 1000 + (iVar7 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 200) {
      FUN_005aad30();
      goto LAB_005a73dd;
    }
  }
  FUN_005aae40();
LAB_005a73dd:
  piVar15 = (int *)(param_1 + 4);
  cVar3 = FUN_0058fb50(piVar15);
  if ((cVar3 == '\0') ||
     (((-1 < *piVar15) - 1 & 0xfffffffe) + 1 !=
      ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
    uVar5 = 0;
  }
  else {
    uVar5 = 1;
  }
  if ((char)uVar5 == '\0') {
    iVar7 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
    if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == *(uint *)(param_1 + 0x2b8)) {
      iVar7 = -iVar7;
    }
    FUN_00590aa0(iVar7,0,0);
    FUN_005a89c0(&local_f8,0x5a);
    bVar26 = param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40);
    uVar5 = (uint)bVar26;
    if ((bVar26) && (uVar5 = FUN_0058f100(), (char)uVar5 == '\0')) {
      FUN_0058ed70();
      piVar8 = (int *)FUN_005ee0f0(0x6666,CONCAT22(extraout_var,*(undefined2 *)(param_1 + 0x34)));
      iVar7 = *(int *)(param_1 + 400);
      *(int *)(iVar7 + 4) = *(int *)(iVar7 + 4) - *piVar8;
      *(int *)(iVar7 + 8) = *(int *)(iVar7 + 8) - piVar8[1];
      uVar5 = piVar8[2];
      *(uint *)(iVar7 + 0xc) = *(int *)(iVar7 + 0xc) - uVar5;
    }
  }
  if ((*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 0) &&
     (uVar5 = *(uint *)(param_1 + 400), param_1 != *(int *)(uVar5 + 0x40))) {
    cVar3 = FUN_0058fb50(piVar15);
    if ((cVar3 == '\0') ||
       (((-1 < *piVar15) - 1 & 0xfffffffe) + 1 !=
        ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
      uVar5 = 0;
    }
    else {
      uVar5 = 1;
    }
    if ((char)uVar5 != '\0') {
      if ((DAT_006744a4 & 1) == 0) {
        DAT_006744a4 = DAT_006744a4 | 1;
        DAT_0067428c = 0x9999;
        DAT_00674284 = 0;
        DAT_00674290 = 0;
        _DAT_00674298 = 0x9999;
        _DAT_0067429c = 0;
        DAT_00674280 = 0x1b333;
        DAT_00674288 = 0x4000;
        DAT_00674294 = 0x10000;
        _DAT_006742a0 = 0x1cccc;
        _DAT_006742a4 = 0x21999;
        _DAT_006742a8 = 0x3555;
        _DAT_006742ac = 0x3333;
        _DAT_006742b0 = 0x21999;
        _DAT_006742b4 = 0x3555;
        _DAT_006742b8 = 0xf333;
        _DAT_006742bc = 0x21999;
        _DAT_006742c0 = 0x3555;
        _DAT_006742c4 = 0x1b333;
        _DAT_006742c8 = 0x21999;
        _DAT_006742cc = 0xffffcaab;
        _DAT_006742d0 = 0x3333;
        _DAT_006742d4 = 0x21999;
        _DAT_006742d8 = 0xffffcaab;
        _DAT_006742dc = 0xf333;
        _DAT_006742e0 = 0x21999;
        _DAT_006742e4 = 0xffffcaab;
        _DAT_006742e8 = 0x1b333;
        FUN_00605ff0(&DAT_005a8670);
      }
      if ((DAT_006744a4 & 2) == 0) {
        DAT_006744a4 = DAT_006744a4 | 2;
        _DAT_00674444 = 0x6666;
        _DAT_00674450 = 0x6666;
        _DAT_00674438 = 0x14ccc;
        _DAT_0067443c = 0;
        _DAT_00674440 = 0;
        _DAT_00674448 = 0;
        _DAT_0067444c = 0;
        _DAT_00674454 = 0;
        _DAT_00674458 = 0;
        _DAT_0067445c = 0x18ccc;
        _DAT_00674460 = 0x3555;
        _DAT_00674464 = 0;
        _DAT_00674468 = 0x18ccc;
        _DAT_0067446c = 0x3555;
        _DAT_00674470 = 0;
        _DAT_00674474 = 0x18ccc;
        _DAT_00674478 = 0x3555;
        _DAT_0067447c = 0;
        _DAT_00674480 = 0x18ccc;
        _DAT_00674484 = 0xffffcaab;
        _DAT_00674488 = 0;
        _DAT_0067448c = 0x18ccc;
        _DAT_00674490 = 0xffffcaab;
        _DAT_00674494 = 0;
        _DAT_00674498 = 0x18ccc;
        _DAT_0067449c = 0xffffcaab;
        _DAT_006744a0 = 0;
        FUN_00605ff0(&DAT_005a8660);
      }
      uVar5 = *(uint *)(param_1 + 0x40);
      local_159 = '\0';
      if ((((uVar5 == 0x1e) || (uVar5 == 0x22)) || (uVar5 == 0x23)) || (uVar5 == 0x20)) {
        if (((-1 < *(int *)(*(int *)(param_1 + 400) + 4)) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *piVar15) - 1 & 0xfffffffe) + 1) {
          *(byte *)(*(int *)(param_1 + 0x18c) + 0x461) =
               *(byte *)(*(int *)(param_1 + 0x18c) + 0x461) & 0xdf;
          pbVar1 = (byte *)(*(int *)(param_1 + 0x18c) + 0x461);
          *pbVar1 = *pbVar1 & 0xef;
        }
        FUN_005b05a0();
        iVar7 = *(int *)(param_1 + 400);
        uVar5 = *(int *)(iVar7 + 4) - *piVar15;
        uVar21 = (int)uVar5 >> 0x1f;
        if ((((int)((uVar5 ^ uVar21) - uVar21) < 0x230000) &&
            (uVar5 = *(int *)(iVar7 + 8) - *(int *)(param_1 + 8), uVar21 = (int)uVar5 >> 0x1f,
            (int)((uVar5 ^ uVar21) - uVar21) < 0x230000)) &&
           (uVar5 = *(int *)(iVar7 + 0xc) - *(int *)(param_1 + 0xc), uVar21 = (int)uVar5 >> 0x1f,
           (int)((uVar5 ^ uVar21) - uVar21) < 0x230000)) {
          piVar15 = (int *)0x1;
        }
        else {
          piVar15 = (int *)0x0;
        }
        if (((char)piVar15 != '\0') &&
           ((cVar3 = FUN_005b8c90(), cVar3 == '\0' ||
            ((piVar15 = *(int **)(param_1 + 400), piVar15[0x10] == 0 && (piVar15[0x11] == param_1)))
            ))) {
          iVar7 = *(int *)(param_1 + 400);
          local_124 = 0x7c72;
          local_120 = 0x7c72;
          local_148 = 0;
          local_138 = 0;
          local_128 = (int *)0x0;
          local_144 = -1;
          piVar15 = (int *)0x0;
          iVar14 = -1;
          if ((*(int *)(iVar7 + 0x5c) != 0) != true) {
            do {
              piVar15 = local_128;
              iVar14 = local_144;
              if (local_144 != -1) break;
              local_f8 = *(undefined4 *)(iVar7 + 4);
              local_f4 = *(undefined4 *)(iVar7 + 8);
              local_f0 = *(undefined4 *)(iVar7 + 0xc);
              iVar14 = 0x10;
              puVar18 = (undefined4 *)(iVar7 + 0x1c8);
              piVar15 = (int *)register0x00000010;
              do {
                local_160 = piVar15 + -3;
                iVar14 = iVar14 + -1;
                *local_160 = *puVar18;
                piVar15[-2] = puVar18[1];
                piVar15[-1] = puVar18[2];
                puVar18 = puVar18 + -3;
                piVar15 = local_160;
              } while (iVar14 != 0);
              if (local_128 == (int *)0x1) {
                iVar14 = *(int *)(iVar7 + 0x5c) + -1;
                iVar16 = ((int)(iVar14 + (iVar14 >> 0x1f & 3U)) >> 2) + 0x17;
                iVar14 = *(int *)(iVar7 + 4 + iVar16 * 0xc);
                piVar15 = (int *)(iVar7 + iVar16 * 0xc);
                iVar7 = *piVar15;
                iVar16 = piVar15[2];
                iVar17 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
                if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) ==
                    *(uint *)(param_1 + 0x2b8)) {
                  iVar17 = -iVar17;
                }
                uVar13 = FUN_005ee080(iVar17 - iVar7,-iVar14);
                FUN_005ee0f0(0x15478,uVar13);
                iVar17 = *(int *)(*(int *)(param_1 + 400) + 0x5c) + -1;
                iVar20 = (int)(iVar17 + (iVar17 >> 0x1f & 3U)) >> 2;
                iVar17 = iVar20 + 1;
                if (iVar17 < 0x10) {
                  local_e8 = iVar20 * local_108;
                  local_ec = iVar20 * local_110;
                  iVar24 = local_108 * iVar17;
                  local_160 = aiStack_c0 + iVar17 * 3;
                  iVar11 = local_10c * iVar17;
                  iVar25 = local_110 * iVar17;
                  local_140 = (int *)(0x10 - iVar17);
                  do {
                    iVar17 = iVar11 - iVar20 * local_10c;
                    *local_160 = (iVar25 - local_ec) + iVar7;
                    iVar11 = iVar11 + local_10c;
                    local_160[1] = iVar17 + iVar14;
                    iVar25 = iVar25 + local_110;
                    local_160[2] = (iVar24 - local_e8) + iVar16;
                    local_160 = local_160 + 3;
                    iVar24 = iVar24 + local_108;
                    local_140 = (int *)((int)local_140 + -1);
                  } while (local_140 != (int *)0x0);
                }
              }
              local_160 = (int *)0x0;
              local_14c = &DAT_00665510;
              local_140 = &DAT_00674288;
              do {
                if ((local_128 == (int *)0x0) ||
                   (*(int *)(&DAT_006654e8 + (int)local_160 * 4) != -1)) {
                  iVar7 = *(int *)(&DAT_00665538 + (int)local_160 * 4);
                  iVar14 = local_140[-2];
                  iVar16 = local_140[-1];
                  iVar17 = *local_140;
                  piVar15 = (int *)(param_1 + 4);
                  local_158 = aiStack_c0[iVar7 * 3];
                  local_154 = aiStack_c0[iVar7 * 3 + 1];
                  local_150 = aiStack_c0[iVar7 * 3 + 2];
                  FUN_00590aa0(local_158 - *piVar15,local_154 - *(int *)(param_1 + 8),
                               local_150 - *(int *)(param_1 + 0xc));
                  iVar20 = FUN_005b1260();
                  uVar21 = iVar20 - iVar14;
                  puVar18 = (undefined4 *)FUN_00590ae0(local_cc,piVar15);
                  uVar13 = FUN_005ee080(*puVar18,puVar18[1]);
                  iVar16 = CONCAT22((short)((uint)uVar13 >> 0x10),
                                    (short)uVar13 - *(short *)(param_1 + 0x34)) - iVar16;
                  puVar18 = (undefined4 *)FUN_00590ae0(local_d8,piVar15);
                  sVar4 = FUN_005ee080(*puVar18,puVar18[1]);
                  uVar5 = local_150 - iVar17 >> 0x1f;
                  if ((((int)((local_150 - iVar17 ^ uVar5) - uVar5) < 0x6666) ||
                      (((double)iVar17 == _DAT_00639260 && (iVar17 < local_150)))) &&
                     ((int)((uVar21 ^ (int)uVar21 >> 0x1f) - ((int)uVar21 >> 0x1f)) < *local_14c)) {
                    uVar5 = (uint)(short)((*(short *)(param_1 + 0x34) - sVar4) + (short)iVar16);
                    uVar23 = (int)uVar5 >> 0x1f;
                    iVar14 = (uVar5 ^ uVar23) - uVar23;
                    if (iVar14 < (short)local_124) {
LAB_005a8217:
                      local_144 = (int)local_160;
                      local_148 = iVar7 * 4;
                      local_138 = uVar21;
                      local_124 = iVar14;
                      local_120 = iVar16;
                      local_11c = local_158;
                      local_118 = local_154;
                      local_114 = local_150;
                    }
                    else {
                      iVar17 = *(int *)(param_1 + 0x18c);
                      if (((((local_158 < *(int *)(iVar17 + 0x1828)) ||
                            (*(int *)(iVar17 + 0x1834) < local_158)) ||
                           (local_154 < *(int *)(iVar17 + 0x182c))) ||
                          ((*(int *)(iVar17 + 0x1838) < local_154 ||
                           (local_150 < *(int *)(iVar17 + 0x1830))))) ||
                         (*(int *)(iVar17 + 0x183c) < local_150)) {
                        bVar26 = false;
                      }
                      else {
                        bVar26 = true;
                      }
                      if (bVar26) {
                        if (((local_11c < *(int *)(iVar17 + 0x1828)) ||
                            (*(int *)(iVar17 + 0x1834) < local_11c)) ||
                           ((local_118 < *(int *)(iVar17 + 0x182c) ||
                            (((*(int *)(iVar17 + 0x1838) < local_118 ||
                              (local_114 < *(int *)(iVar17 + 0x1830))) ||
                             (*(int *)(iVar17 + 0x183c) < local_114)))))) {
                          bVar26 = false;
                        }
                        else {
                          bVar26 = true;
                        }
                        if (!bVar26) goto LAB_005a8217;
                      }
                    }
                  }
                }
                local_140 = local_140 + 3;
                local_160 = (int *)((int)local_160 + 1);
                local_14c = local_14c + 1;
              } while ((int)local_140 < 0x6742f4);
              iVar7 = *(int *)(param_1 + 400);
              piVar15 = (int *)((int)local_128 + 1);
              iVar14 = local_144;
              local_128 = piVar15;
            } while ((int)piVar15 < (int)((*(int *)(iVar7 + 0x5c) != 0) + 1));
          }
          if (-1 < iVar14) {
            FUN_005ee0f0(*(int *)(&DAT_00674438 + iVar14 * 0xc) + local_138,
                         (uint)(ushort)(*(short *)(param_1 + 0x34) +
                                       (short)*(undefined4 *)(&DAT_0067443c + iVar14 * 0xc)) +
                         local_120);
            *(byte *)(*(int *)(param_1 + 0x18c) + 0x461) =
                 *(byte *)(*(int *)(param_1 + 0x18c) + 0x461) | 0x10;
            iVar7 = *(int *)(param_1 + 4);
            iVar16 = *(int *)(param_1 + 8);
            iVar17 = *(int *)(param_1 + 0xc);
            *(int *)(param_1 + 0x44) = iVar14;
            if (*(int *)(&DAT_006654e8 + iVar14 * 4) == -1) {
              FUN_005909f0(1);
              FUN_00594470(0xf,param_1,0);
              uVar13 = FUN_005ec240();
              if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
                FUN_004ebf80(*(undefined4 *)(param_1 + 0x2c0));
              }
              FUN_005ec230(uVar13);
              FUN_005a5430(*(undefined4 *)(&DAT_006654c0 + iVar14 * 4));
              if (DAT_006d31c4 == '\0') {
                piVar15 = (int *)(*(int *)(param_1 + 0x3b8) + 0x94);
                *piVar15 = *piVar15 + 1;
              }
              iVar14 = *(int *)(*(int *)(param_1 + 400) + 0x70);
              if (iVar14 < 0x79) {
                iVar14 = 0x78;
              }
              *(int *)(*(int *)(param_1 + 400) + 0x70) = iVar14;
              iVar14 = *(int *)(param_1 + 400);
              *(undefined4 *)(iVar14 + 0x20) = 0;
              *(undefined4 *)(iVar14 + 0x24) = 0;
              *(undefined4 *)(iVar14 + 0x28) = 0;
              iVar14 = *(int *)(param_1 + 400);
              *(undefined4 *)(iVar14 + 0x68) = 1;
              *(int *)(iVar14 + 0x6c) = local_148;
              *(int *)(iVar14 + 0x9c) = local_11c;
              *(int *)(iVar14 + 0xa0) = local_118;
              *(int *)(iVar14 + 0xa4) = local_114;
              FUN_0058eca0(param_1);
              *(undefined1 *)(*(int *)(param_1 + 400) + 99) = 1;
              *(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x458) = 0;
            }
            else {
              FUN_005a5430(*(int *)(&DAT_006654e8 + iVar14 * 4));
            }
            piVar15 = (int *)(param_1 + 0x94);
            *(int *)(param_1 + 0x84) = local_148;
            *(undefined4 *)(param_1 + 0x80) = 1;
            *piVar15 = local_158 + iVar7;
            local_159 = '\x01';
            *(int *)(param_1 + 0x98) = local_154 + iVar16;
            *(int *)(param_1 + 0x9c) = local_150 + iVar17;
            *(short *)(param_1 + 0x66) = *(short *)(param_1 + 0x34) + (short)local_120;
          }
        }
        uVar5 = CONCAT31((int3)((uint)piVar15 >> 8),local_159);
        if ((local_159 == '\0') &&
           ((uVar5 = *(uint *)(*(int *)(param_1 + 400) + 0x40), uVar5 == 0 ||
            (*(int *)(param_1 + 0x2b8) != *(int *)(uVar5 + 0x2b8))))) {
          piVar15 = (int *)FUN_005ee0f0(0x4ccc,*(undefined2 *)(param_1 + 0x34));
          iVar7 = *(int *)(param_1 + 400);
          uVar5 = (*(int *)(iVar7 + 0x138) - *piVar15) - *(int *)(param_1 + 4);
          uVar21 = (int)uVar5 >> 0x1f;
          if (((int)((uVar5 ^ uVar21) - uVar21) < 0x8000) &&
             ((uVar5 = *(int *)(iVar7 + 0x13c) - (piVar15[1] + *(int *)(param_1 + 8)),
              uVar21 = (int)uVar5 >> 0x1f, (int)((uVar5 ^ uVar21) - uVar21) < 0x8000 &&
              (uVar5 = *(int *)(iVar7 + 0x140) - (piVar15[2] + *(int *)(param_1 + 0xc)),
              uVar21 = (int)uVar5 >> 0x1f, (int)((uVar5 ^ uVar21) - uVar21) < 0x8000)))) {
            bVar26 = true;
          }
          else {
            bVar26 = false;
          }
          if (!bVar26) {
            piVar15 = (int *)FUN_005ee0f0(0x4ccc,*(undefined2 *)(param_1 + 0x34));
            iVar7 = *(int *)(param_1 + 400);
            uVar5 = ((*(int *)(iVar7 + 0x138) - *(int *)(param_1 + 0x20)) - *piVar15) -
                    *(int *)(param_1 + 4);
            uVar21 = (int)uVar5 >> 0x1f;
            if ((((int)((uVar5 ^ uVar21) - uVar21) < 0x8000) &&
                (uVar5 = *(int *)(iVar7 + 0x13c) -
                         (*(int *)(param_1 + 0x24) + piVar15[1] + *(int *)(param_1 + 8)),
                uVar21 = (int)uVar5 >> 0x1f, (int)((uVar5 ^ uVar21) - uVar21) < 0x8000)) &&
               (uVar5 = *(int *)(iVar7 + 0x140) -
                        (*(int *)(param_1 + 0x28) + *(int *)(param_1 + 0xc) + piVar15[2]),
               uVar21 = (int)uVar5 >> 0x1f, (int)((uVar5 ^ uVar21) - uVar21) < 0x8000)) {
              uVar5 = 1;
            }
            else {
              uVar5 = 0;
            }
            if ((char)uVar5 == '\0') {
              return uVar5;
            }
          }
          uVar5 = FUN_005aa870(1);
        }
      }
      else if ((((*(byte *)(*(int *)(param_1 + 0x18c) + 0x461) & 0x20) == 0) &&
               (((((uVar5 == 0x35 || (uVar5 == 0x31)) ||
                  ((uVar5 == 0x26 || ((uVar5 == 0x2a || (uVar5 == 0x32)))))) || (uVar5 == 0x27)) ||
                (uVar5 == 0x2b)))) && (*(int *)(param_1 + 0x2c) == 5)) {
        iVar7 = *(int *)(param_1 + 400);
        iVar14 = *(int *)(&DAT_00665538 + *(int *)(param_1 + 0x44) * 4);
        sVar4 = FUN_005ee080(*(undefined4 *)(iVar7 + 0x20),*(undefined4 *)(iVar7 + 0x24));
        iVar9 = FUN_005edfb0(*(undefined4 *)(iVar7 + 0x20),
                             *(undefined4 *)(&DAT_006d31c8 + (sVar4 + 8 >> 4 & 0xfffU) * 4),
                             *(undefined4 *)(iVar7 + 0x24),
                             *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar4 >> 4 & 0xfffU) * 4));
        iVar7 = iVar14 + 0x12;
        iVar16 = *(int *)(*(int *)(param_1 + 400) + iVar7 * 0xc);
        iVar7 = *(int *)(param_1 + 400) + iVar7 * 0xc;
        iVar17 = *(int *)(iVar7 + 4);
        iVar7 = *(int *)(iVar7 + 8);
        iVar20 = *(int *)(param_1 + 0x44);
        iVar24 = (&DAT_00674280)[iVar20 * 3];
        iVar11 = *(int *)(&DAT_00674438 + iVar20 * 0xc);
        iVar22 = (&DAT_00674288)[iVar20 * 3] - *(int *)(&DAT_00674440 + iVar20 * 0xc);
        iVar20 = *piVar15;
        iVar25 = *(int *)(param_1 + 8);
        iVar2 = *(int *)(param_1 + 0xc);
        iVar10 = FUN_005b1260();
        iVar12 = *(int *)(param_1 + 0x38c);
        uVar23 = iVar10 - (iVar24 - iVar11);
        uVar5 = iVar7 - iVar22 >> 0x1f;
        iVar24 = (iVar7 - iVar22 ^ uVar5) - uVar5;
        uVar21 = (int)uVar23 >> 0x1f;
        if (((iVar24 < (iVar12 * 0x570a) / 100) ||
            (((*(int *)(param_1 + 0x40) == 0x31 || (*(int *)(param_1 + 0x40) == 0x32)) &&
             (iVar7 < iVar22)))) &&
           ((int)((uVar23 ^ uVar21) - uVar21) <
            ((&DAT_00665510)[*(int *)(param_1 + 0x44)] * iVar12) / 0x140)) {
          iVar11 = MulDiv(iVar12 * 4 + 400,0x9999 - iVar9,0x4c96);
          iVar12 = FUN_005ec250();
          if ((int)(iVar12 * 1000 + (iVar12 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar11) {
            FUN_005909f0(1);
            if ((*(int *)(param_1 + 0x40) == 0x31) || (*(int *)(param_1 + 0x40) == 0x32)) {
              FUN_00594470(0xf,param_1,0);
              uVar13 = FUN_005ec240();
              if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
                FUN_004ebf80(*(undefined4 *)(param_1 + 0x2c0));
              }
              FUN_005ec230(uVar13);
            }
            else {
              FUN_00594470(0xf,param_1,1);
              uVar13 = FUN_005ec240();
              if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
                FUN_004ea530(*(undefined4 *)(param_1 + 0x2c0),0);
              }
              FUN_005ec230(uVar13);
            }
            iVar20 = *(int *)(param_1 + 0x40);
            if ((((iVar20 == 0x2a) || (iVar20 == 0x2b)) || ((iVar20 == 0x26 || (iVar20 == 0x27))))
               && (*(char *)(*(int *)(param_1 + 0x18c) + 0x180c) != '\0')) {
              FUN_00590f00();
            }
            if (*(int *)(param_1 + 0x40) == 0x35) {
              *(undefined4 *)(param_1 + 0x40) = 0x30;
            }
            else {
              *(int *)(param_1 + 0x40) = *(int *)(param_1 + 0x40) + 2;
            }
            if (DAT_006d31c4 == '\0') {
              piVar15 = (int *)(*(int *)(param_1 + 0x3b8) + 0x94);
              *piVar15 = *piVar15 + 1;
            }
            iVar20 = *(int *)(*(int *)(param_1 + 400) + 0x70);
            if (iVar20 < 0x79) {
              iVar20 = 0x78;
            }
            *(int *)(*(int *)(param_1 + 400) + 0x70) = iVar20;
            iVar20 = *(int *)(param_1 + 400);
            *(undefined4 *)(iVar20 + 0x20) = 0;
            *(undefined4 *)(iVar20 + 0x24) = 0;
            *(undefined4 *)(iVar20 + 0x28) = 0;
            iVar20 = *(int *)(param_1 + 400);
            *(undefined4 *)(iVar20 + 0x68) = 1;
            *(int *)(iVar20 + 0x6c) = (iVar14 + -5) * 4;
            *(int *)(iVar20 + 0x9c) = iVar16;
            *(int *)(iVar20 + 0xa0) = iVar17;
            *(int *)(iVar20 + 0xa4) = iVar7;
            FUN_0058eca0(param_1);
            *(undefined1 *)(*(int *)(param_1 + 400) + 99) = 1;
            uVar5 = *(uint *)(param_1 + 0x18c);
            *(undefined4 *)(uVar5 + 0x458) = 0;
            return uVar5;
          }
        }
        iVar14 = *(int *)(param_1 + 0x38c);
        if (((iVar24 < (iVar14 * 0x7333) / 100) ||
            (((uVar5 = *(uint *)(param_1 + 0x40), uVar5 == 0x31 || (uVar5 == 0x32)) &&
             (iVar7 < iVar22)))) &&
           (uVar5 = -((&DAT_00665510)[*(int *)(param_1 + 0x44)] * iVar14 >> 0x1f),
           (int)((uVar23 ^ uVar21) - uVar21) <
           ((&DAT_00665510)[*(int *)(param_1 + 0x44)] * iVar14) / 0xfa)) {
          iVar11 = MulDiv(iVar14 * 2 + 400,0x9999 - iVar9,0x4c96);
          iVar14 = *(int *)(param_1 + 0x38c);
          iVar12 = FUN_005ec250();
          uVar5 = (int)(iVar12 * 1000 + (iVar12 * 1000 >> 0x1f & 0x7fffU)) >> 0xf;
          if ((int)uVar5 < iVar11 + 100 + iVar14 * 2) {
            sVar4 = *(short *)(param_1 + 0x34);
            iVar14 = FUN_005ec250();
            FUN_005ee0f0((*(int *)(param_1 + 0x38c) * 0x4d03) / 200,
                         ((int)(iVar14 * 0x80 + (iVar14 * 0x80 >> 0x1f & 0x7fU)) >> 7) + -0x4000 +
                         (int)sVar4);
            FUN_005909f0(1);
            iVar14 = *(int *)(param_1 + 400);
            if ((*(int *)(iVar14 + 0x4c) == 0) && (*(int *)(iVar14 + 0x50) != 0)) {
              *(undefined4 *)(iVar14 + 0x50) = 0;
            }
            pbVar1 = (byte *)(*(int *)(param_1 + 0x18c) + 0x461);
            *pbVar1 = *pbVar1 | 0x20;
            iVar14 = FUN_005ec250();
            FUN_005ee6e0(((int)(iVar14 * 0xe39 + (iVar14 * 0xe39 >> 0x1f & 0x7fffU)) >> 0xf) + 0x38f
                        );
            iVar14 = *(int *)(param_1 + 400);
            *(int *)(iVar14 + 4) = *(int *)(iVar14 + 4) + *(int *)(param_1 + 0x20);
            *(int *)(iVar14 + 8) = *(int *)(iVar14 + 8) + *(int *)(param_1 + 0x24);
            *(int *)(iVar14 + 0xc) = *(int *)(iVar14 + 0xc) + *(int *)(param_1 + 0x28);
            iVar14 = *(int *)(param_1 + 400);
            *(int *)(iVar14 + 0x20) = iVar16 - iVar20;
            *(int *)(iVar14 + 0x24) = iVar17 - iVar25;
            *(int *)(iVar14 + 0x28) = iVar7 - iVar2;
            FUN_0058ed80(param_1);
            FUN_00594470(0xe,param_1,1);
            if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180c) != '\0') {
              FUN_00590f00();
            }
            uVar13 = FUN_005ec240();
            if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
              FUN_004ea660();
            }
            uVar5 = FUN_005ec230(uVar13);
            return uVar5;
          }
        }
        if ((iVar24 < 0x7333) &&
           (uVar5 = (&DAT_00665510)[*(int *)(param_1 + 0x44)] * 0x55555556,
           (int)((uVar23 ^ uVar21) - uVar21) < (int)(&DAT_00665510)[*(int *)(param_1 + 0x44)] / 3))
        {
          iVar7 = FUN_005ec250();
          uVar5 = (int)(iVar7 * 1000 + (iVar7 * 1000 >> 0x1f & 0x7fffU)) >> 0xf;
          if ((int)uVar5 < 300) {
            pbVar1 = (byte *)(*(int *)(param_1 + 0x18c) + 0x461);
            *pbVar1 = *pbVar1 | 0x20;
            return uVar5;
          }
        }
      }
    }
  }
  return uVar5;
}


