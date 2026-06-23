// FUN_005a65a0  entry=005a65a0  size=3193 bytes

void __thiscall FUN_005a65a0(int param_1,char param_2)

{
  byte *pbVar1;
  undefined1 uVar2;
  char cVar3;
  short sVar4;
  uint uVar5;
  int iVar6;
  undefined4 uVar7;
  undefined2 extraout_var;
  int *piVar8;
  int iVar9;
  undefined4 *puVar10;
  byte bVar11;
  uint uVar12;
  int iVar13;
  bool bVar14;
  int local_40;
  int local_3c;
  int local_38;
  int local_34;
  int local_30;
  int local_2c;
  int local_28;
  int local_24;
  int local_20;
  int local_1c;
  undefined1 local_18 [8];
  int local_10;
  undefined1 local_c [12];
  
  uVar2 = *(undefined1 *)(param_1 + 0x5c);
  if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
     (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
    bVar14 = false;
  }
  else {
    bVar14 = true;
  }
  if (((!bVar14) && (*(int *)(param_1 + 0x40) != 4)) && (*(int *)(param_1 + 0x40) != 0x25)) {
    if (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40)) {
      if (param_1 == 0) {
        iVar6 = 0xc80000;
      }
      else {
        uVar5 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
        uVar12 = (int)uVar5 >> 0x1f;
        iVar6 = (uVar5 ^ uVar12) - uVar12;
      }
      if (iVar6 < 0x280001) {
        if (param_1 == 0) {
          iVar6 = 0xc80000;
        }
        else {
          uVar5 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
          uVar12 = (int)uVar5 >> 0x1f;
          iVar6 = (uVar5 ^ uVar12) - uVar12;
        }
        if (iVar6 < 0x1a0001) {
          iVar6 = FUN_005ec250();
          *(int *)(param_1 + 0x54) = ((int)(iVar6 * 6 + (iVar6 * 6 >> 0x1f & 0x7fffU)) >> 0xf) + 10;
        }
        else {
          iVar6 = FUN_005ec250();
          *(int *)(param_1 + 0x54) = ((int)(iVar6 * 4 + (iVar6 * 4 >> 0x1f & 0x7fffU)) >> 0xf) + 0xc
          ;
        }
        goto LAB_005a6759;
      }
    }
    else {
      if (param_1 == 0) {
        iVar6 = 0xc80000;
      }
      else {
        uVar5 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
        uVar12 = (int)uVar5 >> 0x1f;
        iVar6 = (uVar5 ^ uVar12) - uVar12;
      }
      if (((0x13ffff < iVar6) ||
          (uVar5 = (int)*(uint *)(param_1 + 8) >> 0x1f,
          0xbffff < (int)((*(uint *)(param_1 + 8) ^ uVar5) - uVar5))) ||
         ((*(int *)(*(int *)(param_1 + 400) + 0x4c) != param_1 &&
          (iVar6 = FUN_005ec250(),
          299 < (int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf)))) {
        if (param_1 == 0) {
          iVar6 = 0xc80000;
        }
        else {
          uVar5 = *(int *)(param_1 + 4) - *(int *)(param_1 + 0x3a4);
          uVar12 = (int)uVar5 >> 0x1f;
          iVar6 = (uVar5 ^ uVar12) - uVar12;
        }
        if (((0x13ffff < iVar6) ||
            (uVar5 = (int)*(uint *)(param_1 + 8) >> 0x1f,
            0xbffff < (int)((*(uint *)(param_1 + 8) ^ uVar5) - uVar5))) ||
           (cVar3 = FUN_005b8c90(), cVar3 != '\0')) {
          *(undefined4 *)(param_1 + 0x58) = 0;
          *(undefined4 *)(param_1 + 0x54) = 0;
          goto LAB_005a6759;
        }
      }
    }
    iVar6 = FUN_005ec250();
    *(int *)(param_1 + 0x54) = ((int)(iVar6 * 2 + (iVar6 * 2 >> 0x1f & 0x7fffU)) >> 0xf) + 0xe;
  }
LAB_005a6759:
  iVar6 = *(int *)(param_1 + 0x18c);
  *(undefined1 *)(param_1 + 0x5c) = 0;
  bVar11 = *(byte *)(iVar6 + 0x461) & 0x40;
  if ((bVar11 == 0) ||
     (((iVar9 = *(int *)(param_1 + 0x40), iVar9 != 0x10 && (iVar9 != 0x11)) && (iVar9 != 0x35)))) {
    if ((bVar11 == 0) || (*(int *)(param_1 + 0x2b8) != *(int *)(*(int *)(iVar6 + 0x444) + 0x2b8))) {
      if (*(int *)(iVar6 + 0x19a0) != 4) {
        iVar9 = *(int *)(param_1 + 0x40);
        if ((iVar9 < 0) || (3 < iVar9)) {
          bVar14 = false;
        }
        else {
          bVar14 = true;
        }
        if (bVar14) {
          iVar13 = *(int *)(iVar6 + 0x448);
          if (((iVar13 == 0) || (iVar13 == 6)) && (*(int *)(param_1 + 0x48) == 0)) {
            if ((*(int *)(iVar6 + 0x440) == 0) || (iVar13 != 0)) {
              if (param_2 == '\0') {
                if ((iVar9 < 0) || (3 < iVar9)) {
                  bVar14 = false;
                }
                else {
                  bVar14 = true;
                }
                if ((!bVar14) || (cVar3 = FUN_005b1420(), cVar3 != '\0')) goto LAB_005a7208;
              }
              if (param_1 != *(int *)(*(int *)(param_1 + 400) + 0x40)) {
                FUN_005b0040();
                *(undefined1 *)(param_1 + 0x5c) = uVar2;
                return;
              }
              iVar6 = *(int *)(param_1 + 0x18c);
              if (*(char *)(param_1 + 99) == '\0') {
                iVar9 = *(int *)(iVar6 + 0x1820);
                if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(iVar6 + 0x19a0) & 1)) {
                  iVar9 = -iVar9;
                }
                FUN_00590aa0(iVar9,0,0);
                FUN_005a89c0(local_c,0x5a);
                *(undefined1 *)(param_1 + 0x5c) = uVar2;
                return;
              }
              iVar9 = *(int *)(iVar6 + 0x1820);
              if ((*(uint *)(iVar6 + 0x19a0) & 1) == *(uint *)(param_1 + 0x2b8)) {
                iVar9 = -iVar9;
              }
              FUN_00590aa0(iVar9,0,0);
              FUN_005a89c0(local_c,0x5a);
              iVar6 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
              if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == *(uint *)(param_1 + 0x2b8))
              {
                iVar6 = -iVar6;
              }
              FUN_00590aa0(iVar6,0,0);
              puVar10 = (undefined4 *)FUN_00590ae0(local_18,param_1 + 4);
              sVar4 = FUN_005ee080(*puVar10,puVar10[1]);
              if ((short)(sVar4 - *(short *)(param_1 + 0x34)) < 0x38e) {
                local_40 = 0;
                _param_2 = 0x12c0000;
                iVar13 = *(int *)(param_1 + 0x3a4) / 2;
                iVar6 = (*(int **)(param_1 + 0x184))[1];
                iVar9 = **(int **)(param_1 + 0x184);
                local_20 = iVar6 + -1;
                if (iVar6 != 0) {
                  piVar8 = (int *)(iVar9 + 8);
                  do {
                    if ((piVar8[0xad] != 0) && (iVar9 != param_1)) {
                      FUN_00590aa0(iVar13 - piVar8[-1],-*piVar8,-piVar8[1]);
                      iVar6 = FUN_005b1260();
                      if (iVar6 < _param_2) {
                        FUN_00590aa0(iVar13 - piVar8[-1],-*piVar8,-piVar8[1]);
                        _param_2 = FUN_005b1260();
                        local_40 = iVar9;
                      }
                    }
                    iVar9 = iVar9 + 0x3bc;
                    piVar8 = piVar8 + 0xef;
                    iVar6 = local_20 + -1;
                    bVar14 = local_20 != 0;
                    local_20 = iVar6;
                  } while (bVar14);
                }
                if (local_40 == 0) {
                  FUN_005aa4d0();
                  *(undefined1 *)(param_1 + 99) = 0;
                  *(undefined1 *)(param_1 + 0x5c) = uVar2;
                  return;
                }
                FUN_005aa490(local_40,0,0);
                *(undefined1 *)(param_1 + 99) = 0;
                *(undefined1 *)(param_1 + 0x5c) = uVar2;
                return;
              }
            }
            else {
              iVar9 = *(int *)(*(int *)(param_1 + 400) + 0x40);
              if (param_1 != iVar9) {
                if (iVar9 != 0) {
                  FUN_005a8f20(*(undefined2 *)(param_1 + 0x34));
                  *(undefined1 *)(param_1 + 0x5c) = uVar2;
                  return;
                }
                FUN_005b0040();
                *(undefined1 *)(param_1 + 0x5c) = uVar2;
                return;
              }
              local_24 = *(int *)(param_1 + 4);
              local_20 = *(int *)(iVar6 + 0x1824) *
                         (((-1 < *(int *)(param_1 + 8)) - 1 & 0xfffffffe) + 1);
              local_1c = 0;
              FUN_005a89c0(&local_24,0x5a);
              uVar5 = (uint)(short)(*(short *)(param_1 + 0x34) + -0x4000);
              uVar12 = (int)uVar5 >> 0x1f;
              if (((int)((uVar5 ^ uVar12) - uVar12) < 0x38e) ||
                 (uVar5 = (uint)(short)(*(short *)(param_1 + 0x34) + 0x4000),
                 uVar12 = (int)uVar5 >> 0x1f, (int)((uVar5 ^ uVar12) - uVar12) < 0x38e)) {
                FUN_005aa870(0);
                *(undefined1 *)(param_1 + 0x5c) = uVar2;
                return;
              }
            }
            goto LAB_005a7208;
          }
        }
      }
      iVar9 = *(int *)(iVar6 + 0x448);
      if ((((iVar9 == 2) && (param_1 == *(int *)(iVar6 + 0x438))) && (*(int *)(param_1 + 0x40) == 0)
          ) && (*(int *)(param_1 + 0x48) < 600)) {
        iVar6 = *(int *)(*(int *)(param_1 + 400) + 0x4c);
        if (iVar6 != 0) {
          FUN_005a8bc0(iVar6 + 4);
        }
        iVar6 = FUN_005ec250();
        if (((int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 0x32) ||
           (*(int *)(param_1 + 0x48) == 0)) {
          FUN_005aa4d0();
          *(undefined1 *)(param_1 + 0x5c) = uVar2;
          return;
        }
      }
      else if ((iVar9 == 3) && (param_1 == *(int *)(iVar6 + 0x438))) {
        iVar6 = FUN_005ec250();
        if ((int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 0x28) {
          *(undefined4 *)(param_1 + 0x48) = 0;
          *(undefined1 *)(param_1 + 0x5c) = uVar2;
          return;
        }
      }
      else if ((iVar9 == 4) && (param_1 == *(int *)(iVar6 + 0x438))) {
        local_24 = *(int *)(iVar6 + 0x1820) + -0xb0000;
        local_20 = 0;
        local_1c = 0;
        FUN_005a4510(local_c,*(undefined4 *)(param_1 + 0x2b8),&local_24);
        FUN_005a89c0(local_c,0x5a);
        local_20 = 0;
        local_24 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820) + -0xb0000;
        local_1c = 0;
        FUN_005a4510(&local_30,*(undefined4 *)(param_1 + 0x2b8),&local_24);
        FUN_00590aa0(local_30 - *(int *)(param_1 + 4),local_2c - *(int *)(param_1 + 8),
                     local_28 - *(int *)(param_1 + 0xc));
        sVar4 = FUN_005ee080(local_3c,local_38);
        if (((short)(sVar4 - *(short *)(param_1 + 0x34)) < 0xe39) &&
           (iVar6 = FUN_005ec250(),
           (int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 200)) {
          *(undefined4 *)(param_1 + 0x48) = 0;
          iVar6 = FUN_005ec250();
          *(int *)(param_1 + 0x58) = ((int)(iVar6 * 4 + (iVar6 * 4 >> 0x1f & 0x7fffU)) >> 0xf) + 0xc
          ;
          iVar6 = FUN_005ec250();
          *(undefined1 *)(param_1 + 0x5c) = uVar2;
          *(int *)(param_1 + 0x54) = ((int)(iVar6 * 6 + (iVar6 * 6 >> 0x1f & 0x7fffU)) >> 0xf) + 4;
          return;
        }
      }
      else if ((iVar9 == 5) && (param_1 == *(int *)(iVar6 + 0x438))) {
        iVar6 = FUN_005ec250();
        *(int *)(param_1 + 0x58) = (int)(iVar6 * 0x10 + (iVar6 * 0x10 >> 0x1f & 0x7fffU)) >> 0xf;
        iVar6 = FUN_005ec250();
        *(int *)(param_1 + 0x54) = ((int)(iVar6 * 3 + (iVar6 * 3 >> 0x1f & 0x7fffU)) >> 0xf) + 0xd;
      }
    }
    else {
      if ((((*(int *)(param_1 + 700) != 0) && (*(int *)(param_1 + 0x40) != 0xe)) &&
          (*(int *)(param_1 + 0x40) != 0xf)) &&
         (iVar6 = FUN_005ec250(),
         (int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 200)) {
        if ((*(int *)(param_1 + 0x2c0) != 0x26b7) ||
           (uVar7 = 0xf, *(int *)(*(int *)(param_1 + 0x18c) + 0x444) != param_1)) {
          uVar7 = 0xe;
        }
        FUN_005a5430(uVar7);
      }
      if ((param_1 == *(int *)(*(int *)(param_1 + 0x18c) + 0x444)) &&
         (*(int *)(param_1 + 0x48) == 0)) {
        FUN_00590aa0(*(int *)(param_1 + 0x1e0) - *(int *)(param_1 + 4),
                     *(int *)(param_1 + 0x1e4) - *(int *)(param_1 + 8),
                     *(int *)(param_1 + 0x1e8) - *(int *)(param_1 + 0xc));
        local_10 = local_34;
        if (((-1 < *(int *)(param_1 + 0x1e0)) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *(int *)(param_1 + 0x1e4)) - 1 & 0xfffffffe) + 1) {
          iVar6 = local_3c;
          iVar9 = -local_38;
        }
        else {
          iVar6 = -local_3c;
          iVar9 = local_38;
        }
        FUN_00590aa0(local_3c / 3,local_38 / 3,local_34 / 3);
        FUN_00590aa0(*(int *)(param_1 + 0x1e0) + local_30,*(int *)(param_1 + 0x1e4) + local_2c,
                     *(int *)(param_1 + 0x1e8) + local_28);
        FUN_00590aa0(local_24 + iVar9,local_20 + iVar6,local_1c + local_10);
        FUN_005a89c0(local_c,0x5a);
        uVar5 = *(int *)(param_1 + 4) - *(int *)(param_1 + 0x1e0);
        uVar12 = (int)uVar5 >> 0x1f;
        if ((((int)((uVar5 ^ uVar12) - uVar12) < 0x160000) &&
            (uVar5 = *(int *)(param_1 + 8) - *(int *)(param_1 + 0x1e4), uVar12 = (int)uVar5 >> 0x1f,
            (int)((uVar5 ^ uVar12) - uVar12) < 0x160000)) &&
           (uVar5 = *(int *)(param_1 + 0xc) - *(int *)(param_1 + 0x1e8), uVar12 = (int)uVar5 >> 0x1f
           , (int)((uVar5 ^ uVar12) - uVar12) < 0x160000)) {
          bVar14 = true;
        }
        else {
          bVar14 = false;
        }
        if (bVar14) {
          pbVar1 = (byte *)(*(int *)(param_1 + 0x18c) + 0x461);
          *pbVar1 = *pbVar1 & 0x7f;
        }
        uVar5 = *(int *)(param_1 + 4) - *(int *)(param_1 + 0x1e0);
        uVar12 = (int)uVar5 >> 0x1f;
        if ((((int)((uVar5 ^ uVar12) - uVar12) < 0x40000) &&
            (uVar5 = *(int *)(param_1 + 8) - *(int *)(param_1 + 0x1e4), uVar12 = (int)uVar5 >> 0x1f,
            (int)((uVar5 ^ uVar12) - uVar12) < 0x40000)) &&
           (uVar5 = *(int *)(param_1 + 0xc) - *(int *)(param_1 + 0x1e8), uVar12 = (int)uVar5 >> 0x1f
           , (int)((uVar5 ^ uVar12) - uVar12) < 0x40000)) {
          bVar14 = true;
        }
        else {
          bVar14 = false;
        }
        if ((bVar14) &&
           (iVar6 = FUN_005ec250(),
           (int)(iVar6 * 0x32 + (iVar6 * 0x32 >> 0x1f & 0x7fffU)) >> 0xf != 0)) {
          if (*(int *)(param_1 + 700) == 0) {
            FUN_005a5430(0x35);
            *(undefined1 *)(param_1 + 0x5c) = uVar2;
            return;
          }
          iVar6 = FUN_005ec250();
          FUN_005a5430(0x11 - (uint)((int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf <
                                    500));
          if (*(int *)(param_1 + 0x40) == 0x11) {
            piVar8 = (int *)FUN_005ee0f0(0x38000,CONCAT22(extraout_var,
                                                          *(undefined2 *)(param_1 + 0x34)));
            local_1c = piVar8[2] + *(int *)(param_1 + 0xc);
            local_20 = piVar8[1] + *(int *)(param_1 + 8);
            local_24 = *(int *)(param_1 + 4) + *piVar8;
            FUN_005a7220(0,0x30,&local_24,
                         CONCAT22((short)((uint)local_1c >> 0x10),*(undefined2 *)(param_1 + 0x34)));
            *(undefined1 *)(param_1 + 0x5c) = uVar2;
            return;
          }
        }
      }
      else if (*(int *)(param_1 + 700) != 0) {
        FUN_00590ae0(local_c,param_1 + 4);
        iVar6 = FUN_005b1260();
        if (0x6ffff < iVar6) {
          FUN_00590ae0(local_c,param_1 + 4);
          iVar6 = FUN_005b1260();
          if (iVar6 < 0x320001) {
            FUN_005a89c0(*(int *)(*(int *)(param_1 + 0x18c) + 0x444) + 0x1e0,0x5a);
            *(undefined1 *)(param_1 + 0x5c) = uVar2;
            return;
          }
        }
        FUN_005a5430(0);
        *(undefined1 *)(param_1 + 0x5c) = uVar2;
        return;
      }
    }
  }
  else if (*(int *)(param_1 + 0x2c) == (&DAT_00664fb8)[iVar9] + -1) {
    *(undefined4 *)(param_1 + 0x30) = 0;
    if (iVar9 == 0x35) {
      FUN_005a5430(0x1e);
    }
    *(undefined4 *)(param_1 + 0x48) = 0xe10;
    *(undefined1 *)(param_1 + 0x5c) = uVar2;
    return;
  }
LAB_005a7208:
  *(undefined1 *)(param_1 + 0x5c) = uVar2;
  return;
}


