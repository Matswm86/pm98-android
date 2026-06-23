// FUN_005ad010  entry=005ad010  size=2391 bytes

void __fastcall FUN_005ad010(int param_1)

{
  int *piVar1;
  byte *pbVar2;
  bool bVar3;
  char cVar4;
  short sVar5;
  short sVar6;
  int iVar7;
  int iVar8;
  int *piVar9;
  uint uVar10;
  undefined4 uVar11;
  int iVar12;
  int extraout_ECX;
  uint uVar14;
  uint uVar15;
  int iVar16;
  int local_18;
  int local_14;
  int local_10;
  undefined4 local_c;
  uint local_8;
  undefined2 uVar13;
  
  if ((*(int *)(param_1 + 0x2c) == 3) && (*(int *)(param_1 + 0x30) == 3)) {
    bVar3 = true;
  }
  else {
    bVar3 = false;
  }
  if (!bVar3) {
    return;
  }
  *(undefined4 *)(*(int *)(param_1 + 400) + 0x4c) = 0;
  if (*(int *)(param_1 + 0x54) < 0xe) {
    cVar4 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180a);
  }
  else {
    if (*(char *)(param_1 + 0x5e) == '\0') {
      local_18 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
      local_14 = 0;
      local_10 = 0;
      sVar5 = FUN_005aac00(&local_18);
      uVar10 = (int)sVar5 >> 0x1f;
      if ((int)(((int)sVar5 ^ uVar10) - uVar10) < 0x4000) {
        if (param_1 == 0) {
          iVar7 = 0xc80000;
        }
        else {
          uVar10 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
          uVar15 = (int)uVar10 >> 0x1f;
          iVar7 = (uVar10 ^ uVar15) - uVar15;
        }
        if (0x1e0000 < iVar7) {
          if (param_1 == 0) {
            iVar7 = 0xc80000;
          }
          else {
            uVar10 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
            uVar15 = (int)uVar10 >> 0x1f;
            iVar7 = (uVar10 ^ uVar15) - uVar15;
          }
          if ((int)(iVar7 + -0x1e0000 + (iVar7 + -0x1e0000 >> 0x1f & 0x7ffffU)) >> 0x13 < 6) {
            if (param_1 == 0) {
              iVar7 = 0xc80000;
            }
            else {
              uVar10 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
              uVar15 = (int)uVar10 >> 0x1f;
              iVar7 = (uVar10 ^ uVar15) - uVar15;
            }
            iVar7 = (int)(iVar7 + -0x1e0000 + (iVar7 + -0x1e0000 >> 0x1f & 0x7ffffU)) >> 0x13;
          }
          else {
            iVar7 = 5;
          }
          *(int *)(param_1 + 0x54) = *(int *)(param_1 + 0x54) + iVar7;
        }
      }
    }
    cVar4 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180a);
  }
  if (cVar4 != '\0') {
    FUN_00590f00();
  }
  if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
     (cVar4 = FUN_005943b0(), cVar4 == '\0')) {
    bVar3 = false;
  }
  else {
    bVar3 = true;
  }
  if ((bVar3) && (*(char *)(param_1 + 0x5c) != '\0')) {
    bVar3 = true;
  }
  else {
    bVar3 = false;
  }
  if (bVar3) {
    *(bool *)(param_1 + 0x5e) = *(int *)(param_1 + 0x58) != 0;
  }
  else {
    if (param_1 == 0) {
      iVar7 = 0xc80000;
    }
    else {
      uVar10 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
      uVar15 = (int)uVar10 >> 0x1f;
      iVar7 = (uVar10 ^ uVar15) - uVar15;
    }
    iVar8 = FUN_005ec250();
    bVar3 = (int)(iVar8 * 1000 + (iVar8 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < (iVar7 * 500) / 0x3c0000
    ;
    *(bool *)(param_1 + 0x5e) = bVar3;
    if (bVar3) {
      if (param_1 == 0) {
        iVar7 = 0xc80000;
      }
      else {
        uVar10 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
        uVar15 = (int)uVar10 >> 0x1f;
        iVar7 = (uVar10 ^ uVar15) - uVar15;
      }
      iVar7 = (iVar7 * 10) / 0x3c0000;
      if (iVar7 < 0x8000) {
        iVar8 = FUN_005ec250();
        iVar7 = (int)(iVar8 * iVar7 + (iVar8 * iVar7 >> 0x1f & 0x7fffU)) >> 0xf;
      }
      else {
        iVar8 = FUN_005ec250();
        iVar8 = ((int)(iVar7 + (iVar7 >> 0x1f & 0xffU)) >> 8) * iVar8;
        iVar7 = (int)(iVar8 + (iVar8 >> 0x1f & 0x7fU)) >> 7;
      }
      *(int *)(param_1 + 0x58) = iVar7 + 4;
    }
  }
  if (*(int *)(param_1 + 700) == 0) {
    piVar1 = (int *)(param_1 + 4);
    cVar4 = FUN_0059a120(piVar1);
    if (cVar4 == '\0') goto LAB_005ad535;
    *(undefined1 *)(param_1 + 0x5e) = 1;
    if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
       (cVar4 = FUN_005943b0(), cVar4 == '\0')) {
      bVar3 = false;
    }
    else {
      bVar3 = true;
    }
    if ((bVar3) && (*(char *)(param_1 + 0x5c) != '\0')) {
      bVar3 = true;
    }
    else {
      bVar3 = false;
    }
    if (bVar3) {
      uVar14 = *(int *)(param_1 + 0x58) >> 0x1f;
      *(int *)(param_1 + 0x58) = *(int *)(param_1 + 0x58) / 2 + 8;
    }
    else {
      iVar16 = 0;
      iVar8 = 0x3e80000;
      iVar7 = FUN_005ec250();
      *(int *)(param_1 + 0x58) = ((int)(iVar7 * 4 + (iVar7 * 4 >> 0x1f & 0x7fffU)) >> 0xf) + 0xc;
      iVar7 = FUN_005ec250();
      *(int *)(param_1 + 0x54) = ((int)(iVar7 * 2 + (iVar7 * 2 >> 0x1f & 0x7fffU)) >> 0xf) + 0xe;
      uVar15 = (*(int **)(param_1 + 0x188))[1];
      iVar7 = **(int **)(param_1 + 0x188);
      uVar10 = uVar15 - 1;
      uVar14 = uVar10;
      while (local_8 = uVar10, uVar15 != 0) {
        if (iVar7 == 0) {
          iVar12 = 0xc80000;
        }
        else {
          iVar12 = *(int *)(param_1 + 0xe4 +
                           (*(int *)(iVar7 + 0x2b8) * 0xb + *(int *)(iVar7 + 0x2c4)) * 4);
        }
        if (iVar12 < iVar8) {
          iVar16 = iVar7;
          if (iVar7 == 0) {
            iVar8 = 0xc80000;
          }
          else {
            iVar8 = *(int *)(param_1 + 0xe4 +
                            (*(int *)(iVar7 + 0x2b8) * 0xb + *(int *)(iVar7 + 0x2c4)) * 4);
          }
        }
        iVar7 = iVar7 + 0x3bc;
        uVar10 = local_8 - 1;
        uVar14 = local_8;
        uVar15 = local_8;
      }
      if (iVar16 != 0) {
        if (*(short *)(param_1 + 0xb8 +
                      (*(int *)(iVar16 + 0x2b8) * 0xb + *(int *)(iVar16 + 0x2c4)) * 2) < 0) {
          iVar7 = FUN_005ec250();
          uVar14 = iVar7 * 0x222 >> 0x1f & 0x7fff;
          *(short *)(param_1 + 0x34) =
               *(short *)(param_1 + 0x34) + (-0x222 - (short)((int)(iVar7 * 0x222 + uVar14) >> 0xf))
          ;
        }
        else {
          iVar7 = FUN_005ec250();
          uVar14 = iVar7 * 0x222 >> 0x1f & 0x7fff;
          *(short *)(param_1 + 0x34) =
               *(short *)(param_1 + 0x34) + (short)((int)(iVar7 * 0x222 + uVar14) >> 0xf) + 0x222;
        }
      }
    }
    iVar7 = *(int *)(param_1 + 0x54) * 0x120000;
    FUN_005ee0f0(((int)(iVar7 + (iVar7 >> 0x1f & 0xfU)) >> 4) + 0x120000,
                 CONCAT22((short)(uVar14 >> 0x10),*(undefined2 *)(param_1 + 0x34)));
    *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + local_14;
    *piVar1 = *piVar1 + local_18;
    *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + local_10;
    iVar7 = FUN_005b1100(*(undefined4 *)(param_1 + 0x184),*(undefined2 *)(param_1 + 0x34),0x1e0000,
                         0xa0000);
    *piVar1 = *piVar1 - local_18;
    *(int *)(param_1 + 8) = *(int *)(param_1 + 8) - local_14;
    *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) - local_10;
    if (iVar7 == 0) {
      iVar7 = *(int *)(param_1 + 0x54) * 0xe0000;
      iVar7 = iVar7 + (iVar7 >> 0x1f & 0xfU);
      uVar11 = CONCAT22((short)((uint)iVar7 >> 0x10),*(undefined2 *)(param_1 + 0x34));
      iVar8 = FUN_005ec250(uVar11);
      piVar9 = (int *)FUN_005ee0f0(((int)(iVar8 * 0x800 + (iVar8 * 0x800 >> 0x1f & 0x7fU)) >> 7) +
                                   (iVar7 >> 4) + 0x120000,uVar11);
      iVar7 = piVar9[1];
      iVar8 = piVar9[2];
      *(int *)(param_1 + 0xa0) = *piVar1 + *piVar9;
      *(int *)(param_1 + 0xa4) = iVar7 + *(int *)(param_1 + 8);
      *(int *)(param_1 + 0xa8) = iVar8 + *(int *)(param_1 + 0xc);
      goto LAB_005ad75c;
    }
LAB_005ad73a:
    *(undefined4 *)(param_1 + 0xa0) = *(undefined4 *)(iVar7 + 4);
    *(undefined4 *)(param_1 + 0xa4) = *(undefined4 *)(iVar7 + 8);
    *(undefined4 *)(param_1 + 0xa8) = *(undefined4 *)(iVar7 + 0xc);
    *(int *)(*(int *)(param_1 + 400) + 0x4c) = iVar7;
  }
  else {
LAB_005ad535:
    iVar7 = *(int *)(param_1 + 0x18c);
    if (*(int *)(iVar7 + 0x44c) == 4) {
      if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
         (cVar4 = FUN_005943b0(), cVar4 == '\0')) {
        bVar3 = false;
      }
      else {
        bVar3 = true;
      }
      if ((bVar3) && (*(char *)(param_1 + 0x5c) != '\0')) {
        iVar7 = 1;
      }
      else {
        iVar7 = 0;
      }
      if ((char)iVar7 == '\0') {
        *(undefined1 *)(param_1 + 0x5e) = 1;
        iVar7 = FUN_005ec250();
        *(int *)(param_1 + 0x58) = ((int)(iVar7 * 6 + (iVar7 * 6 >> 0x1f & 0x7fffU)) >> 0xf) + 0xc;
        iVar7 = FUN_005ec250();
        iVar7 = ((int)(iVar7 * 3 + (iVar7 * 3 >> 0x1f & 0x7fffU)) >> 0xf) + 0xd;
        *(int *)(param_1 + 0x54) = iVar7;
      }
      if (*(int *)(param_1 + 0x58) != 0) {
        iVar8 = *(int *)(param_1 + 0x54) * 0x190000;
        FUN_005ee0f0(((int)(iVar8 + (iVar8 >> 0x1f & 0xfU)) >> 4) + 0xf0000,
                     CONCAT22((short)((uint)iVar7 >> 0x10),*(undefined2 *)(param_1 + 0x34)));
        iVar7 = *(int *)(param_1 + 0xc) + local_10;
        *(int *)(param_1 + 4) = *(int *)(param_1 + 4) + local_18;
        *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + local_14;
        *(int *)(param_1 + 0xc) = iVar7;
        iVar7 = FUN_005b1100(*(undefined4 *)(param_1 + 0x184),
                             CONCAT22((short)((uint)iVar7 >> 0x10),*(undefined2 *)(param_1 + 0x34)),
                             0x460000,0x80000);
        iVar8 = *(int *)(param_1 + 0xc) - local_10;
        *(int *)(param_1 + 4) = *(int *)(param_1 + 4) - local_18;
        *(int *)(param_1 + 8) = *(int *)(param_1 + 8) - local_14;
        *(int *)(param_1 + 0xc) = iVar8;
        if (iVar7 == 0) {
          iVar7 = FUN_005b1100(*(undefined4 *)(param_1 + 0x184),
                               CONCAT22((short)((uint)iVar8 >> 0x10),*(undefined2 *)(param_1 + 0x34)
                                       ),0x460000,0xf0000);
joined_r0x005ad738:
          if (iVar7 != 0) goto LAB_005ad73a;
        }
        else {
          *(undefined4 *)(param_1 + 0xa0) = *(undefined4 *)(iVar7 + 4);
          *(undefined4 *)(param_1 + 0xa4) = *(undefined4 *)(iVar7 + 8);
          *(undefined4 *)(param_1 + 0xa8) = *(undefined4 *)(iVar7 + 0xc);
          *(int *)(*(int *)(param_1 + 400) + 0x4c) = iVar7;
        }
      }
    }
    else {
      if (*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') {
LAB_005ad6c8:
        uVar13 = (undefined2)((uint)iVar7 >> 0x10);
        bVar3 = false;
      }
      else {
        cVar4 = FUN_005943b0();
        uVar13 = (undefined2)((uint)extraout_ECX >> 0x10);
        iVar7 = extraout_ECX;
        if (cVar4 == '\0') goto LAB_005ad6c8;
        bVar3 = true;
      }
      if ((bVar3) && (*(char *)(param_1 + 0x5c) != '\0')) {
        bVar3 = true;
      }
      else {
        bVar3 = false;
      }
      if ((!bVar3) && (*(int *)(*(int *)(param_1 + 0x18c) + 0x44c) == 5)) {
        if (*(int *)(*(int *)(param_1 + 0x18c) + 0x19cc) == 0) {
          iVar7 = FUN_005b1100(*(undefined4 *)(param_1 + 0x184),
                               CONCAT22(uVar13,*(undefined2 *)(param_1 + 0x34)),0x190000,0xf0000);
          goto joined_r0x005ad738;
        }
        iVar7 = FUN_005ec250();
        *(undefined1 *)(param_1 + 0x5e) = 1;
        *(int *)(param_1 + 0x58) = ((int)(iVar7 * 8 + (iVar7 * 8 >> 0x1f & 0x7fffU)) >> 0xf) + 4;
      }
    }
  }
