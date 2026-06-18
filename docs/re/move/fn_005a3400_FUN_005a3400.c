// FUN_005a3400  entry=005a3400  size=4293 bytes

/* WARNING: Removing unreachable block (ram,0x005a34d3) */
/* WARNING: Removing unreachable block (ram,0x005a34e3) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __fastcall FUN_005a3400(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  bool bVar4;
  byte bVar5;
  char cVar6;
  ushort uVar7;
  undefined2 uVar8;
  uint uVar9;
  int *piVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  int *piVar13;
  int iVar14;
  int *piVar15;
  int iVar16;
  int *piVar17;
  undefined4 *puVar18;
  undefined4 *puVar19;
  undefined4 uStack_a8;
  int iStack_a4;
  int iStack_a0;
  undefined1 auStack_9c [12];
  int aiStack_90 [4];
  undefined4 uStack_80;
  undefined4 uStack_7c;
  int iStack_78;
  int iStack_74;
  int iStack_70;
  int iStack_6c;
  int iStack_68;
  int iStack_64;
  undefined1 auStack_60 [12];
  undefined1 auStack_54 [84];
  
  FUN_005ed870();
  iVar14 = *(int *)(param_1 + 0x18c);
  iVar16 = *(int *)(iVar14 + 0x1820);
  if ((*(uint *)(iVar14 + 0x19a0) & 1) == *(uint *)(param_1 + 0x2b8)) {
    iVar16 = -iVar16;
  }
  *(int *)(param_1 + 0x3a4) = iVar16;
  if (*(int *)(param_1 + 700) == 0) {
    *(int *)(param_1 + 0x1ec) = iVar16;
    *(undefined4 *)(param_1 + 0x1f0) = 0;
    *(undefined4 *)(param_1 + 500) = 0;
    *(int *)(param_1 + 0x1e0) = iVar16;
    *(undefined4 *)(param_1 + 0x1e4) = 0;
    *(undefined4 *)(param_1 + 0x1e8) = 0;
    iVar16 = *(int *)(iVar14 + 0x1820);
    aiStack_90[3] = 0x108000 - iVar16;
    uVar9 = *(uint *)(iVar14 + 0x19a0) & 1 ^ *(uint *)(param_1 + 0x2b8);
    if (uVar9 != 0) {
      aiStack_90[3] = -aiStack_90[3];
    }
    iVar14 = -iVar16;
    if (uVar9 != 0) {
      iVar14 = iVar16;
    }
    aiStack_90[2] = 0;
    aiStack_90[0] = iVar14;
    aiStack_90[1] = 0xffebd70b;
    uStack_80 = 0x1428f5;
    uStack_7c = 0;
    if (aiStack_90[3] < iVar14) {
      aiStack_90[0] = aiStack_90[3];
      aiStack_90[3] = iVar14;
    }
    uStack_7c = 0;
    aiStack_90[2] = 0;
    piVar17 = aiStack_90;
  }
  else {
    FUN_005a4510(&uStack_a8,*(uint *)(param_1 + 0x2b8),param_1 + 0x1f8);
    *(undefined4 *)(param_1 + 0x1e0) = uStack_a8;
    *(int *)(param_1 + 0x1e4) = iStack_a4;
    *(int *)(param_1 + 0x1e8) = iStack_a0;
    FUN_005a4510(&uStack_a8,*(undefined4 *)(param_1 + 0x2b8),param_1 + 0x204);
    iVar14 = iStack_a0;
    *(undefined4 *)(param_1 + 0x1ec) = uStack_a8;
    iStack_a0 = 0;
    *(int *)(param_1 + 0x1f0) = iStack_a4;
    *(int *)(param_1 + 500) = iVar14;
    uStack_a8 = *(undefined4 *)(param_1 + 0x230);
    iStack_a4 = *(int *)(param_1 + 0x234);
    uVar11 = FUN_0059a0e0(auStack_60,&uStack_a8);
    uVar12 = FUN_005b11f0(param_1 + 0x228,0);
    uVar12 = FUN_0059a0e0(auStack_54,uVar12);
    FUN_005b12c0(uVar12,uVar11);
    piVar17 = &iStack_78;
  }
  piVar15 = (int *)(param_1 + 0x1e0);
  piVar10 = (int *)(param_1 + 0x210);
  piVar13 = piVar10;
  for (iVar14 = 6; iVar14 != 0; iVar14 = iVar14 + -1) {
    *piVar13 = *piVar17;
    piVar17 = piVar17 + 1;
    piVar13 = piVar13 + 1;
  }
  *(undefined4 *)(param_1 + 0x218) = 0xffff0000;
  *(undefined4 *)(param_1 + 0x224) = 0x12c0000;
  if (*piVar15 < *piVar10) {
    *piVar10 = *piVar15;
  }
  if (*(int *)(param_1 + 0x1e4) < *(int *)(param_1 + 0x214)) {
    *(int *)(param_1 + 0x214) = *(int *)(param_1 + 0x1e4);
  }
  if (*(int *)(param_1 + 0x1e8) < *(int *)(param_1 + 0x218)) {
    *(int *)(param_1 + 0x218) = *(int *)(param_1 + 0x1e8);
  }
  if (*(int *)(param_1 + 0x21c) < *piVar15) {
    *(int *)(param_1 + 0x21c) = *piVar15;
  }
  if (*(int *)(param_1 + 0x220) < *(int *)(param_1 + 0x1e4)) {
    *(int *)(param_1 + 0x220) = *(int *)(param_1 + 0x1e4);
  }
  if (*(int *)(param_1 + 0x224) < *(int *)(param_1 + 0x1e8)) {
    *(int *)(param_1 + 0x224) = *(int *)(param_1 + 0x1e8);
  }
  if (*(int *)(param_1 + 0x1ec) < *piVar10) {
    *piVar10 = *(int *)(param_1 + 0x1ec);
  }
  if (*(int *)(param_1 + 0x1f0) < *(int *)(param_1 + 0x214)) {
    *(int *)(param_1 + 0x214) = *(int *)(param_1 + 0x1f0);
  }
  if (*(int *)(param_1 + 500) < *(int *)(param_1 + 0x218)) {
    *(int *)(param_1 + 0x218) = *(int *)(param_1 + 500);
  }
  if (*(int *)(param_1 + 0x21c) < *(int *)(param_1 + 0x1ec)) {
    *(int *)(param_1 + 0x21c) = *(int *)(param_1 + 0x1ec);
  }
  if (*(int *)(param_1 + 0x220) < *(int *)(param_1 + 0x1f0)) {
    *(int *)(param_1 + 0x220) = *(int *)(param_1 + 0x1f0);
  }
  if (*(int *)(param_1 + 0x224) < *(int *)(param_1 + 500)) {
    *(int *)(param_1 + 0x224) = *(int *)(param_1 + 500);
  }
  if (DAT_006d31c4 == '\0') {
    FUN_005bbf10(param_1 + 0x3b0,0);
    *(undefined4 *)(param_1 + 0x3b4) = 0;
    *(undefined4 *)(param_1 + 0x48) = 0;
    *(undefined4 *)(param_1 + 0x90) = 0;
    uVar9 = *(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0);
    *(undefined4 *)(param_1 + 0x54) = 0;
    *(undefined4 *)(param_1 + 0x58) = 0;
    uVar7 = -(ushort)((uVar9 & 1) != *(uint *)(param_1 + 0x2b8)) & 0x8000;
    *(ushort *)(param_1 + 100) = uVar7;
    *(ushort *)(param_1 + 0x34) = uVar7;
    if (*(int *)(param_1 + 0x2cc) < 0) {
      iVar14 = 0;
    }
    else {
      iVar14 = *(int *)(*(int *)(param_1 + 0x188) + 0x13c + *(int *)(param_1 + 0x2cc) * 4);
    }
    *(int *)(param_1 + 0xb0) = iVar14;
    if (iVar14 != 0) {
      *(undefined1 *)(param_1 + 0x61) = 1;
    }
    piVar17 = (int *)(param_1 + 4);
    *(undefined4 *)(param_1 + 0x68) = 0;
    *(undefined4 *)(param_1 + 0x6c) = 0;
    *(undefined4 *)(param_1 + 0x20) = 0;
    *(undefined4 *)(param_1 + 0x24) = 0;
    *(undefined4 *)(param_1 + 0x28) = 0;
    *piVar17 = 0;
    *(undefined4 *)(param_1 + 8) = 0;
    *(undefined4 *)(param_1 + 0xc) = 0;
    FUN_005a5430(-(*(int *)(param_1 + 700) == 0) & 0x1e);
    iVar14 = *(int *)(param_1 + 0x18c);
    switch(*(undefined4 *)(iVar14 + 0x448)) {
    default:
      goto switchD_005a380d_caseD_0;
    case 2:
      if (param_1 == *(int *)(iVar14 + 0x438)) {
        FUN_0058eca0(param_1);
        if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
           (cVar6 = FUN_005943b0(), cVar6 == '\0')) {
          bVar4 = false;
        }
        else {
          bVar4 = true;
        }
        if ((bVar4) && (*(char *)(param_1 + 0x5c) != '\0')) {
          bVar5 = 1;
        }
        else {
          bVar5 = 0;
        }
        *(uint *)(param_1 + 0x48) = (-(uint)bVar5 & 0x2d0) + 0xb4;
        FUN_005a5430(0);
        iVar14 = *(int *)(param_1 + 400);
        *piVar17 = *(int *)(iVar14 + 0x90);
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(iVar14 + 0x94);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(iVar14 + 0x98);
        iVar14 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
        if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
          iVar14 = -iVar14;
        }
        FUN_00590aa0(iVar14,0,0);
        puVar19 = (undefined4 *)FUN_00590ae0(&uStack_a8,piVar17);
        uVar11 = FUN_005ee080(*puVar19,puVar19[1]);
        *(short *)(param_1 + 0x34) = (short)uVar11;
        *(short *)(param_1 + 100) = (short)uVar11;
        piVar13 = (int *)FUN_005ee0f0(0x6666,uVar11);
        iVar14 = *(int *)(param_1 + 400);
        iVar16 = piVar13[1];
        iVar1 = piVar13[2];
        iVar2 = *(int *)(iVar14 + 0x94);
        iVar3 = *(int *)(iVar14 + 0x98);
        *piVar17 = *(int *)(iVar14 + 0x90) - *piVar13;
        *(int *)(param_1 + 8) = iVar2 - iVar16;
        *(int *)(param_1 + 0xc) = iVar3 - iVar1;
        return;
      }
      iStack_a4 = *(int *)(iVar14 + 0x1824);
      uStack_a8 = 0;
      iStack_a0 = 0x3e80000;
      puVar19 = &uStack_a8;
      iVar14 = -*(int *)(iVar14 + 0x1824);
      uVar12 = 0xffff0000;
      uVar11 = FUN_005a44f0(*(undefined4 *)(param_1 + 0x2b8));
      uVar11 = FUN_00590aa0(uVar11,iVar14,uVar12);
      FUN_005b12c0(uVar11,puVar19);
      iVar14 = *(int *)(param_1 + 0x1e8);
      iVar16 = iStack_70;
      if (iStack_70 <= iVar14) {
        iVar16 = iVar14;
      }
      if ((iVar16 <= iStack_64) && (iStack_64 = iVar14, iVar14 < iStack_70)) {
        iStack_64 = iStack_70;
      }
      iVar14 = *(int *)(param_1 + 0x1e4);
      iVar16 = iStack_74;
      if (iStack_74 <= iVar14) {
        iVar16 = iVar14;
      }
      if ((iVar16 <= iStack_68) && (iStack_68 = iStack_74, iStack_74 <= iVar14)) {
        iStack_68 = iVar14;
      }
      iVar14 = *piVar15;
      iVar16 = iStack_78;
      if (iStack_78 <= iVar14) {
        iVar16 = iVar14;
      }
      if ((iVar16 <= iStack_6c) && (iStack_6c = iStack_78, iStack_78 <= iVar14)) {
        iStack_6c = iVar14;
      }
      *piVar17 = iStack_6c;
      *(int *)(param_1 + 8) = iStack_68;
      *(int *)(param_1 + 0xc) = iStack_64;
      FUN_005ee2d0(*(int *)(param_1 + 400) + 0x90,0x90000);
      break;
    case 3:
      if (param_1 == *(int *)(iVar14 + 0x438)) {
        FUN_0058eca0(param_1);
        if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
           (cVar6 = FUN_005943b0(), cVar6 == '\0')) {
          bVar4 = false;
        }
        else {
          bVar4 = true;
        }
        if ((bVar4) && (*(char *)(param_1 + 0x5c) != '\0')) {
          bVar5 = 1;
        }
        else {
          bVar5 = 0;
        }
        *(uint *)(param_1 + 0x48) = (-(uint)bVar5 & 0x2d0) + 0xb4;
        FUN_005a5430(0x13);
        iVar14 = ((*(int *)(*(int *)(param_1 + 400) + 0x94) < 1) - 1 & 0xffff8000) + 0x4000;
        *(short *)(param_1 + 0x34) = (short)iVar14;
        piVar13 = (int *)FUN_005ee0f0(0x6666,iVar14);
        iVar14 = *(int *)(param_1 + 400);
        iVar16 = piVar13[1];
        iVar1 = piVar13[2];
        iVar2 = *(int *)(iVar14 + 0x94);
        iVar3 = *(int *)(iVar14 + 0x98);
        *piVar17 = *(int *)(iVar14 + 0x90) - *piVar13;
        *(int *)(param_1 + 8) = iVar2 - iVar16;
        *(int *)(param_1 + 0xc) = iVar3 - iVar1;
        return;
      }
      if (*(int *)(param_1 + 0x2b8) == *(int *)(*(int *)(iVar14 + 0x438) + 0x2b8)) {
        *piVar17 = *(int *)(param_1 + 0x1ec);
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x1f0);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 500);
      }
      else {
        *piVar17 = *piVar15;
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x1e4);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 0x1e8);
      }
      break;
    case 4:
    case 5:
      if (param_1 == *(int *)(iVar14 + 0x438)) {
        uVar9 = -(uint)(*(int *)(param_1 + 700) == 0) & 0x1e;
        _DAT_00665154 = (&DAT_006650e0)[uVar9];
        _DAT_0066502c = (&DAT_00664fb8)[uVar9];
        _DAT_0067455c = (&DAT_006744e8)[uVar9];
        FUN_0058eca0(param_1);
        if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
           (cVar6 = FUN_005943b0(), cVar6 == '\0')) {
          bVar4 = false;
        }
        else {
          bVar4 = true;
        }
        if ((bVar4) && (*(char *)(param_1 + 0x5c) != '\0')) {
          bVar5 = 1;
        }
        else {
          bVar5 = 0;
        }
        *(uint *)(param_1 + 0x48) = (-(uint)bVar5 & 0x2d0) + 0xb4;
        FUN_005a5430(0x1d);
        iVar14 = *(int *)(param_1 + 400);
        *piVar17 = *(int *)(iVar14 + 0x90);
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(iVar14 + 0x94);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(iVar14 + 0x98);
        iVar14 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
        if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
          iVar14 = -iVar14;
        }
        FUN_00590aa0(iVar14,0,0);
        puVar19 = (undefined4 *)FUN_00590ae0(auStack_9c,piVar17);
        uVar11 = FUN_005ee080(*puVar19,puVar19[1]);
        *(short *)(param_1 + 0x34) = (short)uVar11;
        *(short *)(param_1 + 100) = (short)uVar11;
        piVar13 = (int *)FUN_005ee0f0(0x6666,uVar11);
        iVar14 = *(int *)(param_1 + 400);
        iVar16 = *(int *)(iVar14 + 0x94);
        iVar1 = *(int *)(iVar14 + 0x98);
        iVar2 = piVar13[1];
        iVar3 = piVar13[2];
        *piVar17 = *(int *)(iVar14 + 0x90) - *piVar13;
        *(int *)(param_1 + 8) = iVar16 - iVar2;
        *(int *)(param_1 + 0xc) = iVar1 - iVar3;
        iVar14 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
        if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
          iVar14 = -iVar14;
        }
        FUN_00590aa0(iVar14,0,0);
      }
      else if (*(int *)(param_1 + 0x2b8) == *(int *)(*(int *)(iVar14 + 0x438) + 0x2b8)) {
        if ((DAT_006742ec & 1) == 0) {
          DAT_006742ec = DAT_006742ec | 1;
          _DAT_00674330 = 0;
          _DAT_00674334 = 0;
          _DAT_00674338 = 0;
          _DAT_0067433c = 0;
          _DAT_00674340 = 0;
          _DAT_00674344 = 0;
          _DAT_00674348 = 0;
          _DAT_0067434c = 0;
          _DAT_00674350 = 0;
          _DAT_00674354 = 0;
          _DAT_00674358 = 0;
          _DAT_0067435c = 0;
          _DAT_00674360 = 0;
          _DAT_00674364 = 0;
          _DAT_00674368 = 0;
          _DAT_0067436c = 0xb0000;
          _DAT_00674370 = 0;
          _DAT_00674374 = 0;
          _DAT_00674378 = 0xb0000;
          _DAT_0067437c = 0;
          _DAT_00674380 = 0;
          _DAT_00674384 = 0x20000;
          _DAT_00674388 = 0xfff6d70b;
          _DAT_0067438c = 0;
          _DAT_00674390 = 0xc0000;
          _DAT_00674394 = 0xfff78000;
          _DAT_00674398 = 0;
          _DAT_0067439c = 0x70000;
          _DAT_006743a0 = 0x30000;
          _DAT_006743a4 = 0;
          _DAT_006743a8 = 0x128000;
          _DAT_006743ac = 0;
          _DAT_006743b0 = 0;
          _DAT_006743b4 = 0x90000;
          _DAT_006743b8 = 0xfff50000;
          _DAT_006743bc = 0;
          _DAT_006743c0 = 0xa0000;
          _DAT_006743c4 = 0xb0000;
          _DAT_006743c8 = 0;
          _DAT_006743cc = 0x80000;
          _DAT_006743d0 = 0x20000;
          _DAT_006743d4 = 0;
          _DAT_006743d8 = 0x68000;
          _DAT_006743dc = 0xb0000;
          _DAT_006743e0 = 0;
          _DAT_006743e4 = 0;
          _DAT_006743e8 = 0;
          _DAT_006743ec = 0;
          _DAT_006743f0 = 0x80000;
          _DAT_006743f4 = 0xfffb0000;
          _DAT_006743f8 = 0;
          _DAT_006743fc = 0x80000;
          _DAT_00674400 = 0x60000;
          _DAT_00674404 = 0;
          _DAT_00674408 = 0xb0000;
          _DAT_0067440c = 0x58000;
          _DAT_00674410 = 0;
          FUN_00605ff0(&DAT_005a4550);
        }
        iVar14 = *(int *)(param_1 + 0x2c8);
        iVar16 = *(int *)(&DAT_00674330 + iVar14 * 0xc);
        iStack_a4 = *(int *)(&DAT_00674334 + iVar14 * 0xc);
        iStack_a0 = *(int *)(&DAT_00674338 + iVar14 * 0xc);
        *piVar17 = *(int *)(param_1 + 0x1ec);
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x1f0);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 500);
        iVar1 = *(int *)(param_1 + 0x18c);
        if ((*(int *)(iVar1 + 0x448) != 5) || (*(int *)(iVar1 + 0x19cc) != 0)) {
          if ((iVar16 == 0) && ((iStack_a4 == 0 && (iStack_a0 == 0)))) {
            bVar4 = true;
          }
          else {
            bVar4 = false;
          }
          if ((!bVar4) && (((iVar14 != 5 && (iVar14 != 6)) || (*(char *)(param_1 + 0x2d6) != '\0')))
             ) {
            iVar16 = *(int *)(iVar1 + 0x1820) - iVar16;
            if ((*(uint *)(iVar1 + 0x19a0) & 1) != *(uint *)(param_1 + 0x2b8)) {
              iVar16 = -iVar16;
            }
            iVar14 = iStack_a4;
            if (0 < *(int *)(*(int *)(param_1 + 400) + 0x94)) {
              iVar14 = -iStack_a4;
            }
            *piVar17 = iVar16;
            *(int *)(param_1 + 8) = iVar14;
            *(int *)(param_1 + 0xc) = iStack_a0;
          }
        }
        if (*(int *)(param_1 + 700) != 0) {
          FUN_005ee2d0(*(int *)(param_1 + 400) + 0x90,0xa8000);
        }
      }
      else if (*(int *)(param_1 + 700) == 0) {
        FUN_005a5430(0x20);
        *piVar17 = *piVar15;
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x1e4);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 0x1e8);
        *piVar17 = *piVar17 +
                   (-(uint)((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) !=
                           *(uint *)(param_1 + 0x2b8)) & 0xffff6668) + 0x4ccc;
        *(uint *)(param_1 + 8) =
             *(int *)(param_1 + 8) +
             (((-1 < *(int *)(*(int *)(param_1 + 400) + 0x94)) - 1 & 0xfffffffe) + 1) * -0x20000;
      }
      else {
        *piVar17 = *piVar15;
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x1e4);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 0x1e8);
        FUN_005ee2d0(*(int *)(param_1 + 400) + 0x90,0xa8000);
      }
      break;
    case 6:
      if (param_1 == *(int *)(iVar14 + 0x438)) {
        _DAT_00665154 = DAT_00665158;
        _DAT_0066502c = DAT_00665030;
        _DAT_0067455c = DAT_00674560;
        FUN_0058eca0(param_1);
        uVar11 = FUN_005ec240();
        if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
          FUN_004e9630(*(undefined4 *)(param_1 + 0x2c0),0);
        }
        FUN_005ec230(uVar11);
        if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
           (cVar6 = FUN_005943b0(), cVar6 == '\0')) {
          bVar4 = false;
        }
        else {
          bVar4 = true;
        }
        if ((bVar4) && (*(char *)(param_1 + 0x5c) != '\0')) {
          bVar5 = 1;
        }
        else {
          bVar5 = 0;
        }
        *(uint *)(param_1 + 0x48) = (-(uint)bVar5 & 0x2d0) + 0xb4;
        FUN_005a5430(0x1d);
        iVar14 = *(int *)(param_1 + 400);
        uVar7 = -(ushort)((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) !=
                         *(uint *)(param_1 + 0x2b8)) & 0x8000;
        *(ushort *)(param_1 + 100) = uVar7;
        *(ushort *)(param_1 + 0x34) = uVar7;
        *piVar17 = *(int *)(iVar14 + 0x90);
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(iVar14 + 0x94);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(iVar14 + 0x98);
        return;
      }
      if (*(int *)(param_1 + 0x2b8) == *(int *)(*(int *)(iVar14 + 0x438) + 0x2b8)) {
        *piVar17 = (*(int *)(param_1 + 0x1ec) + *piVar15) / 2;
        *(int *)(param_1 + 8) = (*(int *)(param_1 + 0x1e4) + *(int *)(param_1 + 0x1f0)) / 2;
        *(int *)(param_1 + 0xc) = (*(int *)(param_1 + 0x1e8) + *(int *)(param_1 + 500)) / 2;
      }
      else {
        *piVar17 = *piVar15;
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x1e4);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 0x1e8);
      }
      break;
    case 7:
      if (param_1 == *(int *)(iVar14 + 0x438)) {
        uVar9 = -(uint)(*(int *)(param_1 + 700) == 0) & 0x1e;
        _DAT_00665154 = (&DAT_006650e0)[uVar9];
        _DAT_0066502c = (&DAT_00664fb8)[uVar9];
        _DAT_0067455c = (&DAT_006744e8)[uVar9];
        FUN_0058eca0(param_1);
        if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
           (cVar6 = FUN_005943b0(), cVar6 == '\0')) {
          bVar4 = false;
        }
        else {
          bVar4 = true;
        }
        if ((bVar4) && (*(char *)(param_1 + 0x5c) != '\0')) {
          bVar5 = 1;
        }
        else {
          bVar5 = 0;
        }
        *(uint *)(param_1 + 0x48) = (-(uint)bVar5 & 0x2d0) + 0xb4;
        FUN_005a5430(0x1d);
        iVar14 = *(int *)(param_1 + 400);
        *piVar17 = *(int *)(iVar14 + 0x90);
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(iVar14 + 0x94);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(iVar14 + 0x98);
        iVar14 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
        if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
          iVar14 = -iVar14;
        }
        FUN_00590aa0(iVar14,0,0);
        puVar19 = (undefined4 *)FUN_00590ae0(auStack_9c,piVar17);
        uVar11 = FUN_005ee080(*puVar19,puVar19[1]);
        *(short *)(param_1 + 0x34) = (short)uVar11;
        *(short *)(param_1 + 100) = (short)uVar11;
        piVar13 = (int *)FUN_005ee0f0(0x6666,uVar11);
        iVar14 = *(int *)(param_1 + 400);
        iVar16 = *(int *)(iVar14 + 0x94);
        iVar1 = *(int *)(iVar14 + 0x98);
        iVar2 = piVar13[1];
        iVar3 = piVar13[2];
        *piVar17 = *(int *)(iVar14 + 0x90) - *piVar13;
        *(int *)(param_1 + 8) = iVar16 - iVar2;
        *(int *)(param_1 + 0xc) = iVar1 - iVar3;
        iVar14 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
        if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
          iVar14 = -iVar14;
        }
        FUN_00590aa0(iVar14,0,0);
      }
      else if (*(int *)(param_1 + 0x2b8) == *(int *)(*(int *)(iVar14 + 0x438) + 0x2b8)) {
        *piVar17 = *(int *)(param_1 + 0x1ec);
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x1f0);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 500);
      }
      else if (*(int *)(param_1 + 700) == 0) {
        FUN_005a5430(0x20);
        *piVar17 = *piVar15;
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x1e4);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 0x1e8);
        *piVar17 = *piVar17 +
                   (((-1 < *(int *)(*(int *)(param_1 + 400) + 0x90)) - 1 & 0xfffffffe) + 1) *
                   -0x5999;
      }
      else {
        *piVar17 = *piVar15;
        *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x1e4);
        *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 0x1e8);
      }
    }
    puVar19 = (undefined4 *)FUN_00590ae0(auStack_9c,piVar17);
    uVar8 = FUN_005ee080(*puVar19,puVar19[1]);
    *(undefined2 *)(param_1 + 0x34) = uVar8;
    *(undefined2 *)(param_1 + 100) = uVar8;
  }
  else {
    if (param_1 == 0) {
      puVar19 = (undefined4 *)0x0;
    }
    else {
      puVar19 = (undefined4 *)(param_1 + 0x40);
    }
    puVar18 = *(undefined4 **)(param_1 + 0x3b0);
    for (iVar14 = 0x51; iVar14 != 0; iVar14 = iVar14 + -1) {
      *puVar19 = *puVar18;
      puVar18 = puVar18 + 1;
      puVar19 = puVar19 + 1;
    }
    if (*(char *)(param_1 + 0x5c) != '\0') {
      iVar14 = *(int *)(*(int *)(param_1 + 0x184) + 0x168);
      if ((iVar14 != 0) && (iVar14 != param_1)) {
        *(undefined1 *)(iVar14 + 0x5c) = 0;
      }
      *(int *)(*(int *)(param_1 + 0x184) + 0x168) = param_1;
      if (param_1 == *(int *)(*(int *)(param_1 + 0x18c) + 0x438)) {
        *(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x45c) = *(undefined4 *)(param_1 + 0x2b8);
      }
    }
    if (param_1 == *(int *)(*(int *)(param_1 + 0x18c) + 0x438)) {
      uVar9 = -(uint)(*(int *)(param_1 + 700) == 0) & 0x1e;
      _DAT_00665154 = (&DAT_006650e0)[uVar9];
      _DAT_0066502c = (&DAT_00664fb8)[uVar9];
      _DAT_0067455c = (&DAT_006744e8)[uVar9];
      return;
    }
  }
switchD_005a380d_caseD_0:
  return;
}


