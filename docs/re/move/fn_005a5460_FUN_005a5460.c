// FUN_005a5460  entry=005a5460  size=4404 bytes

void __thiscall FUN_005a5460(int param_1,int param_2)

{
  byte bVar1;
  undefined2 uVar2;
  short sVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  bool bVar7;
  char cVar8;
  char cVar9;
  short sVar10;
  int iVar11;
  undefined4 uVar12;
  int iVar13;
  int iVar14;
  int iVar15;
  ushort *puVar16;
  int iVar17;
  int iVar18;
  int iVar19;
  int *piVar20;
  uint uVar21;
  ushort uVar22;
  short sVar23;
  int iVar24;
  int iVar25;
  int iVar26;
  int iVar27;
  int iVar28;
  int iVar29;
  int iVar30;
  int iVar31;
  int iVar32;
  int iVar33;
  int iVar34;
  int iVar35;
  uint uVar36;
  uint uVar37;
  int iVar38;
  char *_Format;
  char *pcStack_318;
  int iStack_314;
  int iStack_310;
  char *pcStack_30c;
  int iStack_308;
  uint uStack_304;
  int iStack_300;
  uint uStack_2fc;
  int iStack_2a0;
  int iStack_29c;
  int iStack_298;
  int iStack_294;
  int iStack_290;
  int iStack_28c;
  int iStack_288;
  int iStack_284;
  int iStack_280;
  int iStack_27c;
  int iStack_278;
  int iStack_274;
  int iStack_270;
  int iStack_26c;
  undefined4 uStack_268;
  int iStack_264;
  int iStack_260;
  undefined4 uStack_25c;
  int iStack_258;
  int iStack_254;
  undefined4 uStack_250;
  int iStack_24c;
  int iStack_248;
  undefined4 uStack_244;
  int aiStack_240 [8];
  int aiStack_220 [8];
  CHAR aCStack_200 [256];
  undefined1 auStack_100 [256];
  
  iVar35 = *(int *)(param_1 + 0x18c);
  iVar32 = *(int *)(param_1 + 0x40);
  if (*(char *)(iVar35 + 0x5fac) != '\0') {
    iVar24 = *(int *)(iVar35 + 0x5e88 + iVar32 * 4);
    if (iVar24 < 0) {
      return;
    }
    iVar32 = (&DAT_00664fb8)[iVar32];
    iVar15 = *(int *)(param_1 + 0x2c);
    iVar18 = *(int *)(param_1 + 0x30);
    if (*(int *)(iVar35 + 0x29b4) == 0) {
      iVar11 = 0;
    }
    else {
      iVar11 = *(int *)(*(int *)(*(int *)(iVar35 + 0x29b0) + 0x108) + 4 + iVar24 * 0xc);
    }
    iVar33 = *(int *)(param_1 + 4);
    iVar34 = *(int *)(param_2 + 0xe4);
    iVar38 = *(int *)(param_1 + 8);
    iVar19 = *(int *)(param_2 + 0xe8);
    uVar12 = ftol(*(undefined4 *)(param_2 + 0x100));
    iVar13 = FUN_005edf90(uVar12);
    iVar17 = (uint)(*(int *)(param_1 + 700) == 0) + *(int *)(param_1 + 0x2b8) * 2;
    lstrcpyA(aCStack_200,&DAT_00664ba0);
    _Format = &DAT_00652f00;
    iVar14 = lstrlenA(aCStack_200);
    sprintf(aCStack_200 + iVar14,_Format,iVar17);
    FUN_0051fd00(aCStack_200);
    FUN_005f3480(iVar24);
    FUN_005f34c0((iVar11 * ((iVar18 + iVar15 * 4) % (iVar32 << 2))) / (iVar32 << 2),1);
    *(undefined4 *)(iVar35 + 0x29f0) = *(undefined4 *)(param_1 + 4);
    *(undefined4 *)(iVar35 + 0x29f4) = *(undefined4 *)(param_1 + 8);
    uVar12 = *(undefined4 *)(param_1 + 0xc);
    *(undefined1 *)(iVar35 + 0x2a10) = 1;
    *(undefined4 *)(iVar35 + 0x29f8) = uVar12;
    uVar2 = *(undefined2 *)(param_1 + 0x34);
    *(undefined2 *)(iVar35 + 0x29fe) = 0;
    *(undefined2 *)(iVar35 + 0x2a00) = 0;
    *(undefined2 *)(iVar35 + 0x29fc) = uVar2;
    *(undefined1 *)(iVar35 + 0x2a10) = 1;
    FUN_005f3360(auStack_100,0);
    cVar8 = FUN_005f37f0(param_2);
    if (cVar8 == '\0') {
      return;
    }
    if (iVar13 < 0x1e0001) {
      if (iVar13 < 0x190001) {
        cVar8 = 0xc0000 < iVar13;
      }
      else {
        cVar8 = '\x02';
      }
    }
    else {
      cVar8 = '\x03';
    }
    bVar1 = cVar8 + 3;
    if (3 < bVar1) {
      bVar1 = 4;
    }
    if (*(char *)(*(int *)(param_1 + 0x18c) + 0x1a1c) != '\0') {
      iStack_300 = -1;
      do {
        iStack_314 = -1;
        do {
          iVar32 = (*(int *)(param_1 + 4) -
                   (*(int *)(*(int *)(param_1 + 0x18c) + 0x1820) + 0x80000) * iStack_300) / 0x26;
          iVar24 = (*(int *)(param_1 + 8) -
                   (*(int *)(*(int *)(param_1 + 0x18c) + 0x1824) + 0x80000) * iStack_314) / 0x26;
          sVar10 = FUN_005ee080(iVar32,iVar24);
          FUN_00436fb0(*(undefined4 *)(&DAT_006d31c8 + (sVar10 + 8 >> 4 & 0xfffU) * 4),
                       *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar10 >> 4 & 0xfffU) * 4));
          iVar15 = FUN_005edfb0(iVar32,iVar33 - iVar34,iVar24,iVar38 - iVar19);
          if (iVar15 < 0x28000) {
            FUN_005f1b00(bVar1);
            FUN_005f3750(param_2,iVar32,iVar24,
                         ((int)(iVar15 * 0x52 + (iVar15 * 0x52 >> 0x1f & 0x3ffffU)) >> 0x12) + 0x3c)
            ;
          }
          iStack_314 = iStack_314 + 2;
        } while (iStack_314 < 2);
        iStack_300 = iStack_300 + 2;
      } while (iStack_300 < 2);
    }
    FUN_005f1b00(cVar8);
    if (cVar8 == '\x02') {
      *(undefined4 *)(iVar35 + 0x2a04) = 0x111eb;
      *(undefined4 *)(iVar35 + 0x2a08) = 0x10937;
      *(undefined4 *)(iVar35 + 0x2a0c) = 0x10000;
      *(undefined1 *)(iVar35 + 0x2a10) = 1;
    }
    if (cVar8 == '\x03') {
      *(undefined4 *)(iVar35 + 0x2a04) = 0x12ccc;
      *(undefined4 *)(iVar35 + 0x2a08) = 0x11999;
    }
    else {
      *(undefined4 *)(iVar35 + 0x2a04) = 0x10000;
      *(undefined4 *)(iVar35 + 0x2a08) = 0x10000;
    }
    *(undefined4 *)(iVar35 + 0x2a0c) = 0x10000;
    *(undefined1 *)(iVar35 + 0x2a10) = 1;
    FUN_005db240(1);
    FUN_005f3700(param_2);
    return;
  }
  uVar21 = (&DAT_006650e0)[iVar32];
  iVar32 = (uVar21 ^ (int)uVar21 >> 0x1f) - ((int)uVar21 >> 0x1f);
  if ((iVar32 == 0xc) || (bVar7 = false, iVar32 == 8)) {
    bVar7 = true;
  }
  sVar10 = *(short *)(iVar35 + 0x181e);
  uVar12 = *(undefined4 *)(&DAT_006d31c8 + (sVar10 + 8 >> 4 & 0xfffU) * 4);
  pcStack_318._0_2_ = *(short *)(param_1 + 0x2c);
  uVar4 = *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar10 >> 4 & 0xfffU) * 4);
  iStack_300 = 0x10000;
  uStack_304 = 0;
  iStack_310 = 0x10000;
  if (((iVar32 == 5) || (iVar32 == 8)) || (iVar35 = 0xc, iVar32 == 1)) {
    iVar35 = 8;
  }
  sVar3 = *(short *)(param_1 + 0x34);
  sVar23 = *(short *)(param_2 + 0xdc) + -0x4000;
  uVar22 = (sVar3 - *(short *)(param_2 + 0xdc)) + 0x4000;
  pcStack_30c._0_2_ = (short)pcStack_318;
  if (iVar35 == 8) {
    uVar36 = 0;
    puVar16 = &DAT_006653e0;
    do {
      if (*puVar16 < uVar22) {
        uVar36 = uVar36 + 1;
      }
      if (*puVar16 < (ushort)(sVar3 - sVar10)) {
        uStack_304 = uStack_304 + 1;
      }
      puVar16 = puVar16 + 1;
    } while ((int)puVar16 < 0x6653f0);
    uVar36 = uVar36 & 7;
    if ((&DAT_00665330)[*(uint *)(param_1 + 0x40) & 0x7f] != '\0') {
      if (uVar36 != 0) {
        uVar22 = uVar22 + (-((short)(*(short *)(&DAT_006653de + uVar36 * 2) -
                                    (&DAT_006653e0)[uVar36]) / 2) - (&DAT_006653e0)[uVar36]);
      }
      iVar35 = (*(short *)(param_2 + 0xde) + 0x4000) * (int)((short)(uVar22 * 3) / 2);
      sVar10 = (short)((int)(iVar35 + (iVar35 >> 0x1f & 0x3fffU)) >> 0xe);
      iVar35 = (int)sVar10;
      if (sVar10 < 1) {
        iVar24 = *(int *)(&DAT_00665410 + uVar36 * 4);
        iVar35 = -iVar35;
      }
      else {
        iVar24 = *(int *)(&DAT_006653f0 + uVar36 * 4);
      }
      iStack_310 = iVar24 * (iVar35 >> 8) + 0x10000;
      sVar23 = sVar10 + sVar23;
    }
    uVar36 = uVar36 + 2 & 7;
    uVar37 = (uStack_304 & 7) + 2 & 7;
    if ((int)uVar21 < 0) {
      iStack_300 = -0x10000;
      uVar36 = (int)(iVar32 - uVar36) % iVar32;
      uVar37 = (int)(iVar32 - uVar37) % iVar32;
      iStack_310 = -iStack_310;
    }
    if (!bVar7) {
      if (iVar32 == 1) {
        uVar36 = 0;
        uVar37 = 0;
      }
      else {
        if (4 < (int)uVar36) {
          iStack_310 = -iStack_310;
          iVar35 = *(int *)(param_1 + 0x40);
          uVar36 = 8 - uVar36;
          if ((iVar35 == *(int *)(&DAT_00665208 + iVar35 * 4)) && ((&DAT_00664fb8)[iVar35] == 0xe))
          {
            bVar7 = true;
          }
          else {
            bVar7 = false;
          }
          if (bVar7) {
            pcStack_30c._0_2_ = (short)(((short)pcStack_318 + 7) % 0xe);
          }
        }
        if (4 < (int)uVar37) {
          iStack_300 = -iStack_300;
          iVar35 = *(int *)(param_1 + 0x40);
          uVar37 = 8 - uVar37;
          if ((iVar35 == *(int *)(&DAT_00665208 + iVar35 * 4)) && ((&DAT_00664fb8)[iVar35] == 0xe))
          {
            bVar7 = true;
          }
          else {
            bVar7 = false;
          }
          if (bVar7) {
            pcStack_318._0_2_ = (short)(((short)pcStack_318 + 7) % 0xe);
          }
        }
      }
    }
  }
  else {
    iVar35 = 0;
    puVar16 = &DAT_00665430;
    do {
      if (*puVar16 < uVar22) {
        iVar35 = iVar35 + 1;
      }
      if (*puVar16 < (ushort)(sVar3 - sVar10)) {
        uStack_304 = uStack_304 + 1;
      }
      puVar16 = puVar16 + 1;
    } while ((int)puVar16 < 0x665448);
    iVar35 = iVar35 % 0xc;
    iVar24 = (int)uStack_304 % 0xc;
    if ((int)uVar21 < 0) {
      iVar35 = (iVar32 - iVar35) % iVar32;
      iVar24 = (iVar32 - iVar24) % iVar32;
      iStack_300 = -0x10000;
      iStack_310 = -0x10000;
    }
    if (iVar35 != 0) {
      uVar22 = uVar22 + (-((short)(*(short *)(&DAT_0066542e + iVar35 * 2) - (&DAT_00665430)[iVar35])
                          / 2) - (&DAT_00665430)[iVar35]);
    }
    iVar32 = (*(short *)(param_2 + 0xde) + 0x4000) * (int)(short)(((short)uVar22 * 3) / 2);
    sVar10 = (short)((int)(iVar32 + (iVar32 >> 0x1f & 0x3fffU)) >> 0xe);
    iVar32 = (int)sVar10;
    if (sVar10 < 1) {
      iVar15 = *(int *)(&DAT_00665478 + iVar35 * 4);
      iVar32 = -iVar32;
    }
    else {
      iVar15 = *(int *)(&DAT_00665448 + iVar35 * 4);
    }
    iStack_310 = iStack_310 + iVar15 * (iVar32 >> 8);
    sVar23 = sVar10 + sVar23;
    uVar36 = (iVar35 + 3) % 0xc;
    uVar37 = (iVar24 + 3) % 0xc;
    if (6 < (int)uVar36) {
      uVar36 = 0xc - uVar36;
      iStack_310 = -iStack_310;
    }
    if (6 < (int)uVar37) {
      uVar37 = 0xc - uVar37;
      iStack_300 = -iStack_300;
    }
  }
  iVar35 = (&DAT_00664fb8)[*(int *)(param_1 + 0x40)];
  iStack_308 = (int)(short)pcStack_30c;
  if (iVar35 + -1 <= (int)(short)pcStack_30c) {
    iStack_308 = iVar35 + -1;
  }
  iVar32 = *(int *)(*(int *)(param_1 + 0x18c) + 0x2468);
  iVar24 = iVar32 + (iVar35 * uVar36 + (&DAT_006744e8)[*(int *)(param_1 + 0x40)] + iStack_308) *
                    0x4c;
  iVar15 = (int)(short)pcStack_318;
  if (iVar35 + -1 <= (int)(short)pcStack_318) {
    iVar15 = iVar35 + -1;
  }
  iVar32 = iVar32 + (iVar35 * uVar37 + (&DAT_006744e8)[*(int *)(param_1 + 0x40)] + iVar15) * 0x4c;
  uVar5 = *(undefined4 *)(&DAT_006d31c8 + (sVar23 + 8 >> 4 & 0xfffU) * 4);
  uVar6 = *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar23 >> 4 & 0xfffU) * 4);
  iVar35 = *(int *)(iVar24 + 0x3c);
  iVar15 = *(int *)(iVar24 + 0x18);
  iVar18 = *(int *)(iVar32 + 0x3c) * 0x1b333;
  iVar11 = (*(int *)(iVar32 + 0x3c) - *(int *)(iVar32 + 0x18)) * 0x1b333;
  iVar33 = (*(int *)(iVar24 + 0x14) - *(int *)(iVar24 + 0x38)) * iStack_310;
  iVar38 = -(*(int *)(iVar24 + 0x38) * iStack_310);
  iVar34 = -(*(int *)(iVar32 + 0x38) * iStack_300);
  iStack_300 = (*(int *)(iVar32 + 0x14) - *(int *)(iVar32 + 0x38)) * iStack_300;
  iVar17 = FUN_005edfa0(iVar38,uVar5);
  iVar14 = iVar17 / 0x1a + *(int *)(param_1 + 4);
  iVar17 = FUN_005edfa0(iVar33,uVar5);
  iVar25 = iVar17 / 0x1a + *(int *)(param_1 + 4);
  iVar17 = FUN_005edfa0(iVar38,uVar6);
  iVar26 = iVar17 / 0x1a + *(int *)(param_1 + 8);
  iVar17 = FUN_005edfa0(iVar33,uVar6);
  iVar27 = iVar17 / 0x1a + *(int *)(param_1 + 8);
  iVar17 = FUN_005edfa0(iVar34,uVar12);
  iVar28 = iVar17 / 0x1a + *(int *)(param_1 + 4);
  iVar17 = FUN_005edfa0(iStack_300,uVar12);
  iVar29 = iVar17 / 0x1a + *(int *)(param_1 + 4);
  iVar17 = FUN_005edfa0(iVar34,uVar4);
  iVar30 = iVar17 / 0x1a + *(int *)(param_1 + 8);
  iVar17 = FUN_005edfa0(iStack_300,uVar4);
  iVar31 = iVar17 / 0x1a + *(int *)(param_1 + 8);
  iVar17 = FUN_005edfd0(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1940),iVar18,uVar4);
  iVar33 = FUN_005edfd0(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1940),iVar18,uVar4);
  iVar34 = FUN_005edfd0(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1940),iVar18,uVar12);
  iVar18 = FUN_005edfd0(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1940),iVar18,uVar12);
  iVar38 = FUN_005edfd0(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1940),iVar11,uVar4);
  iVar19 = FUN_005edfd0(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1940),iVar11,uVar4);
  iVar13 = FUN_005edfd0(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1940),iVar11,uVar12);
  iVar11 = FUN_005edfd0(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1940),iVar11,uVar12);
  iStack_254 = iVar11 / 0x30 + iVar31;
  iStack_298 = (iVar35 * 0x1b333) / 0x30;
  iStack_280 = ((iVar35 - iVar15) * 0x1b333) / 0x30;
  uStack_268 = 0;
  uStack_25c = 0;
  uStack_250 = 0;
  uStack_244 = 0;
  iStack_2a0 = iVar14;
  iStack_29c = iVar26;
  iStack_294 = iVar25;
  iStack_290 = iVar27;
  iStack_28c = iStack_298;
  iStack_288 = iVar25;
  iStack_284 = iVar27;
  iStack_27c = iVar14;
  iStack_278 = iVar26;
  iStack_274 = iStack_280;
  iStack_270 = iVar28 - iVar17 / 0x30;
  iStack_26c = iVar34 / 0x30 + iVar30;
  iStack_264 = iVar29 - iVar33 / 0x30;
  iStack_260 = iVar18 / 0x30 + iVar31;
  iStack_258 = iVar29 - iVar19 / 0x30;
  iStack_24c = iVar28 - iVar38 / 0x30;
  iStack_248 = iVar13 / 0x30 + iVar30;
  iVar35 = FUN_005eec60(param_2 + 0xf0,&iStack_2a0,aiStack_240,8);
  if (iVar35 != 0) {
    return;
  }
  iVar11 = 0x70000000;
  iVar18 = 0x70000000;
  uStack_2fc = 4;
  piVar20 = aiStack_240;
  iVar35 = -0x70000000;
  iVar15 = -0x70000000;
  do {
    iVar17 = *piVar20;
    if (iVar17 <= iVar18) {
      iVar18 = iVar17;
    }
    iVar33 = piVar20[1];
    if (iVar33 <= iVar11) {
      iVar11 = iVar33;
    }
    if (iVar17 < iVar15) {
      iVar17 = iVar15;
    }
    if (iVar33 < iVar35) {
      iVar33 = iVar35;
    }
    uStack_2fc = uStack_2fc + -1;
    piVar20 = piVar20 + 2;
    iVar35 = iVar33;
    iVar15 = iVar17;
  } while (uStack_2fc != 0);
  iVar35 = 0x70000000;
  iVar15 = 0x70000000;
  uStack_2fc = 4;
  piVar20 = aiStack_220;
  iVar34 = -0x70000000;
  iVar38 = -0x70000000;
  do {
    iVar19 = *piVar20;
    if (iVar19 <= iVar15) {
      iVar15 = iVar19;
    }
    iVar13 = piVar20[1];
    if (iVar13 <= iVar35) {
      iVar35 = iVar13;
    }
    if (iVar19 < iVar38) {
      iVar19 = iVar38;
    }
    if (iVar13 < iVar34) {
      iVar13 = iVar34;
    }
    uStack_2fc = uStack_2fc + -1;
    piVar20 = piVar20 + 2;
    iVar34 = iVar13;
    iVar38 = iVar19;
  } while (uStack_2fc != 0);
  iVar34 = *(int *)(param_1 + 0x18c);
  if (*(char *)(iVar34 + 0x1a1c) != '\0') {
    iVar25 = *(int *)(iVar34 + 0x80) - *(int *)(iVar34 + 0x78);
    iVar14 = *(int *)(iVar34 + 0x84) - *(int *)(iVar34 + 0x7c);
    iVar38 = 0;
    if (0 < iVar15) {
      iVar38 = iVar15;
    }
    if (iVar19 < iVar25) {
      iVar25 = iVar19;
    }
    if (iVar38 < iVar25) {
      iVar15 = 0;
      if (0 < iVar35) {
        iVar15 = iVar35;
      }
      if (iVar13 < iVar14) {
        iVar14 = iVar13;
      }
      if (iVar14 <= iVar15) goto LAB_005a62f8;
      bVar7 = true;
    }
    else {
LAB_005a62f8:
      bVar7 = false;
    }
    if (bVar7) {
      FUN_005d33b0(*(undefined4 *)(iVar34 + 0x1a4c),0,0);
      uVar21 = *(uint *)(iVar32 + 0x14);
      uVar36 = *(uint *)(iVar32 + 0x18);
      FUN_005cc670(aiStack_220,*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1a4c),
                   (0 < (int)uVar21) - 1 & uVar21,(0 < (int)uVar36) - 1 & uVar36,
                   uVar21 & ((int)uVar21 < 0) - 1,uVar36 & ((int)uVar36 < 0) - 1,6,0);
    }
  }
  iVar35 = *(int *)(param_1 + 0x18c);
  iVar15 = *(int *)(iVar35 + 0x80) - *(int *)(iVar35 + 0x78);
  iVar35 = *(int *)(iVar35 + 0x84) - *(int *)(iVar35 + 0x7c);
  iVar32 = 0;
  if (0 < iVar18) {
    iVar32 = iVar18;
  }
  if (iVar17 < iVar15) {
    iVar15 = iVar17;
  }
  if (iVar32 < iVar15) {
    iVar32 = 0;
    if (0 < iVar11) {
      iVar32 = iVar11;
    }
    if (iVar33 < iVar35) {
      iVar35 = iVar33;
    }
    if (iVar32 < iVar35) {
      bVar7 = true;
      goto LAB_005a63da;
    }
  }
  bVar7 = false;