LAB_005ad75c:
  if ((*(char *)(param_1 + 0x5e) != '\0') && (*(int *)(*(int *)(param_1 + 400) + 0x4c) == 0)) {
    if (*(int *)(param_1 + 700) == 0) {
      cVar4 = FUN_0058fb50((int *)(param_1 + 4));
      if ((cVar4 == '\0') ||
         (((-1 < *(int *)(param_1 + 4)) - 1 & 0xfffffffe) + 1 !=
          ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
        bVar3 = false;
      }
      else {
        bVar3 = true;
      }
      if (bVar3) goto LAB_005ad94b;
    }
    if (param_1 == 0) {
      iVar7 = 0xc80000;
    }
    else {
      uVar10 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
      uVar15 = (int)uVar10 >> 0x1f;
      iVar7 = (uVar10 ^ uVar15) - uVar15;
    }
    piVar1 = (int *)(param_1 + 0xa0);
    *piVar1 = *(int *)(param_1 + 0xa0) - *(int *)(param_1 + 4);
    *(int *)(param_1 + 0xa4) = *(int *)(param_1 + 0xa4) - *(int *)(param_1 + 8);
    *(int *)(param_1 + 0xa8) = *(int *)(param_1 + 0xa8) - *(int *)(param_1 + 0xc);
    iVar8 = *(int *)(param_1 + 0x58) * 0x8000;
    FUN_005ee1c0(0x10000 - ((int)(iVar8 + (iVar8 >> 0x1f & 0xfU)) >> 4));
    iVar8 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
    if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1)) {
      iVar8 = -iVar8;
    }
    FUN_00590aa0(iVar8 - *(int *)(param_1 + 4),-*(int *)(param_1 + 8),-*(int *)(param_1 + 0xc));
    sVar5 = FUN_005ee080(local_c,local_8);
    FUN_00590aa0(*piVar1 - *(int *)(param_1 + 4),*(int *)(param_1 + 0xa4) - *(int *)(param_1 + 8),
                 *(int *)(param_1 + 0xa8) - *(int *)(param_1 + 0xc));
    sVar6 = FUN_005ee080(local_18,local_14);
    uVar10 = (int)(short)(sVar6 - sVar5) >> 0x1f;
    if ((int)(((int)(short)(sVar6 - sVar5) ^ uVar10) - uVar10) < 0x2000) {
      uVar11 = FUN_005ee080(*piVar1,*(undefined4 *)(param_1 + 0xa4));
      piVar9 = (int *)FUN_005ee0f0(iVar7,uVar11);
      *piVar1 = *piVar1 + *piVar9;
      *(int *)(param_1 + 0xa4) = *(int *)(param_1 + 0xa4) + piVar9[1];
      *(int *)(param_1 + 0xa8) = *(int *)(param_1 + 0xa8) + piVar9[2];
      *piVar1 = *piVar1 / 2;
      *(int *)(param_1 + 0xa4) = *(int *)(param_1 + 0xa4) / 2;
      *(int *)(param_1 + 0xa8) = *(int *)(param_1 + 0xa8) / 2;
    }
    *piVar1 = *piVar1 + *(int *)(param_1 + 4);
    *(int *)(param_1 + 0xa4) = *(int *)(param_1 + 0xa4) + *(int *)(param_1 + 8);
    *(int *)(param_1 + 0xa8) = *(int *)(param_1 + 0xa8) + *(int *)(param_1 + 0xc);
  }
LAB_005ad94b:
  FUN_005ac1a0();
  pbVar2 = (byte *)(*(int *)(param_1 + 0x18c) + 0x462);
  *pbVar2 = *pbVar2 | 0x80;
  return;
}


