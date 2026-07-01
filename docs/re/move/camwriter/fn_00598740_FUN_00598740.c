// FUN_00598740  entry=00598740  size=6507 bytes

undefined4 __fastcall FUN_00598740(int param_1)

{
  int iVar1;
  byte bVar2;
  char cVar3;
  char *pcVar4;
  undefined1 *puVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 *puVar8;
  undefined2 uVar11;
  undefined4 uVar9;
  int iVar10;
  int iVar12;
  uint uVar13;
  uint uVar14;
  char cVar15;
  int *piVar16;
  undefined **ppuVar17;
  int iVar18;
  int iVar19;
  undefined4 *puVar20;
  bool bVar21;
  undefined4 uVar22;
  undefined4 uVar23;
  undefined4 uVar24;
  int iStack_44;
  undefined4 *local_40;
  int iStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined1 auStack_2c [12];
  undefined1 auStack_20 [12];
  undefined4 local_14;
  undefined4 uStack_10;
  undefined4 uStack_c;
  undefined4 uStack_8;
  
  iVar19 = *(int *)(*(int *)(param_1 + 0x468) + 0xfec);
  if (iVar19 == 0) {
LAB_005987a1:
    if (*(char *)(param_1 + 0x180d) != '\0') {
      *(undefined1 *)(param_1 + 0x180d) = 0;
      ppuVar17 = &PTR_s_ALIENTO_00663c40;
      do {
        ppuVar17 = ppuVar17 + 5;
        FUN_00590f40();
      } while ((int)ppuVar17 < 0x663f10);
    }
  }
  else if (*(char *)(param_1 + 0x180d) == '\0') {
    *(undefined1 *)(param_1 + 0x180c) = 1;
    *(undefined1 *)(param_1 + 0x180d) = 1;
    if ((*(char *)(param_1 + 0x180c) != '\0') &&
       (FUN_00590f00(), *(char *)(param_1 + 0x180c) != '\0')) {
      FUN_00590f00();
    }
  }
  else if (iVar19 == 0) goto LAB_005987a1;
  FUN_00593a30();
  cVar3 = *(char *)(param_1 + 0x1a1e);
  *(undefined1 *)(param_1 + 0x1a1e) = 0;
  if (cVar3 != '\0') {
    FUN_00593b70();
    goto LAB_0059a06e;
  }
  if ((DAT_006d31c4 == '\0') &&
     ((((*(int *)(param_1 + 0x448) == 7 ||
        ((*(int *)(param_1 + 0x448) == 5 && (*(int *)(param_1 + 0x19cc) != 0)))) &&
       (*(char *)(*(int *)(param_1 + 0x45c) * 800 + 0x759 + param_1) != '\0')) &&
      (cVar3 = *(char *)(param_1 + 0x1a20), *(undefined1 *)(param_1 + 0x1a20) = 1, cVar3 == '\0'))))
  {
    iVar19 = *(int *)(*(int *)(param_1 + 0x45c) * 800 + 0x470 + param_1);
    *(undefined4 *)(param_1 + 0x19b8) = 0;
    *(undefined4 *)(param_1 + 0x19bc) = 0;
    do {
      iVar12 = (*(int *)(param_1 + 0x19b8) + -1 + iVar19) % iVar19;
      *(int *)(param_1 + 0x19b8) = iVar12;
    } while (*(int *)(*(int *)(*(int *)(param_1 + 0x45c) * 800 + 0x46c + param_1) + 0x8c +
                     iVar12 * 0x3bc) != 0);
    iVar19 = *(int *)(param_1 + 0x45c) * 800 + param_1;
    iVar1 = *(int *)(iVar19 + 0x46c);
    iVar18 = *(int *)(iVar19 + 0x678) + 1;
    iVar10 = iVar18 * 4;
    FUN_005bbf10((int *)(iVar19 + 0x674),iVar10);
    *(int *)(iVar19 + 0x678) = iVar18;
    *(int *)(*(int *)(iVar19 + 0x674) + -4 + iVar10) = iVar1 + iVar12 * 0x3bc;
    uVar7 = FUN_005b8f20();
    *(undefined4 *)(param_1 + 0x438) = uVar7;
    iVar19 = 2;
    do {
      FUN_005b70e0();
      iVar19 = iVar19 + -1;
    } while (iVar19 != 0);
    iVar19 = 2;
    do {
      FUN_005b73a0();
      iVar19 = iVar19 + -1;
    } while (iVar19 != 0);
    goto LAB_0059a06e;
  }
  if (((*(char *)(param_1 + 0x1a20) != '\0') || (DAT_006d31c4 != '\0')) &&
     (*(int *)(param_1 + 0x27e8) <= *(int *)(param_1 + 0x27ec))) goto LAB_0059a06e;
  if (((*(int *)(param_1 + 0x448) == 0) && (*(int *)(param_1 + 0x19a0) != 4)) &&
     ((*(int *)(param_1 + 0x450) = *(int *)(param_1 + 0x450) + 1, *(char *)(param_1 + 0x450) == '\0'
      && (DAT_006d31c4 == '\0')))) {
    FUN_005946d0();
    FUN_00594410();
  }
  *(undefined2 *)(param_1 + 0x181c) = *(undefined2 *)(param_1 + 0x287c);
  if (DAT_006d31c4 == '\0') {
    if (DAT_00665d8c != '\0') {
      if (DAT_006d31bc == 0) {
        if (param_1 == 0) {
          local_40 = (undefined4 *)0x0;
        }
        else {
          local_40 = (undefined4 *)(param_1 + 0x434);
        }
        iVar19 = *(int *)(param_1 + 0x27e0) + 1;
        iVar12 = iVar19 * 0x30;
        FUN_005bbf10((int *)(param_1 + 0x27dc),iVar12);
        *(int *)(param_1 + 0x27e0) = iVar19;
        puVar20 = (undefined4 *)(*(int *)(param_1 + 0x27dc) + -0x30 + iVar12);
        for (iVar19 = 0xc; iVar19 != 0; iVar19 = iVar19 + -1) {
          *puVar20 = *local_40;
          local_40 = local_40 + 1;
          puVar20 = puVar20 + 1;
        }
      }
      puVar20 = (undefined4 *)FUN_005910c0(param_1);
      iVar19 = *(int *)(param_1 + 0x27e8) + 1;
      iVar12 = iVar19 * 0x14;
      FUN_005bbf10((int *)(param_1 + 0x27e4),iVar12);
      *(int *)(param_1 + 0x27e8) = iVar19;
      puVar8 = (undefined4 *)(*(int *)(param_1 + 0x27e4) + -0x14 + iVar12);
      for (iVar19 = 5; iVar19 != 0; iVar19 = iVar19 + -1) {
        *puVar8 = *puVar20;
        puVar20 = puVar20 + 1;
        puVar8 = puVar8 + 1;
      }
    }
  }
  else {
    if (DAT_006d31bc == 0) {
      if (param_1 == 0) {
        puVar20 = (undefined4 *)0x0;
      }
      else {
        puVar20 = (undefined4 *)(param_1 + 0x434);
      }
      puVar8 = (undefined4 *)(DAT_006d31c0 * 0x30 + *(int *)(param_1 + 0x27dc));
      for (iVar19 = 0xc; iVar19 != 0; iVar19 = iVar19 + -1) {
        *puVar20 = *puVar8;
        puVar8 = puVar8 + 1;
        puVar20 = puVar20 + 1;
      }
    }
    FUN_00591120(param_1);
  }
  pcVar4 = (char *)(param_1 + 0x67d);
  iVar19 = 2;
  do {
    if (((pcVar4[-1] == '\0') && (*pcVar4 == '\0')) && ((pcVar4[1] == '\0' && (pcVar4[2] == '\0'))))
    {
      *(int *)(pcVar4 + 0xcb) = *(int *)(pcVar4 + 0xcb) + 1;
    }
    else {
      pcVar4[0xcb] = '\0';
      pcVar4[0xcc] = '\0';
      pcVar4[0xcd] = '\0';
      pcVar4[0xce] = '\0';
    }
    pcVar4 = pcVar4 + 800;
    iVar19 = iVar19 + -1;
  } while (iVar19 != 0);
  FUN_005b8bf0();
  FUN_005b8bf0();
  (**(code **)(*(int *)(param_1 + 0x1610) + 8))();
  (**(code **)(*(int *)(param_1 + 0xaac) + 8))();
  (**(code **)(*(int *)(param_1 + 0xe74) + 8))();
  (**(code **)(*(int *)(param_1 + 0x123c) + 8))();
  FUN_005b8690();
  FUN_005b8690();
  FUN_005b94f0();
  FUN_005b94f0();
  FUN_005b8c20();
  FUN_005b8c20();
  (**(code **)(*(int *)(param_1 + 0x1610) + 0xc))();
  (**(code **)(*(int *)(param_1 + 0xaac) + 0xc))();
  (**(code **)(*(int *)(param_1 + 0xe74) + 0xc))();
  (**(code **)(*(int *)(param_1 + 0x123c) + 0xc))();
  iVar19 = 2;
  do {
    FUN_005b8ce0(0);
    iVar19 = iVar19 + -1;
  } while (iVar19 != 0);
  uVar13 = (int)(DAT_006d31bc + 1U) >> 0x1f;
  DAT_006d31bc = ((DAT_006d31bc + 1U ^ uVar13) - uVar13 & 0x3ff ^ uVar13) - uVar13;
  if (DAT_006d31c4 != '\0') {
    if (DAT_006d31bc == 0) {
      DAT_006d31c0 = DAT_006d31c0 + 1;
    }
    *(int *)(param_1 + 0x27ec) = *(int *)(param_1 + 0x27ec) + 1;
  }
  if (*(int *)(param_1 + 0x448) != 0) goto switchD_005997d5_default;
  if (1 < *(byte *)(param_1 + 0x460)) {
    *(byte *)(param_1 + 0x460) = *(byte *)(param_1 + 0x460) - 1;
  }
  if ((*(int *)(param_1 + 0x43c) != 0) && (*(byte *)(param_1 + 0x460) < 2)) {
    if (((*(byte *)(param_1 + 0x461) & 2) != 0) && (DAT_006d31c4 == '\0')) {
      *(int *)(param_1 + 0x19d0) = *(int *)(param_1 + 0x19d0) + 1;
    }
    if (*(char *)(*(int *)(param_1 + 0x43c) + 0x2d9) != '\0') {
      *(byte *)(param_1 + 0x461) = *(byte *)(param_1 + 0x461) | 4;
    }
    *(int *)(param_1 + 0x45c) = 1 - *(int *)(*(int *)(param_1 + 0x43c) + 0x2b8);
    iVar19 = *(int *)(*(int *)(param_1 + 0x43c) + 0x18c);
    if ((*(byte *)(iVar19 + 0x461) & 1) == 0) {
      puVar5 = (undefined1 *)(*(int *)(param_1 + 0x43c) + 4);
    }
    else {
      uVar7 = FUN_00590aa0(0xb0000 - *(int *)(iVar19 + 0x1820),0,0);
      FUN_0059a0e0(auStack_20,uVar7);
      puVar5 = auStack_20;
    }
    FUN_00590ac0(puVar5);
    FUN_0059a1e0(auStack_2c,0x5f);
    FUN_00590ac0(auStack_2c);
    *(int *)(param_1 + 0x16a0) = iStack_38;
    *(undefined4 *)(param_1 + 0x16a4) = uStack_34;
    *(undefined4 *)(param_1 + 0x16a8) = uStack_30;
    iVar19 = *(int *)(param_1 + 0x43c);
    cVar3 = FUN_0059a120(iVar19 + 4);
    if (cVar3 == '\0') {
      cVar3 = FUN_0059a120(iVar19 + 4);
      if (cVar3 == '\0') {
        iVar12 = 0x134000 - *(int *)(*(int *)(iVar19 + 0x18c) + 0x1820);
        if (*(uint *)(iVar19 + 0x2b8) != (*(uint *)(*(int *)(iVar19 + 0x18c) + 0x19a0) & 1)) {
          iVar12 = -iVar12;
        }
        uVar24 = 0x640000;
        uVar23 = 0x1a28f5;
        uVar22 = 0x54000;
        uVar7 = FUN_00590aa0(iVar12,0,0);
        cVar3 = FUN_005a1820(uVar7,uVar22,uVar23,uVar24);
        if (cVar3 == '\0') goto LAB_00598dbc;
        bVar21 = true;
      }
      else {
LAB_00598dbc:
        bVar21 = false;
      }
      if (bVar21) goto LAB_00598e18;
      iVar12 = 0x164000 - *(int *)(*(int *)(iVar19 + 0x18c) + 0x1820);
      if (*(uint *)(iVar19 + 0x2b8) != (*(uint *)(*(int *)(iVar19 + 0x18c) + 0x19a0) & 1)) {
        iVar12 = -iVar12;
      }
      uVar24 = 0x640000;
      uVar23 = 0x2028f5;
      uVar22 = 0x84000;
      uVar7 = FUN_00590aa0(iVar12,0,0);
      cVar3 = FUN_005a1820(uVar7,uVar22,uVar23,uVar24);
      if (cVar3 == '\0') goto LAB_00598e18;
      bVar21 = true;
    }
    else {
LAB_00598e18:
      bVar21 = false;
    }
    if (bVar21) {
      uVar13 = 2;
    }
    else {
      iVar19 = *(int *)(param_1 + 0x43c);
      cVar3 = FUN_0059a120(iVar19 + 4);
      if (cVar3 == '\0') {
        iStack_38 = 0x134000 - *(int *)(*(int *)(iVar19 + 0x18c) + 0x1820);
        if (*(uint *)(iVar19 + 0x2b8) != (*(uint *)(*(int *)(iVar19 + 0x18c) + 0x19a0) & 1)) {
          iStack_38 = -iStack_38;
        }
        uStack_34 = 0;
        uStack_30 = 0;
        cVar3 = FUN_005a1820(&iStack_38,0x54000,0x1a28f5,0x640000);
        if (cVar3 == '\0') goto LAB_00598e97;
        bVar21 = true;
      }
      else {
LAB_00598e97:
        bVar21 = false;
      }
      if (bVar21) {
        uVar13 = 6;
      }
      else {
        iVar19 = *(int *)(param_1 + 0x43c);
        cVar3 = FUN_0059a120(iVar19 + 4);
        if (cVar3 == '\0') {
          iStack_38 = 0xa8000 - *(int *)(*(int *)(iVar19 + 0x18c) + 0x1820);
          if (*(uint *)(iVar19 + 0x2b8) != (*(uint *)(*(int *)(iVar19 + 0x18c) + 0x19a0) & 1)) {
            iStack_38 = -iStack_38;
          }
          uStack_34 = 0;
          uStack_30 = 0;
          cVar3 = FUN_005a1820(&iStack_38,0x38000,0x640000,0x640000);
          if (cVar3 == '\0') goto LAB_00598f16;
          bVar21 = true;
        }
        else {
LAB_00598f16:
          bVar21 = false;
        }
        if (bVar21) {
          uVar13 = 2;
        }
        else {
          iVar19 = *(int *)(param_1 + 0x43c);
          cVar3 = FUN_0059a120(iVar19 + 4);
          if (cVar3 == '\0') {
            iStack_38 = 0x38000 - *(int *)(*(int *)(iVar19 + 0x18c) + 0x1820);
            if (*(uint *)(iVar19 + 0x2b8) != (*(uint *)(*(int *)(iVar19 + 0x18c) + 0x19a0) & 1)) {
              iStack_38 = -iStack_38;
            }
            uStack_34 = 0;
            uStack_30 = 0;
            cVar3 = FUN_005a1820(&iStack_38,0x38000,0x640000,0x640000);
            if (cVar3 == '\0') goto LAB_00598f92;
            bVar2 = 1;
          }
          else {
LAB_00598f92:
            bVar2 = 0;
          }
          uVar13 = (uint)bVar2;
        }
      }
    }
    *(uint *)(param_1 + 0x19cc) = uVar13;
    if (*(char *)(param_1 + 0x180a) != '\0') {
      FUN_00590f00();
    }
    if (*(char *)(*(int *)(*(int *)(param_1 + 0x43c) + 0x184) + 0x2ec) != '\0') {
      if ((*(byte *)(param_1 + 0x461) & 4) == 0) {
        if ((*(byte *)(param_1 + 0x461) & 2) == 0) goto LAB_00599000;
        cVar3 = *(char *)(param_1 + 0x180c);
      }
      else {
        cVar3 = *(char *)(param_1 + 0x180c);
      }
      if (cVar3 != '\0') {
        FUN_00590f00();
      }
    }
LAB_00599000:
    FUN_005966d0((*(byte *)(param_1 + 0x461) & 1) << 1 | 5);
    goto switchD_005997d5_default;
  }
  cVar3 = FUN_0058f100();
  if ((cVar3 == '\0') && (cVar3 = FUN_0058ede0(), cVar3 != '\0')) {
    iVar19 = *(int *)(param_1 + 0x1658);
    *(int *)(param_1 + 0x444) = iVar19;
    iVar12 = *(int *)(param_1 + 0x1824);
    iStack_44 = 0;
    local_40 = (undefined4 *)0x1;
    piVar16 = (int *)(param_1 + 0x478);
    *(uint *)(iVar19 + 0x1e0) =
         (*(int *)(param_1 + 0x1820) + -0x50000) *
         (((-1 < *(int *)(iVar19 + 4)) - 1 & 0xfffffffe) + 1);
    *(uint *)(iVar19 + 0x1e4) =
         -((iVar12 + -0x50000) * (((-1 < *(int *)(iVar19 + 8)) - 1 & 0xfffffffe) + 1));
    *(undefined4 *)(iVar19 + 0x1e8) = 0;
    do {
      cVar3 = FUN_0058f0b0(iStack_44);
      if (cVar3 != '\0') {
        local_14 = 0;
        uStack_10 = 0;
        bVar21 = iStack_44 != *(int *)(*(int *)(param_1 + 0x444) + 0x2b8);
        uStack_c = 0;
        uStack_8 = 0;
        if ((bVar21) || (*(int *)(*(int *)(param_1 + 0x444) + 0x48) != 0)) {
          cVar3 = '\0';
        }
        else {
          cVar3 = '\x01';
        }
        *(byte *)(param_1 + 0x461) = cVar3 << 6 | *(byte *)(param_1 + 0x461) & 0x3f | cVar3 << 7;
        if (DAT_006d31c4 == '\0') {
          uStack_8 = CONCAT22(*(undefined2 *)(*(int *)(param_1 + 0x444) + 0x2c0),
                              *(undefined2 *)
                               (*(int *)(*(int *)(*(int *)(param_1 + 0x444) + 0x184) + 0x9c) + 0x790
                               ));
          FUN_004510b0(*(undefined4 *)(param_1 + 0x19a0),
                       (*(int *)(param_1 + 0x450) * 0x2d) / *(int *)(param_1 + 0x19ac),bVar21,
                       uStack_8);
        }
        *(undefined4 **)(param_1 + 0x45c) = local_40;
        if (*(int *)(param_1 + 0x19a0) == 4) {
          if (DAT_006d31c4 == '\0') {
            piVar16[1] = piVar16[1] + 1;
            *(int *)(param_1 + 0x19c0) = *(int *)(param_1 + 0x19c0) + 1;
            iVar19 = *(int *)(param_1 + 0x19c4) % 10;
            *(int *)(param_1 + 0x19c4) = iVar19;
            *(undefined1 *)(iVar19 + 0x1a04 + param_1) = 1;
            *(int *)(param_1 + 0x19c4) = *(int *)(param_1 + 0x19c4) + 1;
          }
          uVar13 = *(uint *)(param_1 + 0x19c0);
          uVar14 = (int)uVar13 >> 0x1f;
          if ((int)uVar13 < 0xb) {
            if (((*(int *)(param_1 + 0x79c) - (int)uVar13 / 2) + 5 < *(int *)(param_1 + 0x47c)) ||
               ((*(int *)(param_1 + 0x47c) - (int)(uVar13 + 1) / 2) + 5 < *(int *)(param_1 + 0x79c))
               ) {
              bVar21 = true;
            }
            else {
              bVar21 = false;
            }
          }
          else if ((((uVar13 ^ uVar14) - uVar14 & 1 ^ uVar14) == uVar14) &&
                  (*(int *)(param_1 + 0x47c) != *(int *)(param_1 + 0x79c))) {
            bVar21 = true;
          }
          else {
            bVar21 = false;
          }
          if (bVar21) {
            *(undefined4 *)(*(int *)(param_1 + 0x468) + 0x24) = 1;
            FUN_005966d0(1);
            uVar7 = FUN_005ec240();
            if (*(char *)(param_1 + 0x180b) != '\0') {
              FUN_004ec1e0(0,0,0,0,CONCAT22((short)((uint)*(int *)(param_1 + 0x828) >> 0x10),
                                            *(undefined2 *)(*(int *)(param_1 + 0x508) + 0x790)),
                           CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x798) >> 0x10),
                                    *(undefined2 *)(*(int *)(param_1 + 0x828) + 0x790)),
                           *(undefined4 *)(param_1 + 0x478),*(undefined4 *)(param_1 + 0x798),0);
            }
            FUN_005ec230(uVar7);
            goto LAB_00599397;
          }
          *(byte *)(param_1 + 0x461) = *(byte *)(param_1 + 0x461) & 0x3f;
        }
        else {
          if (DAT_006d31c4 == '\0') {
            *piVar16 = *piVar16 + 1;
            cVar3 = FUN_005943f0();
            if (cVar3 == '\0') {
              puVar20 = (undefined4 *)(param_1 + 0x19b0);
              puVar8 = (undefined4 *)(param_1 + 0x478);
              iVar19 = 2;
              do {
                uVar7 = *puVar8;
                puVar8 = puVar8 + 200;
                *puVar20 = uVar7;
                puVar20 = puVar20 + 1;
                iVar19 = iVar19 + -1;
              } while (iVar19 != 0);
            }
          }
          if ((char)piVar16[0xb8] == '\0') {
            cVar3 = *(char *)(param_1 + 0x180c);
          }
          else {
            FUN_005ec250();
            cVar3 = *(char *)(param_1 + 0x180c);
          }
          if (cVar3 != '\0') {
            FUN_00590f00();
          }
        }
        FUN_005966d0(6);
      }
