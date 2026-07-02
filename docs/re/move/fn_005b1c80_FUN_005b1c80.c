// FUN_005b1c80  entry=005b1c80  size=3679 bytes

char __fastcall FUN_005b1c80(int param_1)

{
  int iVar1;
  char cVar2;
  bool bVar3;
  short sVar4;
  uint uVar5;
  int iVar6;
  uint uVar7;
  undefined4 uVar8;
  int iVar9;
  int iVar10;
  undefined4 *puVar11;
  int *piVar12;
  int iVar13;
  int iVar14;
  uint uVar15;
  int iVar16;
  undefined4 uVar17;
  undefined4 uVar18;
  char local_95;
  int local_94;
  int local_90;
  int local_8c;
  int local_88;
  int local_84;
  int local_80;
  int local_7c;
  int local_78;
  undefined1 local_74 [4];
  int local_70;
  int local_68;
  int local_64;
  int local_60;
  int local_5c;
  int local_54;
  undefined1 local_24 [24];
  undefined1 local_c [12];
  
  local_95 = '\0';
  if (*(int *)(param_1 + 0x13c) == 6) {
    if (*(char *)(param_1 + 0x2d8) == '\0') {
      *(undefined4 *)(param_1 + 0x13c) = 0;
    }
    if (*(int *)(param_1 + 0x13c) != 6) goto LAB_005b1cc0;
LAB_005b1d71:
    uVar5 = *(uint *)(param_1 + 0x218);
    uVar15 = *(uint *)(param_1 + 0x224);
    iVar13 = *(int *)(param_1 + 8);
    if ((int)(((int)uVar5 < 1) - 1 & uVar5) <= (int)uVar15) {
      uVar15 = ((int)uVar5 < 1) - 1 & uVar5;
    }
    iVar6 = *(int *)(param_1 + 0x214);
    iVar9 = iVar6;
    if (iVar6 <= iVar13) {
      iVar9 = iVar13;
    }
    iVar10 = *(int *)(param_1 + 0x220);
    if ((iVar9 <= *(int *)(param_1 + 0x220)) && (iVar10 = iVar6, iVar6 <= iVar13)) {
      iVar10 = iVar13;
    }
    uVar5 = *(uint *)(param_1 + 0x210);
    uVar7 = *(uint *)(param_1 + 0x21c);
    if ((int)(((int)uVar5 < 1) - 1 & uVar5) <= (int)uVar7) {
      uVar7 = uVar5 & ((int)uVar5 < 1) - 1;
    }
    FUN_00590aa0(uVar7,iVar10,uVar15);
    FUN_005a89c0(&local_94,0x5a);
    *(undefined4 *)(param_1 + 0x13c) = 6;
    local_95 = '\x01';
  }
  else {
LAB_005b1cc0:
    iVar13 = *(int *)(*(int *)(param_1 + 400) + 0x40);
    if ((iVar13 != 0) && (param_1 != iVar13)) {
      cVar2 = FUN_005b2b30((int *)(param_1 + 4));
      if (cVar2 != '\0') {
        iVar13 = *(int *)(*(int *)(param_1 + 400) + 0x40);
        if (iVar13 == 0) {
          iVar13 = 0xc80000;
        }
        else {
          uVar5 = *(int *)(iVar13 + 0x3a4) + *(int *)(iVar13 + 4);
          uVar15 = (int)uVar5 >> 0x1f;
          iVar13 = (uVar5 ^ uVar15) - uVar15;
        }
        if (param_1 == 0) {
          iVar6 = 0xc80000;
        }
        else {
          uVar5 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
          uVar15 = (int)uVar5 >> 0x1f;
          iVar6 = (uVar5 ^ uVar15) - uVar15;
        }
        if (((iVar6 < iVar13) && (*(char *)(param_1 + 0x2d8) != '\0')) &&
           (iVar13 = FUN_005b3c90(0,1000), iVar13 < 200)) goto LAB_005b1d71;
      }
    }
  }
  if ((local_95 != '\0') || (param_1 != *(int *)(*(int *)(param_1 + 400) + 0x40)))
  goto LAB_005b29c2;
  if ((*(int *)(*(int *)(param_1 + 0x18c) + 0x458) == 0) ||
     (*(int *)(*(int *)(param_1 + 0x184) + 0x314) != 1)) {
LAB_005b1e7d:
    uVar18 = 0;
    uVar17 = 0;
    uVar8 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar8,uVar17,uVar18);
    iVar13 = FUN_005b1070(*(undefined4 *)(param_1 + 0x188),&local_94,0x8000);
    if (0x7fff < iVar13) {
      iVar13 = param_1 + 4;
      cVar2 = FUN_005b04e0(iVar13);
      if (cVar2 != '\0') {
        uVar18 = 0;
        uVar17 = 0;
        uVar8 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
        FUN_00590aa0(uVar8,uVar17,uVar18);
        FUN_00590ae0(local_74,iVar13);
        iVar6 = FUN_005b1260();
        iVar9 = FUN_005b3c90(0,1000);
        if (iVar9 < ((0x190000 - iVar6) * 0xfa) / 0x140000) goto LAB_005b20d3;
      }
      if ((*(byte *)(param_1 + 0x14c) & 0xf) == 0) {
        uVar18 = 0;
        uVar17 = 0;
        uVar8 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
        FUN_00590aa0(uVar8,uVar17,uVar18);
        FUN_00590ae0(local_74,iVar13);
        iVar13 = FUN_005b1260();
        iVar6 = FUN_005b3c90(0,1000);
        if (iVar6 < 0xf - (iVar13 * 0xf) / 0x280000) goto LAB_005b20d3;
      }
    }
    uVar18 = 0;
    uVar17 = 0;
    uVar8 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar8,uVar17,uVar18);
    FUN_00590ae0(local_74,param_1 + 4);
    iVar13 = FUN_005b1260();
    if (iVar13 < 0x1c0000) {
      uVar18 = 0;
      uVar17 = 0;
      uVar8 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
      FUN_00590aa0(uVar8,uVar17,uVar18);
      iVar13 = FUN_005b1070(*(undefined4 *)(param_1 + 0x188),&local_94,0x20000);
      if (0x1ffff < iVar13) {
        iVar13 = *(int *)(param_1 + 0x2c8);
        if (iVar13 == 9) {
LAB_005b20a6:
          iVar13 = 0x14;
        }
        else {
          if ((iVar13 == 0xc) || (iVar13 == 0xe)) {
            bVar3 = true;
          }
          else {
            bVar3 = false;
          }
          iVar13 = 5;
          if (bVar3) goto LAB_005b20a6;
        }
        iVar6 = FUN_005ec250();
        if ((int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar13)
        goto LAB_005b20d3;
      }
    }
  }
  else {
    if (param_1 == 0) {
      iVar13 = 0xc80000;
    }
    else {
      uVar5 = *(int *)(param_1 + 4) - *(int *)(param_1 + 0x3a4);
      uVar15 = (int)uVar5 >> 0x1f;
      iVar13 = (uVar5 ^ uVar15) - uVar15;
    }
    if (0x1bffff < iVar13) goto LAB_005b1e7d;
LAB_005b20d3:
    *(undefined4 *)(param_1 + 0x13c) = 5;
  }
  if (*(int *)(param_1 + 0x13c) == 5) {
    uVar18 = 0;
    uVar17 = 0;
    iVar13 = ((*(int *)(param_1 + 0x3a0) + *(int *)(param_1 + 0x388)) * 0x238e) / 200 + 0x38e;
    uVar8 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar8,uVar17,uVar18);
    FUN_005a89c0(&local_94,0x5a);
    uVar18 = 0;
    uVar17 = 0;
    uVar8 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar8,uVar17,uVar18);
    sVar4 = FUN_005aac00(&local_94);
    uVar5 = (int)sVar4 >> 0x1f;
    iVar6 = FUN_005ec250();
    if ((int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf <
        (int)((iVar13 - (((int)sVar4 ^ uVar5) - uVar5)) * 1000) / iVar13) {
      FUN_005aa870(0);
      *(undefined4 *)(param_1 + 0x13c) = 0;
      *(undefined4 *)(param_1 + 0x140) = 0;
    }
LAB_005b293a:
    local_95 = '\x01';
  }
  else {
    cVar2 = FUN_005b2b70();
    if ((cVar2 == '\0') && (cVar2 = FUN_005b3060(), cVar2 == '\0')) {
      if (param_1 == 0) {
        iVar13 = 0xc80000;
      }
      else {
        uVar5 = *(int *)(param_1 + 4) - *(int *)(param_1 + 0x3a4);
        uVar15 = (int)uVar5 >> 0x1f;
        iVar13 = (uVar5 ^ uVar15) - uVar15;
      }
      local_95 = '\0';
      if (0x1a0000 < iVar13) {
        if (param_1 == 0) {
          iVar13 = 0xc80000;
        }
        else {
          uVar5 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
          uVar15 = (int)uVar5 >> 0x1f;
          iVar13 = (uVar5 ^ uVar15) - uVar15;
        }
        if (0x90000 < iVar13) {
          iVar13 = *(int *)(param_1 + 0x2c8);
          if (iVar13 == 9) {
LAB_005b228c:
            iVar13 = 100;
          }
          else {
            if ((iVar13 == 0xc) || (iVar13 == 0xe)) {
              bVar3 = true;
            }
            else {
              bVar3 = false;
            }
            iVar13 = 200;
            if (bVar3) goto LAB_005b228c;
          }
          if (param_1 == 0) {
            iVar6 = 0xc80000;
          }
          else {
            uVar5 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
            uVar15 = (int)uVar5 >> 0x1f;
            iVar6 = (uVar5 ^ uVar15) - uVar15;
          }
          iVar9 = FUN_005ec250();
          if ((int)(iVar9 * 1000 + (iVar9 * 1000 >> 0x1f & 0x7fffU)) >> 0xf <
              (int)(((iVar6 < 0x140001) - 1 & 0xfffffed4) + 500 + iVar13)) {
            iVar13 = *(int *)(*(int *)(param_1 + 0x184) + 0x304);
            iVar6 = FUN_005ec250();
            if ((int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < (0x7d - iVar13) * 8)
            {
              iVar13 = *(int *)(param_1 + 0x2c8);
              if ((iVar13 == 2) || (iVar13 == 3)) {
                bVar3 = true;
              }
              else {
                bVar3 = false;
              }
              if (bVar3) {
LAB_005b236f:
                iVar13 = 800;
              }
              else {
                if ((iVar13 == 7) || (iVar13 == 0xb)) {
                  bVar3 = true;
                }
                else {
                  bVar3 = false;
                }
                iVar13 = 400;
                if (bVar3) goto LAB_005b236f;
              }
              iVar6 = FUN_005ec250();
              if ((int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar13) {
                iVar6 = 0;
                local_68 = 0;
                local_78 = 0;
                iVar13 = **(int **)(param_1 + 0x184);
                iVar9 = (*(int **)(param_1 + 0x184))[1];
                while (local_5c = iVar9 + -1, local_60 = iVar13, iVar9 != 0) {
                  if ((*(int *)(iVar13 + 700) != 0) && (iVar13 != param_1)) {
                    if (*(int *)(param_1 + 0x2b8) == *(int *)(iVar13 + 0x2b8)) {
                      if (iVar13 == 0) {
                        iVar9 = 0xc80000;
                      }
                      else {
                        uVar5 = *(int *)(iVar13 + 4) - *(int *)(iVar13 + 0x3a4);
                        uVar15 = (int)uVar5 >> 0x1f;
                        iVar9 = (uVar5 ^ uVar15) - uVar15;
                      }
                    }
                    else {
                      iVar9 = FUN_005b1c60();
                    }
                    iVar10 = FUN_005b1c40();
                    if (iVar10 < iVar9) {
LAB_005b2495:
                      if (iVar13 == 0) {
                        iVar9 = 0xc80000;
                      }
                      else {
                        iVar9 = *(int *)(param_1 + 0xe4 +
                                        (*(int *)(iVar13 + 0x2c4) + *(int *)(iVar13 + 0x2b8) * 0xb)
                                        * 4);
                      }
                      if (0x90000 < iVar9) {
                        if (iVar13 == 0) {
                          iVar9 = 0xc80000;
                        }
                        else {
                          iVar9 = *(int *)(param_1 + 0xe4 +
                                          (*(int *)(iVar13 + 0x2c4) + *(int *)(iVar13 + 0x2b8) * 0xb
                                          ) * 4);
                        }
                        if ((iVar9 < 0x2d0000) &&
                           ((*(char *)(iVar13 + 0x2d8) == '\0' ||
                            (iVar9 = FUN_005ec250(),
                            (int)(iVar9 * 1000 + (iVar9 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 200))))
                        {
                          if (iVar13 == 0) {
                            iVar6 = 0xc80000;
                          }
                          else {
                            iVar6 = *(int *)(param_1 + 0xe4 +
                                            (*(int *)(iVar13 + 0x2c4) +
                                            *(int *)(iVar13 + 0x2b8) * 0xb) * 4);
                          }
                          local_64 = 0x3e80000;
                          iVar9 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
                          if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) ==
                              1U - *(int *)(param_1 + 0x2b8)) {
                            iVar9 = -iVar9;
                          }
                          FUN_00590aa0(iVar9,0,0);
                          puVar11 = (undefined4 *)FUN_00590ae0(local_24,iVar13 + 4);
                          iVar13 = FUN_005ee080(*puVar11,puVar11[1]);
                          piVar12 = (int *)FUN_005ee0f0(iVar6 / 5,
                                                        (int)(short)((-(ushort)((*(uint *)(*(int *)(
                                                  param_1 + 0x18c) + 0x19a0) & 1) !=
                                                  *(uint *)(param_1 + 0x2b8)) & 0x8000) -
                                                  (short)iVar13) / 2 + iVar13);
                          local_54 = *(int *)(param_1 + 4) + *piVar12;
                          iVar10 = piVar12[1] + *(int *)(param_1 + 8);
                          iVar13 = *(int *)(param_1 + 0x18c);
                          iVar9 = piVar12[2] + *(int *)(param_1 + 0xc);
                          iVar6 = *(int *)(iVar13 + 0x1830);
                          if (*(int *)(iVar13 + 0x1830) <= iVar9) {
                            iVar6 = iVar9;
                          }
                          local_88 = *(int *)(iVar13 + 0x183c);
                          if ((iVar6 <= local_88) &&
                             (local_88 = *(int *)(iVar13 + 0x1830),
                             *(int *)(iVar13 + 0x1830) <= iVar9)) {
                            local_88 = iVar9;
                          }
                          iVar6 = *(int *)(iVar13 + 0x182c);
                          iVar9 = iVar6;
                          if (iVar6 <= iVar10) {
                            iVar9 = iVar10;
                          }
                          local_80 = *(int *)(iVar13 + 0x1838);
                          if ((iVar9 <= local_80) && (local_80 = iVar10, iVar10 < iVar6)) {
                            local_80 = iVar6;
                          }
                          iVar6 = *(int *)(iVar13 + 0x1828);
                          iVar9 = iVar6;
                          if (iVar6 <= local_54) {
                            iVar9 = local_54;
                          }
                          local_84 = *(int *)(iVar13 + 0x1834);
                          if ((iVar9 <= *(int *)(iVar13 + 0x1834)) &&
                             (local_84 = iVar6, iVar6 <= local_54)) {
                            local_84 = local_54;
                          }
                          local_7c = local_88;
                          puVar11 = (undefined4 *)FUN_00590ae0(local_c,(int *)(param_1 + 4));
                          uVar8 = FUN_005ee080(*puVar11,puVar11[1]);
                          local_88 = CONCAT22((short)((uint)uVar8 >> 0x10),
                                              (short)uVar8 - *(short *)(param_1 + 0x34));
                          iVar9 = **(int **)(param_1 + 0x188);
                          iVar10 = local_80;
                          iVar14 = local_7c;
                          iVar6 = local_68;
                          iVar16 = local_64;
                          iVar13 = local_60;
                          iVar1 = (*(int **)(param_1 + 0x188))[1];
                          while (local_70 = iVar1 + -1, local_68 = iVar6, iVar1 != 0) {
                            if (iVar9 == 0) {
                              iVar6 = 0xc80000;
                            }
                            else {
                              iVar6 = *(int *)(param_1 + 0xe4 +
                                              (*(int *)(iVar9 + 0x2c4) +
                                              *(int *)(iVar9 + 0x2b8) * 0xb) * 4);
                            }
                            local_60 = iVar13;
                            if ((iVar6 < 0x60000) &&
                               (uVar5 = (uint)(short)(*(short *)(param_1 + 0xb8 +
                                                                (*(int *)(iVar9 + 0x2c4) +
                                                                *(int *)(iVar9 + 0x2b8) * 0xb) * 2)
                                                     - (short)local_88), uVar15 = (int)uVar5 >> 0x1f
                               , (int)((uVar5 ^ uVar15) - uVar15) < 0xe3a)) {
                              iVar16 = 0;
                              local_70 = 0;
                            }
                            else {
                              uVar5 = *(int *)(iVar9 + 4) - local_84;
                              uVar15 = (int)uVar5 >> 0x1f;
                              if (((int)((uVar5 ^ uVar15) - uVar15) < iVar16) &&
                                 ((uVar5 = *(int *)(iVar9 + 8) - iVar10, uVar15 = (int)uVar5 >> 0x1f
                                  , (int)((uVar5 ^ uVar15) - uVar15) < iVar16 &&
                                  (uVar5 = *(int *)(iVar9 + 0xc) - iVar14,
                                  uVar15 = (int)uVar5 >> 0x1f,
                                  (int)((uVar5 ^ uVar15) - uVar15) < iVar16)))) {
                                bVar3 = true;
                              }
                              else {
                                bVar3 = false;
                              }
                              if (bVar3) {
                                FUN_00590aa0(local_84 - *(int *)(iVar9 + 4),
                                             iVar10 - *(int *)(iVar9 + 8),
                                             iVar14 - *(int *)(iVar9 + 0xc));
                                iVar13 = FUN_005b1260();
                                if (iVar13 <= iVar16) {
                                  FUN_00590aa0(local_84 - *(int *)(iVar9 + 4),
                                               local_80 - *(int *)(iVar9 + 8),
                                               local_7c - *(int *)(iVar9 + 0xc));
                                  iVar16 = FUN_005b1260();
                                }
                                iVar14 = local_7c;
                                iVar10 = local_80;
                                if (iVar16 < 0x70000) {
                                  local_70 = 0;
                                }
                              }
                            }
                            iVar9 = iVar9 + 0x3bc;
                            iVar6 = local_68;
                            iVar13 = local_60;
                            iVar1 = local_70;
                          }
                          local_70 = 0xffffffff;
                          if (local_78 < iVar16) {
                            iVar6 = iVar13;
                            local_94 = local_84;
                            local_90 = iVar10;
                            local_8c = iVar14;
                            local_78 = iVar16;
                            local_68 = iVar13;
                          }
                        }
                      }
                    }
                    else {
                      uVar5 = (int)*(uint *)(param_1 + 8) >> 0x1f;
                      uVar15 = (int)*(uint *)(iVar13 + 8) >> 0x1f;
                      if ((int)((*(uint *)(iVar13 + 8) ^ uVar15) - uVar15) <
                          (int)((*(uint *)(param_1 + 8) ^ uVar5) - uVar5)) {
                        if (param_1 == 0) {
                          iVar9 = 0xc80000;
                        }
                        else {
                          uVar5 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
                          uVar15 = (int)uVar5 >> 0x1f;
                          iVar9 = (uVar5 ^ uVar15) - uVar15;
                        }
                        if (iVar13 == 0) {
                          iVar10 = 0xc80000;
                        }
                        else {
                          uVar5 = *(int *)(iVar13 + 0x3a4) + *(int *)(iVar13 + 4);
                          uVar15 = (int)uVar5 >> 0x1f;
                          iVar10 = (uVar5 ^ uVar15) - uVar15;
                        }
                        if (iVar10 + -0xc0000 < iVar9) goto LAB_005b2495;
                      }
                    }
                  }
                  iVar13 = iVar13 + 0x3bc;
                  iVar9 = local_5c;
                }
                if (((iVar6 != 0) && (0x90000 < local_78)) &&
                   (*(int *)(param_1 + 0x180) < *(int *)(iVar6 + 0x17c))) {
                  cVar2 = FUN_0058fb50(&local_94);
                  if ((cVar2 == '\0') ||
                     (((-1 < local_94) - 1 & 0xfffffffe) + 1 ==
                      ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
                    bVar3 = false;
                  }
                  else {
                    bVar3 = true;
                  }
                  if ((bVar3) || (*(int *)(param_1 + 0x180) < 0xa0000)) {
                    iVar13 = FUN_005ec250();
                    uVar5 = *(int *)(iVar6 + 0x3a4) + *(int *)(iVar6 + 4);
                    uVar15 = (int)uVar5 >> 0x1f;
                    FUN_005b3a10(iVar6,1,(int)(iVar13 * 1000 + (iVar13 * 1000 >> 0x1f & 0x7fffU)) >>
                                         0xf < (int)((uVar5 ^ uVar15) - uVar15) / 0x28f);
                    goto LAB_005b293a;
                  }
                }
              }
            }
          }
        }
      }
    }
    else {
      local_95 = '\x01';
    }
  }
  if ((local_95 == '\0') && (*(int *)(param_1 + 0x180) < 0x20000)) {
    iVar13 = *(int *)(param_1 + 0x398);
    iVar6 = FUN_005ec250();
    if (((int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < (100 - iVar13) * 5) &&
       (cVar2 = FUN_005b3c10(500,0x2ee,100), cVar2 != '\0')) {
      iVar13 = FUN_005b31a0(0,1);
      if (iVar13 != 0) {
        FUN_005b3a10(iVar13,0,0);
        local_95 = '\x01';
      }
    }
  }
LAB_005b29c2:
  if (local_95 == '\0') {
    if (*(int *)(param_1 + 0x13c) == 1) {
      FUN_005b2f30();
    }
    switch(*(int *)(param_1 + 0x2c8) + -2) {
    case 0:
    case 1:
      cVar2 = FUN_005b41c0();
      return cVar2;
    case 2:
      cVar2 = FUN_005b4f70();
      return cVar2;
    case 3:
    case 4:
      cVar2 = FUN_005b3d00();
      return cVar2;
    case 5:
    case 9:
      cVar2 = thunk_FUN_005b41c0();
      return cVar2;
    case 6:
    case 0x10:
      cVar2 = thunk_FUN_005b41c0();
      return cVar2;
    case 7:
      cVar2 = FUN_005b3e50();
      return cVar2;
    case 8:
      cVar2 = FUN_005b5520();
      return cVar2;
    case 10:
    case 0xc:
      cVar2 = thunk_FUN_005b3e50();
      return cVar2;
    case 0xb:
    case 0xe:
    case 0xf:
      cVar2 = FUN_005b5150();
      return cVar2;
    case 0xd:
      local_95 = thunk_FUN_005b5520();
    }
  }
  return local_95;
}