LAB_005a63da:
  if (bVar7) {
    if (*(char *)(param_1 + 0x2d5) != '\0') {
      *(undefined4 *)(*(int *)(param_1 + 0x2dc) + 0x15) = *(undefined4 *)(param_1 + 0x368);
      *(undefined4 *)(*(int *)(param_1 + 0x2dc) + 1) = *(undefined4 *)(param_1 + 0x360);
      *(undefined4 *)(*(int *)(param_1 + 0x2dc) + 5) = *(undefined4 *)(param_1 + 0x364);
    }
    if (*(char *)(param_1 + 0x2d4) != '\0') {
      pcStack_30c = (char *)(param_1 + 0x2e0);
      uStack_2fc = 0;
      do {
        iVar35 = 0;
        pcStack_318 = pcStack_30c;
        do {
          iVar32 = 0;
          cVar8 = *pcStack_318;
          do {
            uVar21 = uStack_2fc;
            if (iStack_310 < 0) {
              uVar21 = ((uStack_2fc & 8) - (uStack_2fc & 7)) + 7;
            }
            bVar1 = *(byte *)(*(int *)(*(int *)(param_1 + 0x18c) + 0x1a64) +
                              (iVar35 + (*(int *)(iVar24 + 0x10) * 0x10 + uVar21) * 8) * 6 + iVar32)
            ;
            if (bVar1 != 0) {
              if (cVar8 == '\x7f') {
                cVar9 = (&DAT_006654b0)[iVar32];
              }
              else if (cVar8 == 'g') {
                cVar9 = *(char *)(iVar32 + 0x6654a8);
              }
              else {
                cVar9 = (cVar8 - (char)iVar32) + '\x05';
              }
              *(char *)(*(int *)(param_1 + 0x2dc) + (uint)bVar1) = cVar9;
            }
            iVar32 = iVar32 + 1;
          } while (iVar32 < 6);
          iVar35 = iVar35 + 1;
          pcStack_318 = pcStack_318 + 0x10;
        } while (iVar35 < 8);
        uStack_2fc = uStack_2fc + 1;
        pcStack_30c = pcStack_30c + 1;
      } while ((int)uStack_2fc < 0x10);
    }
    FUN_005d34a0(*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1a4c),0,0,
                 *(undefined4 *)(param_1 + 0x2dc));
    uVar21 = *(uint *)(iVar24 + 0x14);
    uVar36 = *(uint *)(iVar24 + 0x18);
    FUN_005cc670(aiStack_240,*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x1a4c),
                 (0 < (int)uVar21) - 1 & uVar21,(0 < (int)uVar36) - 1 & uVar36,
                 uVar21 & ((int)uVar21 < 0) - 1,uVar36 & ((int)uVar36 < 0) - 1,4,0);
  }
  return;
}


