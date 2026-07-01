// FUN_005a4600  entry=005a4600  size=2632 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __fastcall FUN_005a4600(int param_1)

{
  byte *pbVar1;
  int iVar2;
  int iVar3;
  bool bVar4;
  undefined1 uVar5;
  char cVar6;
  short sVar7;
  int iVar8;
  uint uVar9;
  int iVar10;
  int *piVar11;
  uint uVar12;
  int iVar13;
  uint *puVar14;
  int iVar15;
  int iVar16;
  bool bVar17;
  int iStack_38;
  int iStack_34;
  int iStack_20;
  
  FUN_00606220();
  *(undefined1 *)(param_1 + 0x2d7) = 0;
  if ((((-1 < *(int *)(param_1 + 4)) - 1 & 0xfffffffe) + 1 ==
       ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1) ||
     (iVar8 = FUN_005b0b40(0xfffe0000), 1 < iVar8)) {
    uVar5 = 0;
  }
  else {
    uVar5 = 1;
  }
  *(undefined1 *)(param_1 + 0x2d8) = uVar5;
  uVar9 = *(int *)(param_1 + 0x88) + 1U & 0xf;
  *(uint *)(param_1 + 0x88) = uVar9;
  if (uVar9 == 0) {
    iVar8 = *(int *)(param_1 + 0x68);
    if (iVar8 < 0x777) {
      iVar8 = *(int *)(param_1 + 0x74);
      if (*(int *)(param_1 + 0x70) < iVar8) {
        iVar10 = (*(int *)(param_1 + 0x78) * 5) / 2 + *(int *)(param_1 + 0x70);
        if (iVar10 < iVar8) {
          iVar8 = iVar10;
        }
LAB_005a46d4:
        *(int *)(param_1 + 0x70) = iVar8;
      }
    }
    else if (iVar8 < 0x1334) {
      if (0xd55 < iVar8) {
        if (*(int *)(param_1 + 0x78) < *(int *)(param_1 + 0x70)) {
          iVar8 = *(int *)(param_1 + 0x70) - *(int *)(param_1 + 0x78) / 2;
          goto LAB_005a46d4;
        }
      }
    }
    else if (*(int *)(param_1 + 0x78) < *(int *)(param_1 + 0x70)) {
      *(int *)(param_1 + 0x70) = *(int *)(param_1 + 0x70) - *(int *)(param_1 + 0x78);
    }
    if (*(int *)(param_1 + 0x70) < (*(int *)(param_1 + 0x74) * 4) / 5) {
      uVar9 = *(int *)(param_1 + 0x74) -
              (int)(72000 / (longlong)*(int *)(*(int *)(param_1 + 0x18c) + 0x19ac));
      *(uint *)(param_1 + 0x74) = ((int)uVar9 < 0) - 1 & uVar9;
    }
  }
  FUN_005a50c0();
  *(undefined4 *)(param_1 + 0x6c) = 0;
  if (((*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 0) && (DAT_006d31c4 == '\0')) &&
     (*(int *)(param_1 + 0x50) = *(int *)(param_1 + 0x50) + 1,
     param_1 == *(int *)(*(int *)(param_1 + 400) + 0x44))) {
    *(int *)(param_1 + 0x4c) = *(int *)(param_1 + 0x4c) + 1;
    *(int *)(*(int *)(param_1 + 0x184) + 0x2e8) = *(int *)(*(int *)(param_1 + 0x184) + 0x2e8) + 1;
  }
  switch(*(int *)(param_1 + 0x40)) {
  case 4:
  case 0x25:
    FUN_005acc40();
    break;
  case 5:
  case 0x24:
    FUN_005ad010();
    break;
  case 6:
  case 7:
    if ((*(int *)(param_1 + 0x2c) == (&DAT_00664fb8)[*(int *)(param_1 + 0x40)] + -1) &&
       (*(int *)(param_1 + 0x30) == 0)) {
      bVar17 = true;
    }
    else {
      bVar17 = false;
    }
    if (bVar17) {
      if (*(int *)(param_1 + 0x48) == 0) {
        if (*(int *)(*(int *)(param_1 + 0x18c) + 0x440) == param_1) {
          *(undefined4 *)(param_1 + 0x48) = 5000;
        }
        else {
          iVar8 = (0x78 - *(int *)(param_1 + 0x380)) * 2;
          if (iVar8 < 0x8000) {
            iVar10 = FUN_005ec250();
            *(int *)(param_1 + 0x48) =
                 ((int)(iVar10 * iVar8 + (iVar10 * iVar8 >> 0x1f & 0x7fffU)) >> 0xf) + 0x1e;
          }
          else {
            iVar10 = FUN_005ec250();
            iVar10 = ((int)(iVar8 + (iVar8 >> 0x1f & 0xffU)) >> 8) * iVar10;
            *(int *)(param_1 + 0x48) = ((int)(iVar10 + (iVar10 >> 0x1f & 0x7fU)) >> 7) + 0x1e;
          }
        }
      }
      else if (*(int *)(param_1 + 0x48) < 10) {
        pbVar1 = (byte *)(*(int *)(param_1 + 0x18c) + 0x461);
        *pbVar1 = *pbVar1 & 0xf7;
      }
    }
    break;
  case 8:
  case 9:
    FUN_005aeda0();
    break;
  case 0x13:
    if ((*(int *)(param_1 + 0x48) == 0) && (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 3)) {
      FUN_005942e0(1);
    }
    if ((*(int *)(param_1 + 0x2c) == 5) && (*(int *)(param_1 + 0x30) == 0)) {
      bVar17 = true;
    }
    else {
      bVar17 = false;
    }
    if (bVar17) {
      iVar8 = *(int *)(param_1 + 0x58) * 0x280000;
      piVar11 = (int *)FUN_005ee0f0((int)(iVar8 + (iVar8 >> 0x1f & 0xfU)) >> 4,
                                    *(undefined2 *)(param_1 + 0x34));
      iVar8 = *piVar11;
      iVar10 = *(int *)(param_1 + 4);
      iVar2 = piVar11[1];
      iStack_38 = 0x1f40000;
      iVar3 = *(int *)(param_1 + 8);
      iVar13 = **(int **)(param_1 + 0x184);
      iVar15 = (*(int **)(param_1 + 0x184))[1];
      iStack_20 = iVar15 + -1;
      iStack_34 = 0;
      iVar16 = 0;
      if (iVar15 != 0) {
        do {
          if ((iVar13 != param_1) && (*(int *)(iVar13 + 700) != 0)) {
            iVar16 = *(int *)(iVar13 + 4) - (iVar8 + iVar10);
            iVar15 = *(int *)(iVar13 + 8) - (iVar3 + iVar2);
            sVar7 = FUN_005ee080(iVar16,iVar15);
            iVar15 = FUN_005edfb0(iVar16,*(undefined4 *)
                                          (&DAT_006d31c8 + (sVar7 + 8 >> 4 & 0xfffU) * 4),iVar15,
                                  *(undefined4 *)
                                   (&DAT_006d31c8 + (0x3ff8 - sVar7 >> 4 & 0xfffU) * 4));
            if (iVar15 < iStack_38) {
              iStack_38 = iVar15;
              iStack_34 = iVar13;
            }
          }
          iVar13 = iVar13 + 0x3bc;
          bVar17 = iStack_20 != 0;
          iStack_20 = iStack_20 + -1;
        } while (bVar17);
        iStack_20 = -1;
        iVar16 = iStack_34;
      }
      if (iVar16 != 0) {
        *(int *)(*(int *)(param_1 + 400) + 0x4c) = iVar16;
        *(undefined4 *)(param_1 + 0xa0) = *(undefined4 *)(iVar16 + 4);
        iStack_20 = *(int *)(iVar16 + 8);
        *(int *)(param_1 + 0xa4) = iStack_20;
        *(undefined4 *)(param_1 + 0xa8) = *(undefined4 *)(iVar16 + 0xc);
      }
      *(undefined4 *)(param_1 + 0xb4) = 0;
      piVar11 = (int *)FUN_005ee0f0(0x8000,CONCAT22((short)((uint)iStack_20 >> 0x10),
                                                    *(undefined2 *)(param_1 + 0x34)));
      iVar8 = piVar11[1];
      iVar10 = piVar11[2];
      iVar2 = *(int *)(param_1 + 8);
      iVar3 = *(int *)(param_1 + 0xc);
      iVar13 = *(int *)(param_1 + 400);
      *(int *)(iVar13 + 4) = *piVar11 + *(int *)(param_1 + 4);
      *(int *)(iVar13 + 8) = iVar2 + iVar8;
      *(int *)(iVar13 + 0xc) = iVar10 + iVar3;
      *(undefined4 *)(*(int *)(param_1 + 400) + 0xc) = 0x15c28;
      FUN_005ac1a0();
    }
    break;
  case 0x14:
  case 0x16:
    FUN_005ae4c0();
    break;
  case 0x15:
    FUN_005ae910();
    break;
  case 0x19:
  case 0x1a:
    FUN_005adfc0();
    break;
  case 0x1c:
    iVar8 = *(int *)(param_1 + 400);
    if (((*(int *)(iVar8 + 0x20) == 0) && (*(int *)(iVar8 + 0x24) == 0)) &&
       (*(int *)(iVar8 + 0x28) == 0)) {
      bVar17 = true;
    }
    else {
      bVar17 = false;
    }
    if ((!bVar17) &&
       (iVar8 = FUN_005ec250(), (int)(iVar8 * 1000 + (iVar8 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 100)
       ) {
      FUN_005a5430(0);
    }
    break;
  case 0x1f:
  case 0x21:
    iVar8 = *(int *)(param_1 + 400);
    *(undefined4 *)(iVar8 + 0x20) = 0;
    *(undefined4 *)(iVar8 + 0x24) = 0;
    *(undefined4 *)(iVar8 + 0x28) = 0;
    _DAT_00665154 = DAT_00665158;
    _DAT_0066502c = DAT_00665030;
    _DAT_0067455c = DAT_00674560;
    break;
  case 0x36:
    FUN_005ad970();
    break;
  case 0x37:
    FUN_005adc60();
  }
  puVar14 = (uint *)(param_1 + 4);
  if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
     (cVar6 = FUN_005943b0(), cVar6 == '\0')) {
    bVar17 = false;
  }
  else {
    bVar17 = true;
  }
  if ((bVar17) && (*(char *)(param_1 + 0x5c) != '\0')) {
    bVar17 = true;
  }
  else {
    bVar17 = false;
  }
  if (bVar17) {
    if (*(char *)(*(int *)(param_1 + 0x184) + 0x214) != '\0') {
      iVar8 = *(int *)(param_1 + 0x58) + 1;
      if (0xf < iVar8) {
        iVar8 = 0x10;
      }
      *(int *)(param_1 + 0x58) = iVar8;
    }
    if (*(char *)(*(int *)(param_1 + 0x184) + 0x215) != '\0') {
      iVar8 = *(int *)(param_1 + 0x54) + 1;
      if (0xf < iVar8) {
        iVar8 = 0x10;
      }
      *(int *)(param_1 + 0x54) = iVar8;
    }
  }
  if (*(int *)(param_1 + 0x80) != 0) {
    *(int *)(param_1 + 0x80) = *(int *)(param_1 + 0x80) + -1;
  }
  if ((*(int *)(param_1 + 0x80) == 0) && (iVar8 = *(int *)(param_1 + 0x84), iVar8 != 0)) {
    *(int *)(param_1 + 0x84) = iVar8 + -1;
    *(short *)(param_1 + 0x34) =
         (short)((int)(short)(*(short *)(param_1 + 0x66) - *(short *)(param_1 + 0x34)) / iVar8) +
         *(short *)(param_1 + 0x34);
    *(int *)(param_1 + 8) =
         *(int *)(param_1 + 8) + (*(int *)(param_1 + 0x98) - *(int *)(param_1 + 8)) / iVar8;
    *puVar14 = *puVar14 + (int)(*(int *)(param_1 + 0x94) - *puVar14) / iVar8;
    *(int *)(param_1 + 0xc) =
         *(int *)(param_1 + 0xc) + (*(int *)(param_1 + 0x9c) - *(int *)(param_1 + 0xc)) / iVar8;
  }
  else {
    if ((*(int *)(param_1 + 700) == 0) &&
       (iVar8 = *(int *)(param_1 + 0x18c), (*(byte *)(iVar8 + 0x461) & 0x40) == 0)) {
      if (*(int *)(iVar8 + 0x19a0) == 4) {
        cVar6 = FUN_00590c10(iVar8 + 0x1828);
        if (((cVar6 == '\0') ||
            (uVar9 = (int)*puVar14 >> 0x1f,
            (int)((*puVar14 ^ uVar9) - uVar9) <=
            *(int *)(*(int *)(param_1 + 0x18c) + 0x1820) + -0x108000)) ||
           (uVar9 = (int)*(uint *)(param_1 + 8) >> 0x1f,
           0x1428f4 < (int)((*(uint *)(param_1 + 8) ^ uVar9) - uVar9))) {
          bVar17 = false;
        }
        else {
          bVar17 = true;
        }
        if ((bVar17) &&
           (((-1 < (int)*puVar14) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
          bVar17 = true;
        }
        else {
          bVar17 = false;
        }
        if (!bVar17) goto LAB_005a4ce6;
      }
      iVar8 = *(int *)(*(int *)(param_1 + 0x18c) + 0x44c);
      if (((iVar8 != 7) && (iVar8 != 5)) || (param_1 != *(int *)(*(int *)(param_1 + 0x18c) + 0x438))
         ) goto LAB_005a4e5b;
    }
LAB_005a4ce6:
    if ((*(char *)(param_1 + 99) == '\0') &&
       ((*(byte *)(*(int *)(param_1 + 0x18c) + 0x461) & 0x40) == 0)) {
      iStack_38 = 0;
      if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
         (cVar6 = FUN_005943b0(), cVar6 == '\0')) {
        bVar17 = false;
      }
      else {
        bVar17 = true;
      }
      if ((bVar17) && (*(char *)(param_1 + 0x5c) != '\0')) {
        bVar17 = true;
      }
      else {
        bVar17 = false;
      }
      if ((!bVar17) ||
         ((((*(int *)(param_1 + 700) != 0 && (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 6)) ||
           (900 < *(int *)(*(int *)(param_1 + 0x184) + 0x2dc))) ||
          ((*(int *)(*(int *)(param_1 + 0x18c) + 0x440) != 0 &&
           (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 0)))))) goto LAB_005a4db0;
      bVar17 = false;
    }
    else {
      iStack_38 = 1;
LAB_005a4db0:
      bVar17 = true;
    }
    iVar8 = *(int *)(param_1 + 400);
    if (param_1 == *(int *)(iVar8 + 0x40)) {
LAB_005a4e3e:
      if (!bVar17) {
        FUN_005a8680();
        goto LAB_005a4e5b;
      }
    }
    else {
      if (param_1 == *(int *)(iVar8 + 0x4c)) {
LAB_005a4e34:
        bVar17 = true;
        iStack_38 = 1;
        goto LAB_005a4e3e;
      }
      if (!bVar17) {
        if (0x78 < *(int *)(*(int *)(param_1 + 0x184) + 0x2dc)) {
          uVar9 = *puVar14 - *(int *)(iVar8 + 0xcc);
          uVar12 = (int)uVar9 >> 0x1f;
          if ((((int)((uVar9 ^ uVar12) - uVar12) < 0x60000) &&
              (uVar9 = *(int *)(param_1 + 8) - *(int *)(iVar8 + 0xd0), uVar12 = (int)uVar9 >> 0x1f,
              (int)((uVar9 ^ uVar12) - uVar12) < 0x60000)) &&
             (uVar9 = *(int *)(param_1 + 0xc) - *(int *)(iVar8 + 0xd4), uVar12 = (int)uVar9 >> 0x1f,
             (int)((uVar9 ^ uVar12) - uVar12) < 0x60000)) {
            bVar4 = true;
          }
          else {
            bVar4 = false;
          }
          if (bVar4) goto LAB_005a4e34;
        }
        goto LAB_005a4e3e;
      }
    }
    FUN_005a65a0(iStack_38);
  }
LAB_005a4e5b:
  iVar8 = *(int *)(param_1 + 0x40);
  if (((iVar8 == 0x1d) || (iVar8 == 5)) || (iVar8 == 0x24)) {
    bVar17 = false;
  }
  else {
    bVar17 = true;
  }
  if ((bVar17) && ((*(byte *)(*(int *)(param_1 + 0x18c) + 0x461) & 0x40) == 0)) {
    FUN_005a9490();
  }
  if ((*(int *)(param_1 + 700) == 0) &&
     (iVar8 = *(int *)(param_1 + 0x18c), (*(byte *)(iVar8 + 0x461) & 0x40) == 0)) {
    if (*(int *)(iVar8 + 0x19a0) == 4) {
      uVar9 = *puVar14;
      if (((((int)uVar9 < *(int *)(iVar8 + 0x1828)) || (*(int *)(iVar8 + 0x1834) < (int)uVar9)) ||
          (*(int *)(param_1 + 8) < *(int *)(iVar8 + 0x182c))) ||
         (((*(int *)(iVar8 + 0x1838) < *(int *)(param_1 + 8) ||
           (*(int *)(param_1 + 0xc) < *(int *)(iVar8 + 0x1830))) ||
          (*(int *)(iVar8 + 0x183c) < *(int *)(param_1 + 0xc))))) {
        bVar17 = false;
      }
      else {
        bVar17 = true;
      }
      if (((bVar17) &&
          (*(int *)(iVar8 + 0x1820) + -0x108000 <
           (int)((uVar9 ^ (int)uVar9 >> 0x1f) - ((int)uVar9 >> 0x1f)))) &&
         (uVar12 = (int)*(uint *)(param_1 + 8) >> 0x1f,
         (int)((*(uint *)(param_1 + 8) ^ uVar12) - uVar12) < 0x1428f5)) {
        bVar17 = true;
      }
      else {
        bVar17 = false;
      }
      if ((bVar17) &&
         (((-1 < (int)uVar9) - 1 & 0xfffffffe) + 1 ==
          ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
        bVar17 = true;
      }
      else {
        bVar17 = false;
      }
      if (!bVar17) goto LAB_005a4fa2;
    }
    if (((*(int *)(iVar8 + 0x44c) != 7) && (*(int *)(iVar8 + 0x44c) != 5)) ||
       (param_1 != *(int *)(iVar8 + 0x438))) {
      FUN_005a7260();
    }
  }
LAB_005a4fa2:
  FUN_005a8f20(*(undefined2 *)(param_1 + 0x34));
  if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
     (cVar6 = FUN_005943b0(), cVar6 == '\0')) {
    bVar17 = false;
  }
  else {
    bVar17 = true;
  }
  if ((bVar17) && (*(char *)(param_1 + 0x5c) != '\0')) {
    bVar17 = true;
  }
  else {
    bVar17 = false;
  }
  if (bVar17) {
    if (*(char *)(*(int *)(param_1 + 0x184) + 0x214) == '\0') {
      if ((*(int *)(param_1 + 0x40) < 0) || (3 < *(int *)(param_1 + 0x40))) {
        bVar17 = false;
      }
      else {
        bVar17 = true;
      }
      if (bVar17) {
        *(undefined4 *)(param_1 + 0x58) = 0;
      }
    }
    if (*(char *)(*(int *)(param_1 + 0x184) + 0x215) == '\0') {
      if ((*(int *)(param_1 + 0x40) < 0) || (3 < *(int *)(param_1 + 0x40))) {
        bVar17 = false;
      }
      else {
        bVar17 = true;
      }
      if (bVar17) {
        *(undefined4 *)(param_1 + 0x54) = 0;
      }
    }
  }
  return;
}