LAB_00599397:
      piVar16 = piVar16 + 200;
      iStack_44 = iStack_44 + 1;
      local_40 = (undefined4 *)((int)local_40 - 1);
    } while (local_40 < 0x80000000);
    goto switchD_005997d5_default;
  }
  if (*(int *)(param_1 + 0x19a0) == 4) {
    cVar3 = FUN_0058f140();
    if ((cVar3 == '\0') && (cVar3 = FUN_0058f100(), cVar3 == '\0')) {
      iVar19 = *(int *)(param_1 + 0x1820);
      if (*(uint *)(param_1 + 0x45c) == (*(uint *)(param_1 + 0x19a0) & 1)) {
        iVar19 = -iVar19;
      }
      if (((-1 < *(int *)(param_1 + 0x1630)) - 1 & 0xfffffffe) + 1 !=
          ((-1 < iVar19) - 1 & 0xfffffffe) + 1) {
        if (((*(int *)(param_1 + 0x1630) == 0) && (*(int *)(param_1 + 0x1634) == 0)) &&
           (*(int *)(param_1 + 0x1638) == 0)) {
          bVar21 = true;
        }
        else {
          bVar21 = false;
        }
        if ((!bVar21) || (*(int *)(param_1 + 0x1650) != 0)) goto switchD_005997d5_default;
      }
    }
    *(int *)(param_1 + 0x45c) = 1 - *(int *)(param_1 + 0x45c);
    if (DAT_006d31c4 == '\0') {
      *(int *)(param_1 + 0x19c0) = *(int *)(param_1 + 0x19c0) + 1;
      iVar19 = *(int *)(param_1 + 0x19c4) % 10;
      *(int *)(param_1 + 0x19c4) = iVar19;
      *(undefined1 *)(iVar19 + 0x1a04 + param_1) = 0;
      *(int *)(param_1 + 0x19c4) = *(int *)(param_1 + 0x19c4) + 1;
    }
    uVar13 = *(uint *)(param_1 + 0x19c0);
    uVar14 = (int)uVar13 >> 0x1f;
    if ((int)uVar13 < 0xb) {
      if ((*(int *)(param_1 + 0x79c) - (int)uVar13 / 2) + 5 < *(int *)(param_1 + 0x47c)) {
LAB_00599519:
        bVar21 = true;
      }
      else {
        if (*(int *)(param_1 + 0x79c) <= (*(int *)(param_1 + 0x47c) - (int)(uVar13 + 1) / 2) + 5)
        goto LAB_00599520;
        bVar21 = true;
      }
    }
    else {
      if ((((uVar13 ^ uVar14) - uVar14 & 1 ^ uVar14) == uVar14) &&
         (*(int *)(param_1 + 0x47c) != *(int *)(param_1 + 0x79c))) goto LAB_00599519;
LAB_00599520:
      bVar21 = false;
    }
    if (bVar21) {
      *(undefined4 *)(*(int *)(param_1 + 0x468) + 0x24) = 1;
      FUN_005966d0(1);
      uVar7 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) == '\0') goto LAB_0059993a;
      FUN_004ec1e0(0,0,0,0,CONCAT22((short)((uint)*(int *)(param_1 + 0x828) >> 0x10),
                                    *(undefined2 *)(*(int *)(param_1 + 0x508) + 0x790)),
                   CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x798) >> 0x10),
                            *(undefined2 *)(*(int *)(param_1 + 0x828) + 0x790)),
                   *(undefined4 *)(param_1 + 0x478),*(undefined4 *)(param_1 + 0x798),0);
      FUN_005ec230(uVar7);
    }
    else {
LAB_005996d2:
      FUN_005966d0(3);
    }
    goto switchD_005997d5_default;
  }
  cVar3 = FUN_0058fbe0();
  if (cVar3 != '\0') {
    iVar19 = 1 - *(int *)(param_1 + 0x1664);
    *(int *)(param_1 + 0x45c) = iVar19;
    if (DAT_006d31c4 == '\0') {
      iVar19 = iVar19 * 800;
      *(int *)(iVar19 + 0x480 + param_1) = *(int *)(iVar19 + 0x480 + param_1) + 1;
    }
    if (*(char *)(param_1 + 0x180a) != '\0') {
      FUN_00590f00();
    }
    FUN_005966d0(4);
    goto switchD_005997d5_default;
  }
  cVar3 = FUN_0058f100();
  if ((cVar3 != '\0') && (*(int *)(*(int *)(param_1 + 0x1650) + 0x40) == 0x1f)) {
    *(undefined4 *)(param_1 + 0x45c) = *(undefined4 *)(param_1 + 0x1664);
    FUN_005942e0(6);
    *(undefined4 *)(param_1 + 0x19dc) = 0x6a4;
    iVar19 = *(int *)(*(int *)(param_1 + 0x45c) * 800 + 0x46c + param_1);
    *(int *)(param_1 + 0x438) = iVar19;
    if ((*(char *)(*(int *)(iVar19 + 0x184) + 0x2ee) == '\0') ||
       (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
      bVar21 = false;
    }
    else {
      bVar21 = true;
    }
    if ((bVar21) && (*(char *)(iVar19 + 0x5c) != '\0')) {
      bVar2 = 1;
    }
    else {
      bVar2 = 0;
    }
    *(uint *)(*(int *)(param_1 + 0x438) + 0x48) = (-(uint)bVar2 & 0x2d0) + 0xb4;
    goto switchD_005997d5_default;
  }
  cVar3 = FUN_0058f3c0();
  if (cVar3 != '\0') {
    *(int *)(param_1 + 0x45c) = 1 - *(int *)(param_1 + 0x1664);
    goto LAB_005996d2;
  }
  cVar3 = FUN_0058f140();
  if (cVar3 != '\0') {
    *(int *)(param_1 + 0x45c) = 1 - *(int *)(param_1 + 0x1664);
    FUN_005966d0(2);
    goto switchD_005997d5_default;
  }
  iVar19 = *(int *)(param_1 + 0x19a0);
  if (3 < iVar19) goto switchD_005997d5_default;
  iVar12 = *(int *)(param_1 + 0x19ac);
  iVar10 = iVar12;
  if (1 < iVar19) {
    iVar10 = iVar12 / 3;
  }
  iVar10 = *(int *)(param_1 + 0x450) - iVar10;
  if ((iVar10 < 0) ||
     ((uVar13 = (int)*(uint *)(param_1 + 0x1614) >> 0x1f,
      *(int *)(param_1 + 0x1820) + -0x1e0000 <=
      (int)((*(uint *)(param_1 + 0x1614) ^ uVar13) - uVar13) && (iVar10 <= iVar12 / 9))))
  goto switchD_005997d5_default;
  if (iVar19 == 2) {
    *(undefined4 *)(*(int *)(param_1 + 0x468) + 0x20) = 1;
  }
  *(uint *)(param_1 + 0x45c) = 1U - *(int *)(param_1 + 0x19c8) ^ *(uint *)(param_1 + 0x19a0) & 1;
  FUN_005966d0(1);
  if (*(char *)(param_1 + 0x180a) != '\0') {
    FUN_00590f00();
  }
  switch(*(undefined4 *)(param_1 + 0x19a0)) {
  case 0:
    uVar7 = FUN_005ec240();
    if (*(char *)(param_1 + 0x180b) == '\0') goto LAB_0059993a;
    FUN_004eb4a0(0x2d,CONCAT22((short)((uint)*(int *)(param_1 + 0x828) >> 0x10),
                               *(undefined2 *)(*(int *)(param_1 + 0x508) + 0x790)),
                 CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x798) >> 0x10),
                          *(undefined2 *)(*(int *)(param_1 + 0x828) + 0x790)),
                 *(undefined4 *)(param_1 + 0x478),*(undefined4 *)(param_1 + 0x798));
    FUN_005ec230(uVar7);
    break;
  case 1:
    iVar19 = FUN_00450e60();
    if ((iVar19 == 0) && (iVar19 = *(int *)(param_1 + 0x468), *(int *)(iVar19 + 0x44) != 0)) {
      bVar21 = true;
      if ((*(int *)(iVar19 + 0x2c) != 0xff) || (*(int *)(iVar19 + 0x30) != 0xff)) goto LAB_00599875;
      cVar15 = '\x01';
    }
    else {
      bVar21 = false;
LAB_00599875:
      cVar15 = '\0';
    }
    uVar7 = FUN_005ec240();
    if (*(char *)(param_1 + 0x180b) != '\0') {
      if ((bVar21) && (cVar15 == '\0')) {
        uVar24 = 1;
      }
      else {
        uVar24 = 0;
      }
      uVar22 = *(undefined4 *)(param_1 + 0x798);
      uVar23 = *(undefined4 *)(param_1 + 0x478);
      uVar11 = (undefined2)((uint)uVar23 >> 0x10);
      uVar6 = CONCAT22(uVar11,*(undefined2 *)(*(int *)(param_1 + 0x828) + 0x790));
      uVar9 = CONCAT22(uVar11,*(undefined2 *)(*(int *)(param_1 + 0x508) + 0x790));
      cVar3 = '\0';
      bVar21 = false;
LAB_005999c8:
      FUN_004ec1e0(cVar15,uVar24,bVar21,cVar3,uVar9,uVar6,uVar23,uVar22,0);
    }
    goto LAB_005999cd;
  case 2:
    uVar7 = FUN_005ec240();
    if (*(char *)(param_1 + 0x180b) != '\0') {
      FUN_004eb4a0(0xf,CONCAT22((short)((uint)*(int *)(param_1 + 0x828) >> 0x10),
                                *(undefined2 *)(*(int *)(param_1 + 0x508) + 0x790)),
                   CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x798) >> 0x10),
                            *(undefined2 *)(*(int *)(param_1 + 0x828) + 0x790)),
                   *(undefined4 *)(param_1 + 0x478),*(undefined4 *)(param_1 + 0x798));
    }
LAB_0059993a:
    FUN_005ec230(uVar7);
    break;
  case 3:
    iVar19 = FUN_00450e60();
    if ((iVar19 == 0) && (*(int *)(*(int *)(param_1 + 0x468) + 0x48) != 0)) {
      cVar3 = '\x01';
    }
    else {
      cVar3 = '\0';
    }
    uVar7 = FUN_005ec240();
    if (*(char *)(param_1 + 0x180b) != '\0') {
      uVar22 = *(undefined4 *)(param_1 + 0x798);
      uVar23 = *(undefined4 *)(param_1 + 0x478);
      uVar6 = CONCAT22((short)((uint)uVar22 >> 0x10),
                       *(undefined2 *)(*(int *)(param_1 + 0x828) + 0x790));
      uVar9 = CONCAT22((short)((uint)*(int *)(param_1 + 0x828) >> 0x10),
                       *(undefined2 *)(*(int *)(param_1 + 0x508) + 0x790));
      bVar21 = cVar3 == '\0';
      uVar24 = 0;
      cVar15 = '\0';
      goto LAB_005999c8;
    }
LAB_005999cd:
    FUN_005ec230(uVar7);
  }
switchD_005997d5_default:
  if (*(int *)(param_1 + 0x448) == 0) {
    iVar12 = ((*(int *)(param_1 + 0x450) * 0x2d) / *(int *)(param_1 + 0x19ac)) / 0xf;
    iVar19 = *(int *)(param_1 + 0x1820);
    if (1U - *(int *)(param_1 + 0x1664) == (*(uint *)(param_1 + 0x19a0) & 1)) {
      iVar19 = -iVar19;
    }
    uVar13 = *(int *)(param_1 + 0x1614) - iVar19;
    uVar14 = (int)uVar13 >> 0x1f;
    iVar10 = (uVar13 ^ uVar14) - uVar14;
    uVar13 = (int)*(uint *)(param_1 + 0x1618) >> 0x1f;
    iVar19 = (int)((*(uint *)(param_1 + 0x1618) ^ uVar13) - uVar13) / 3;
    if (iVar10 <= iVar19) {
      iVar10 = iVar19;
    }
    uVar13 = 100 - (iVar10 * 100) / 0x280000;
    uVar13 = ((int)uVar13 < 0) - 1 & uVar13;
    if (((((int)*(uint *)(param_1 + 0x19a0) < 2) && (*(int *)(param_1 + 0x19a4) != iVar12)) &&
        (iVar12 != 3)) &&
       ((*(int *)(param_1 + 0x19a4) = iVar12, iVar12 < 4 &&
        (uVar14 = (int)*(uint *)(param_1 + 0x1614) >> 0x1f,
        (int)((*(uint *)(param_1 + 0x1614) ^ uVar14) - uVar14) <
        *(int *)(param_1 + 0x1820) + -0x200000)))) {
      uVar7 = FUN_005ec240();
      if (*(char *)(param_1 + 0x180b) != '\0') {
        FUN_004eb4a0((iVar12 + *(int *)(param_1 + 0x19a0) * 3) * 0xf,
                     CONCAT22((short)((uint)*(int *)(param_1 + 0x828) >> 0x10),
                              *(undefined2 *)(*(int *)(param_1 + 0x508) + 0x790)),
                     CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x19b4) >> 0x10),
                              *(undefined2 *)(*(int *)(param_1 + 0x828) + 0x790)),
                     *(undefined4 *)(param_1 + 0x19b0),*(undefined4 *)(param_1 + 0x19b4));
      }
      FUN_005ec230(uVar7);
    }
    if ((int)uVar13 < 0x19) {
      uVar13 = 0;
    }
    else if ((int)uVar13 < 0x32) {
      uVar13 = uVar13 * 2 - 0x32;
    }
    if ((int)uVar13 < 0x4c) {
      if (0x32 < (int)uVar13) {
        uVar13 = uVar13 * 2 - 0x32;
      }
    }
    else {
      uVar13 = 100;
    }
    *(uint *)(param_1 + 0x19e0) =
         ((((int)uVar13 <= *(int *)(param_1 + 0x19e0)) - 1 & 2) - 1) + *(int *)(param_1 + 0x19e0);
    FUN_00590f60(*(undefined1 *)(param_1 + 0x19e0));
    FUN_00590f60(100 - *(int *)(param_1 + 0x19e0));
    iVar19 = *(int *)(param_1 + 0x19e4) + -1;
    *(int *)(param_1 + 0x19e4) = iVar19;
    if (iVar19 < 1) {
      iVar19 = FUN_005ec250();
      *(int *)(param_1 + 0x19e4) = (int)(iVar19 * 0x708 + (iVar19 * 0x708 >> 0x1f & 0x7fffU)) >> 0xf
      ;
      iVar19 = FUN_005ec250();
      if ((int)(iVar19 * 1000 + (iVar19 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 500) {
        iVar19 = *(int *)(param_1 + 0x19e0) / 2;
        if (iVar19 < 0x8000) {
          iVar12 = FUN_005ec250();
          iVar19 = (int)(iVar12 * iVar19 + (iVar12 * iVar19 >> 0x1f & 0x7fffU)) >> 0xf;
        }
        else {
          iVar12 = FUN_005ec250();
          iVar12 = ((int)(iVar19 + (iVar19 >> 0x1f & 0xffU)) >> 8) * iVar12;
          iVar19 = (int)(iVar12 + (iVar12 >> 0x1f & 0x7fU)) >> 7;
        }
        FUN_00590f60(CONCAT31((int3)((uint)iVar19 >> 8),(char)iVar19 + '2'));
        cVar3 = *(char *)(param_1 + 0x180c);
      }
      else {
        iVar19 = *(int *)(param_1 + 0x19e0) / 2;
        if (iVar19 < 0x8000) {
          iVar12 = FUN_005ec250();
          iVar19 = (int)(iVar12 * iVar19 + (iVar12 * iVar19 >> 0x1f & 0x7fffU)) >> 0xf;
        }
        else {
          iVar12 = FUN_005ec250();
          iVar12 = ((int)(iVar19 + (iVar19 >> 0x1f & 0xffU)) >> 8) * iVar12;
          iVar19 = (int)(iVar12 + (iVar12 >> 0x1f & 0x7fU)) >> 7;
        }
        FUN_00590f60(CONCAT31((int3)((uint)iVar19 >> 8),(char)iVar19 + '2'));
        cVar3 = *(char *)(param_1 + 0x180c);
      }
      if (cVar3 != '\0') {
        FUN_00590f00();
      }
    }
    iVar19 = *(int *)(param_1 + 0x19e8) + -1;
    *(int *)(param_1 + 0x19e8) = iVar19;
    if (iVar19 < 1) {
      if (*(char *)(param_1 + 0xa78) == '\0') {
        iVar19 = *(int *)(param_1 + 0x478) - *(int *)(param_1 + 0x798);
      }
      else {
        iVar19 = 0;
      }
      iVar12 = FUN_005ec250();
      *(int *)(param_1 + 0x19e8) = (int)(iVar12 * 0xe10 + (iVar12 * 0xe10 >> 0x1f & 0x7fffU)) >> 0xf
      ;
      if ((iVar19 < -1) ||
         (iVar12 = FUN_005ec250(),
         (iVar19 + 2) * 300 <= (int)(iVar12 * 1000 + (iVar12 * 1000 >> 0x1f & 0x7fffU)) >> 0xf))
      goto switchD_00599d9d_default;
      iVar19 = FUN_005ec250();
      switch((int)(iVar19 * 7 + (iVar19 * 7 >> 0x1f & 0x7fffU)) >> 0xf) {
      case 0:
        if (*(char *)(param_1 + 0x180c) == '\0') goto switchD_00599d9d_default;
        goto LAB_00599e19;
      case 1:
        cVar3 = *(char *)(param_1 + 0x180c);
        break;
      case 2:
        cVar3 = *(char *)(param_1 + 0x180c);
        break;
      case 3:
        cVar3 = *(char *)(param_1 + 0x180c);
        break;
      case 4:
        cVar3 = *(char *)(param_1 + 0x180c);
        break;
      case 5:
        cVar3 = *(char *)(param_1 + 0x180c);
        break;
      case 6:
        cVar3 = *(char *)(param_1 + 0x180c);
        break;
      default:
        goto switchD_00599d9d_default;
      }
      if (cVar3 != '\0') {
LAB_00599e19:
        FUN_00590f00();
      }
    }
switchD_00599d9d_default:
    if (((((*(byte *)(param_1 + 0x461) & 0x80) == 0) && (*(int *)(param_1 + 0x19a0) != 4)) &&
        (*(int *)(param_1 + 0x448) == 0)) &&
       (((iVar19 = (*(int *)(param_1 + 0x450) * 0x2d) / *(int *)(param_1 + 0x19ac), 5 < iVar19 &&
         (iVar19 < 0x2a)) &&
        ((iVar19 = *(int *)(param_1 + 0x19ec) + -1, *(int *)(param_1 + 0x19ec) = iVar19, iVar19 < 1
         && ((uVar13 = (int)*(uint *)(param_1 + 0x1614) >> 0x1f,
             (int)((*(uint *)(param_1 + 0x1614) ^ uVar13) - uVar13) < 0xe0000 &&
             (iVar19 = FUN_005e2750(), iVar19 == 0)))))))) {
      uVar13 = *(int *)(param_1 + 0x478) - *(int *)(param_1 + 0x798);
      iVar12 = ((*(int *)(param_1 + 0x754) - *(int *)(param_1 + 0x19f4)) - *(int *)(param_1 + 0xa74)
               ) + *(int *)(param_1 + 0x19f8);
      iVar10 = ((*(int *)(param_1 + 0x750) - *(int *)(param_1 + 0xa70)) - *(int *)(param_1 + 0x19fc)
               ) + *(int *)(param_1 + 0x1a00);
      iVar19 = FUN_005ec250();
      *(int *)(param_1 + 0x19ec) =
           ((int)(iVar19 * 0x960 + (iVar19 * 0x960 >> 0x1f & 0x7fffU)) >> 0xf) + 900;
      if (uVar13 == *(uint *)(param_1 + 0x19f0)) {
        if ((((uVar13 == 0) || (uVar13 == 1)) && (0 < iVar12)) && (0 < iVar10)) {
          uVar7 = FUN_005ec240();
          if (*(char *)(param_1 + 0x180b) != '\0') {
            FUN_004e9e00();
          }
        }
        else {
          if (((uVar13 != 0) && (uVar13 != 0xffffffff)) || ((-1 < iVar12 || (-1 < iVar10))))
          goto LAB_0059a00a;
          uVar7 = FUN_005ec240();
          if (*(char *)(param_1 + 0x180b) != '\0') {
            thunk_FUN_004e9e00();
          }
        }
LAB_0059a001:
        FUN_005ec230(uVar7);
      }
      else if (2 < (int)((uVar13 ^ (int)uVar13 >> 0x1f) - ((int)uVar13 >> 0x1f))) {
        if ((int)uVar13 < 2) {
          if (-2 < (int)uVar13) goto LAB_0059a00a;
          uVar7 = FUN_005ec240();
          if (*(char *)(param_1 + 0x180b) != '\0') {
            FUN_004e9f40();
          }
        }
        else {
          uVar7 = FUN_005ec240();
          if (*(char *)(param_1 + 0x180b) != '\0') {
            FUN_004ea070();
          }
        }
        goto LAB_0059a001;
      }
LAB_0059a00a:
      *(undefined4 *)(param_1 + 0x19f4) = *(undefined4 *)(param_1 + 0x754);
      *(uint *)(param_1 + 0x19f0) = uVar13;
      *(undefined4 *)(param_1 + 0x19f8) = *(undefined4 *)(param_1 + 0xa74);
      *(undefined4 *)(param_1 + 0x19fc) = *(undefined4 *)(param_1 + 0x750);
      *(undefined4 *)(param_1 + 0x1a00) = *(undefined4 *)(param_1 + 0xa70);
    }
  }
  FUN_00594570(0);
  if (((1 < *(int *)(param_1 + 0x454)) && ((*(byte *)(param_1 + 0x461) & 0x80) == 0)) &&
     (*(char *)(param_1 + 0x160c) == '\0')) {
    *(int *)(param_1 + 0x454) = *(int *)(param_1 + 0x454) + -1;
  }
LAB_0059a06e:
  uVar7 = 1;
  if ((*(int *)(param_1 + 0x454) == 1) ||
     ((DAT_006d31c4 != '\0' && (*(int *)(param_1 + 0x27e8) <= *(int *)(param_1 + 0x27ec))))) {
    uVar7 = 0;
  }
  return uVar7;
}


