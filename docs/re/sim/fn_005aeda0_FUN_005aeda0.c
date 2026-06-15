// FUN_005aeda0  entry=005aeda0  size=4737 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_005aeda0(int param_1)

{
  byte *pbVar1;
  byte bVar2;
  short sVar3;
  int iVar4;
  bool bVar5;
  bool bVar6;
  bool bVar7;
  bool bVar8;
  char cVar9;
  short sVar10;
  undefined4 uVar11;
  int iVar12;
  int iVar13;
  int iVar14;
  undefined2 extraout_var;
  int *piVar15;
  int iVar16;
  byte bVar17;
  uint uVar18;
  uint uVar19;
  int *piVar20;
  int local_34;
  int local_30;
  int local_2c;
  int local_28;
  int local_24;
  int local_20;
  int local_1c;
  undefined1 local_18 [12];
  undefined1 local_c [12];
  
  if (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) != 0) {
    return;
  }
  local_34 = 0xc000;
  if ((*(int *)(param_1 + 0x2c) == 3) && (*(int *)(param_1 + 0x30) == 0)) {
    bVar5 = true;
  }
  else {
    bVar5 = false;
  }
  if ((bVar5) && (iVar13 = *(int *)(param_1 + 0xac), iVar13 != 0)) {
    if ((*(int *)(iVar13 + 0x40) < 0) || (3 < *(int *)(iVar13 + 0x40))) {
      bVar5 = false;
    }
    else {
      bVar5 = true;
    }
    if ((bVar5) && (0x1332 < *(int *)(iVar13 + 0x68))) {
      uVar11 = FUN_005b1230(local_18,8);
      FUN_005a1700(&local_24,uVar11);
      uVar11 = FUN_005b1230(local_c,8);
      FUN_005a1700(&local_30,uVar11);
      uVar18 = local_30 - local_24 >> 0x1f;
      if (((int)((local_30 - local_24 ^ uVar18) - uVar18) < 0x10000) &&
         ((uVar18 = local_2c - local_20 >> 0x1f,
          (int)((local_2c - local_20 ^ uVar18) - uVar18) < 0x10000 &&
          (uVar18 = local_28 - local_1c >> 0x1f,
          (int)((local_28 - local_1c ^ uVar18) - uVar18) < 0x10000)))) {
        bVar5 = true;
      }
      else {
        bVar5 = false;
      }
      if (bVar5) {
        iVar13 = *(int *)(*(int *)(param_1 + 0xac) + 0x398);
        if (iVar13 < 0x37) {
          iVar13 = iVar13 / 3;
        }
        else {
          iVar13 = iVar13 + -0x19;
        }
        iVar12 = FUN_005ec250();
        if ((int)(iVar12 * 1000 + (iVar12 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar13 * 9) {
          FUN_005a5430(0x17);
          iVar12 = *(int *)(param_1 + 0xac);
          iVar13 = DAT_00665014 * 4;
          local_20 = *(int *)(iVar12 + 0x24) * iVar13 + *(int *)(iVar12 + 8);
          local_1c = *(int *)(iVar12 + 0x28) * iVar13 + *(int *)(iVar12 + 0xc);
          local_24 = iVar13 * *(int *)(iVar12 + 0x20) + *(int *)(iVar12 + 4);
          FUN_005a7220(0,iVar13,&local_24,
                       CONCAT22((short)((uint)local_1c >> 0x10),*(undefined2 *)(iVar12 + 0x34)));
          iVar13 = *(int *)(param_1 + 0xac);
          if (iVar13 == *(int *)(*(int *)(iVar13 + 400) + 0x40)) {
            iVar14 = *(int *)(param_1 + 400);
            iVar12 = DAT_00665014 * 4;
            iVar16 = *(int *)(iVar13 + 0x20);
            iVar4 = *(int *)(iVar13 + 0x24);
            iVar13 = *(int *)(iVar13 + 0x28);
            *(undefined4 *)(iVar14 + 0x68) = 1;
            *(int *)(iVar14 + 0x6c) = iVar12;
            *(int *)(iVar14 + 0x9c) = iVar12 * iVar16 + *(int *)(iVar14 + 4);
            *(int *)(iVar14 + 0xa0) = iVar4 * iVar12 + *(int *)(iVar14 + 8);
            *(int *)(iVar14 + 0xa4) = iVar13 * iVar12 + *(int *)(iVar14 + 0xc);
          }
          iVar13 = FUN_005ec250();
          if ((int)(iVar13 * 1000 + (iVar13 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 600) {
            uVar11 = FUN_005ec240();
            if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
              FUN_004e9a70();
            }
          }
          else {
            uVar11 = FUN_005ec240();
            if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
              FUN_004e9ba0();
            }
          }
          FUN_005ec230(uVar11);
        }
      }
    }
  }
  iVar13 = *(int *)(param_1 + 0x2c);
  if ((iVar13 < 3) || (8 < iVar13)) {
    if ((iVar13 == 9) && (*(int *)(param_1 + 0x30) == 0)) {
      bVar5 = true;
    }
    else {
      bVar5 = false;
    }
    if (!bVar5) {
      return;
    }
    if (*(char *)(param_1 + 0x60) == '\0') {
      return;
    }
    if (*(int *)(*(int *)(param_1 + 0x18c) + 0x43c) == 0) {
      iVar13 = *(int *)(param_1 + 0xac);
      if (iVar13 == 0) {
        return;
      }
      if (*(int *)(iVar13 + 0x68) < 0x778) {
        return;
      }
      iVar12 = *(int *)(param_1 + 400);
      if (param_1 != *(int *)(iVar12 + 0x40)) {
        if (iVar13 == *(int *)(*(int *)(iVar13 + 400) + 0x40)) {
          return;
        }
        iVar13 = *(int *)(iVar12 + 8) - *(int *)(param_1 + 8);
        iVar12 = *(int *)(iVar12 + 4) - *(int *)(param_1 + 4);
        sVar10 = FUN_005ee080(iVar12,iVar13);
        iVar13 = FUN_005edfb0(iVar12,*(undefined4 *)(&DAT_006d31c8 + (sVar10 + 8 >> 4 & 0xfffU) * 4)
                              ,iVar13,*(undefined4 *)
                                       (&DAT_006d31c8 + (0x3ff8 - sVar10 >> 4 & 0xfffU) * 4));
        iVar14 = *(int *)(*(int *)(param_1 + 400) + 4) - *(int *)(*(int *)(param_1 + 0xac) + 4);
        iVar12 = *(int *)(*(int *)(param_1 + 400) + 8) - *(int *)(*(int *)(param_1 + 0xac) + 8);
        sVar10 = FUN_005ee080(iVar14,iVar12);
        iVar12 = FUN_005edfb0(iVar14,*(undefined4 *)(&DAT_006d31c8 + (sVar10 + 8 >> 4 & 0xfffU) * 4)
                              ,iVar12,*(undefined4 *)
                                       (&DAT_006d31c8 + (0x3ff8 - sVar10 >> 4 & 0xfffU) * 4));
        if (iVar12 <= iVar13) {
          return;
        }
      }
      uVar11 = FUN_005ec240();
      if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
        FUN_00606220();
      }
      FUN_005ec230(uVar11);
      return;
    }
    return;
  }
  if ((((*(int *)(*(int *)(param_1 + 0x18c) + 0x43c) == 0) && (*(char *)(param_1 + 0x62) == '\0'))
      && (iVar13 = *(int *)(param_1 + 0xac), iVar13 != 0)) && (*(int *)(iVar13 + 700) != 0)) {
    if ((*(int *)(iVar13 + 0x40) == 8) || (*(int *)(iVar13 + 0x40) == 9)) {
      bVar5 = true;
    }
    else {
      bVar5 = false;
    }
    if (bVar5) goto LAB_005afabf;
    if ((*(int *)(iVar13 + 0x40) == 6) || (*(int *)(iVar13 + 0x40) == 7)) {
      bVar5 = true;
    }
    else {
      bVar5 = false;
    }
    if (bVar5) goto LAB_005afabf;
    iVar12 = *(int *)(iVar13 + 0x40);
    if (((iVar12 == 0x17) || (iVar12 == 0x15)) || (iVar12 == 0x14)) {
      bVar5 = false;
    }
    else {
      bVar5 = true;
    }
    if (!bVar5) goto LAB_005afabf;
    iVar13 = ((100 - *(int *)(iVar13 + 0x388)) * 0x13333) / 100;
    if (iVar13 < 0x8000) {
      iVar12 = FUN_005ec250();
      local_34 = (int)(iVar12 * iVar13 + (iVar12 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf;
    }
    else {
      iVar12 = FUN_005ec250();
      iVar12 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar12;
      local_34 = (int)(iVar12 + (iVar12 >> 0x1f & 0x7fU)) >> 7;
    }
    local_34 = local_34 + 0x4000;
    uVar11 = FUN_005ee0f0(0x4ccc,*(undefined2 *)(param_1 + 0x34));
    FUN_005a1700(&local_24,uVar11);
    iVar13 = *(int *)(param_1 + 0xac);
    uVar18 = *(int *)(iVar13 + 4) - local_24;
    uVar19 = (int)uVar18 >> 0x1f;
    if ((((int)((uVar18 ^ uVar19) - uVar19) < local_34) &&
        (uVar18 = *(int *)(iVar13 + 8) - local_20, uVar19 = (int)uVar18 >> 0x1f,
        (int)((uVar18 ^ uVar19) - uVar19) < local_34)) &&
       (uVar18 = *(int *)(iVar13 + 0xc) - local_1c, uVar19 = (int)uVar18 >> 0x1f,
       (int)((uVar18 ^ uVar19) - uVar19) < local_34)) {
      bVar5 = true;
    }
    else {
      bVar5 = false;
    }
    if (!bVar5) {
      uVar18 = *(int *)(iVar13 + 4) - *(int *)(param_1 + 4);
      uVar19 = (int)uVar18 >> 0x1f;
      if ((((int)((uVar18 ^ uVar19) - uVar19) < local_34) &&
          (uVar18 = *(int *)(iVar13 + 8) - *(int *)(param_1 + 8), uVar19 = (int)uVar18 >> 0x1f,
          (int)((uVar18 ^ uVar19) - uVar19) < local_34)) &&
         (uVar18 = *(int *)(iVar13 + 0xc) - *(int *)(param_1 + 0xc), uVar19 = (int)uVar18 >> 0x1f,
         (int)((uVar18 ^ uVar19) - uVar19) < local_34)) {
        bVar5 = true;
      }
      else {
        bVar5 = false;
      }
      if (!bVar5) goto LAB_005afabf;
    }
    sVar10 = *(short *)(param_1 + 0x34);
    sVar3 = *(short *)(iVar13 + 0x34);
    bVar5 = false;
    bVar7 = false;
    bVar8 = false;
    bVar6 = false;
    iVar13 = (*(int *)(param_1 + 900) * 0x71c) / 100 + 0x71c;
    if (iVar13 < 0x8000) {
      iVar12 = FUN_005ec250();
      iVar13 = (int)(iVar12 * iVar13 + (iVar12 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf;
    }
    else {
      iVar12 = FUN_005ec250();
      iVar12 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar12;
      iVar13 = (int)(iVar12 + (iVar12 >> 0x1f & 0x7fU)) >> 7;
    }
    uVar18 = (uint)(short)(sVar10 - sVar3);
    uVar19 = (int)uVar18 >> 0x1f;
    *(undefined1 *)(param_1 + 0x62) = 1;
    iVar12 = (uVar18 ^ uVar19) - uVar19;
    if ((8 < *(int *)(*(int *)(*(int *)(param_1 + 0xac) + 0x184) + 4)) &&
       (iVar14 = FUN_005ec250(),
       (int)(iVar14 * 1000 + (iVar14 * 1000 >> 0x1f & 0x7fffU)) >> 0xf <
       (int)((-(uint)(iVar12 < iVar13) & 300) + 400))) {
      FUN_005a5430((iVar12 < 0x4000) + '\x06');
      iVar14 = *(int *)(param_1 + 0xac);
      piVar15 = (int *)FUN_005ee0f0(0x20000,CONCAT22(extraout_var,*(undefined2 *)(iVar14 + 0x34)));
      local_1c = *(int *)(iVar14 + 0xc) + piVar15[2];
      local_20 = *(int *)(iVar14 + 8) + piVar15[1];
      local_24 = *piVar15 + *(int *)(iVar14 + 4);
      FUN_005a7220(0,0x30,&local_24,
                   CONCAT22((short)((uint)local_20 >> 0x10),
                            *(undefined2 *)(*(int *)(param_1 + 0xac) + 0x34)));
      FUN_0058ed50(*(undefined4 *)(param_1 + 0xac));
      iVar14 = *(int *)(*(int *)(param_1 + 0xac) + 0x40);
      iVar16 = FUN_005ec250();
      if (((int)(iVar16 * 1000 + (iVar16 * 1000 >> 0x1f & 0x7fffU)) >> 0xf <
           (int)((-(uint)(iVar14 != 7) & 0xffffffce) + 100)) &&
         (*(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x440) = *(undefined4 *)(param_1 + 0xac),
         DAT_006d31c4 == '\0')) {
        *(undefined4 *)(*(int *)(*(int *)(param_1 + 0xac) + 0x3b8) + 0xa4) = 1;
      }
      bVar6 = true;
      pbVar1 = (byte *)(*(int *)(param_1 + 0x18c) + 0x461);
      *pbVar1 = *pbVar1 | 8;
      iVar14 = FUN_005ec250();
      switch((int)(iVar14 * 5 + (iVar14 * 5 >> 0x1f & 0x7fffU)) >> 0xf) {
      case 0:
        if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180a) == '\0') goto switchD_005af443_default;
        goto LAB_005af4bb;
      case 1:
        cVar9 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180a);
        break;
      case 2:
        cVar9 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180a);
        break;
      case 3:
        cVar9 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180a);
        break;
      case 4:
        cVar9 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180a);
        break;
      default:
        goto switchD_005af443_default;
      }
      if (cVar9 != '\0') {
LAB_005af4bb:
        FUN_00590f00();
      }
switchD_005af443_default:
      if ((*(char *)(*(int *)(param_1 + 0x188) + 0x2ec) != '\0') &&
         (*(char *)(*(int *)(param_1 + 0x18c) + 0x180c) != '\0')) {
        FUN_00590f00();
      }
    }
    iVar14 = FUN_005ec250();
    if ((int)(iVar14 * 1000 + (iVar14 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 900) {
      if (iVar12 < iVar13) {
        if ((bVar6) &&
           (iVar13 = *(int *)(param_1 + 0x40), iVar12 = *(int *)(param_1 + 900),
           cVar9 = *(char *)(param_1 + 0x60), iVar14 = FUN_005ec250(),
           (int)(iVar14 * 1000 + (iVar14 * 1000 >> 0x1f & 0x7fffU)) >> 0xf <
           (int)((-(uint)(cVar9 != '\0') & 0xffffff9c) + 100 +
                (iVar12 + (uint)(iVar13 == 9) * 0x32) * 2))) {
          bVar7 = true;
        }
        else {
          bVar7 = false;
        }
        if (((bVar7) || (!bVar6)) ||
           (iVar13 = *(int *)(param_1 + 0x40), iVar12 = *(int *)(param_1 + 900),
           cVar9 = *(char *)(param_1 + 0x60), iVar14 = FUN_005ec250(),
           (int)((-(uint)(cVar9 != '\0') & 0xffffff9c) + 100 +
                (iVar12 + (uint)(iVar13 == 9) * 0x32) * 2) <=
           (int)(iVar14 * 1000 + (iVar14 * 1000 >> 0x1f & 0x7fffU)) >> 0xf)) {
          bVar8 = false;
        }
        else {
          bVar8 = true;
        }
        if ((!bVar7) && (!bVar8)) {
          if (bVar6) {
            iVar13 = (*(int *)(param_1 + 900) + (uint)(*(int *)(param_1 + 0x40) == 9) * 0x14) * 5 +
                     (-(uint)(*(char *)(param_1 + 0x60) != '\0') & 0xffffff38) + 200;
          }
          else {
            iVar13 = *(int *)(param_1 + 900) << 1;
          }
          iVar12 = FUN_005ec250();
          if (iVar13 <= (int)(iVar12 * 1000 + (iVar12 * 1000 >> 0x1f & 0x7fffU)) >> 0xf) {
            bVar5 = false;
            goto LAB_005af7d4;
          }
        }
        bVar5 = true;
      }
      else if (*(char *)(param_1 + 0x60) == '\0') {
        if (bVar6) {
          iVar13 = (*(int *)(param_1 + 900) + (uint)(*(int *)(param_1 + 0x40) == 9) * 100) * 2;
        }
        else {
          iVar13 = *(int *)(param_1 + 900);
        }
        iVar12 = FUN_005ec250();
        bVar5 = (int)(iVar12 * 1000 + (iVar12 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar13;
        if (((bVar5) && (bVar6)) &&
           (iVar13 = *(int *)(param_1 + 900), iVar12 = *(int *)(param_1 + 0x40),
           iVar14 = FUN_005ec250(),
           (int)(iVar14 * 1000 + (iVar14 * 1000 >> 0x1f & 0x7fffU)) >> 0xf <
           (int)(iVar13 * 3 + (uint)(iVar12 == 9) * 100))) {
          bVar8 = true;
        }
        else {
LAB_005af7cf:
          bVar8 = false;
        }
      }
      else {
        if (bVar6) {
          iVar13 = *(int *)(param_1 + 900) + (uint)(*(int *)(param_1 + 0x40) == 9) * 100;
        }
        else {
          iVar13 = *(int *)(param_1 + 900) / 2;
        }
        iVar12 = FUN_005ec250();
        bVar5 = (int)(iVar12 * 1000 + (iVar12 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar13;
        if (((!bVar5) || (!bVar6)) ||
           (iVar13 = *(int *)(param_1 + 900), iVar12 = FUN_005ec250(),
           iVar13 / 2 <= (int)(iVar12 * 1000 + (iVar12 * 1000 >> 0x1f & 0x7fffU)) >> 0xf))
        goto LAB_005af7cf;
        bVar8 = true;
      }
    }
LAB_005af7d4:
    if (bVar5) {
      if (((*(int *)(*(int *)(param_1 + 0x184) + 4) < 9) && (bVar7 = false, bVar8)) &&
         (*(char *)(param_1 + 0x2da) != '\0')) {
        bVar8 = false;
      }
      *(int *)(*(int *)(param_1 + 0x18c) + 0x43c) = param_1;
      cVar9 = FUN_0058fb50((int *)(param_1 + 4));
      if ((cVar9 == '\0') ||
         (((-1 < *(int *)(param_1 + 4)) - 1 & 0xfffffffe) + 1 !=
          ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
        bVar5 = false;
      }
      else {
        bVar5 = true;
      }
      if (bVar5) {
LAB_005af899:
        bVar17 = 1;
      }
      else {
        iVar13 = *(int *)(param_1 + 0xac);
        piVar15 = (int *)(iVar13 + 4);
        cVar9 = FUN_0058fb50(piVar15);
        if ((cVar9 == '\0') ||
           (((-1 < *piVar15) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *(int *)(iVar13 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
          bVar5 = false;
        }
        else {
          bVar5 = true;
        }
        if (bVar5) goto LAB_005af899;
        bVar17 = 0;
      }
      bVar2 = *(byte *)(*(int *)(param_1 + 0x18c) + 0x461);
      *(byte *)(*(int *)(param_1 + 0x18c) + 0x461) = (bVar2 ^ bVar17) & 1 ^ bVar2;
      *(byte *)(*(int *)(param_1 + 0x18c) + 0x461) =
           *(byte *)(*(int *)(param_1 + 0x18c) + 0x461) & 0xfb | bVar7 << 2;
      *(byte *)(*(int *)(param_1 + 0x18c) + 0x461) =
           *(byte *)(*(int *)(param_1 + 0x18c) + 0x461) & 0xfd | bVar8 << 1;
      if (DAT_006d31c4 == '\0') {
        if (bVar8) {
          *(int *)(*(int *)(param_1 + 0x3b8) + 0x98) =
               *(int *)(*(int *)(param_1 + 0x3b8) + 0x98) + 1;
          iVar13 = *(int *)(param_1 + 0x18c);
          FUN_0044ea40(*(undefined4 *)(param_1 + 0x2b8),*(undefined4 *)(param_1 + 700),
                       ((*(int *)(iVar13 + 0x19a8) + *(int *)(iVar13 + 0x450)) * 0x2d) /
                       *(int *)(iVar13 + 0x19ac));
        }
        if (bVar7) {
          *(int *)(*(int *)(param_1 + 0x3b8) + 0x9c) =
               *(int *)(*(int *)(param_1 + 0x3b8) + 0x9c) + 1;
          iVar13 = *(int *)(param_1 + 0x18c);
          FUN_0044ec00(*(undefined4 *)(param_1 + 0x2b8),*(undefined4 *)(param_1 + 700),
                       ((*(int *)(iVar13 + 0x19a8) + *(int *)(iVar13 + 0x450)) * 0x2d) /
                       *(int *)(iVar13 + 0x19ac));
        }
        if (*(char *)(param_1 + 0x60) != '\0') {
          *(int *)(*(int *)(param_1 + 0x3b8) + 0x8c) =
               *(int *)(*(int *)(param_1 + 0x3b8) + 0x8c) + -1;
          piVar15 = (int *)(*(int *)(param_1 + 0x3b8) + 0x90);
          *piVar15 = *piVar15 + 1;
        }
        if ((bVar7) || (1 < *(int *)(*(int *)(param_1 + 0x3b8) + 0x98))) {
          *(int *)(*(int *)(param_1 + 0x3b8) + 0xa0) =
               *(int *)(*(int *)(param_1 + 0x3b8) + 0xa0) + 1;
          *(undefined1 *)(param_1 + 0x2d9) = 1;
        }
        if ((!bVar7) && (!bVar8)) {
          piVar15 = (int *)(*(int *)(*(int *)(param_1 + 0x184) + 0x9c) + 0xc);
          *piVar15 = *piVar15 + 1;
        }
      }
      goto LAB_005afabf;
    }
    if (*(char *)(param_1 + 0x60) != '\0') {
      if (bVar6) {
        iVar13 = *(int *)(param_1 + 900);
        iVar12 = FUN_005ec250();
        if ((100 - iVar13) * 10 <= (int)(iVar12 * 1000 + (iVar12 * 1000 >> 0x1f & 0x7fffU)) >> 0xf)
        goto LAB_005afabf;
        if (!bVar6) goto LAB_005afa7b;
LAB_005afaab:
        uVar11 = 0x14;
      }
      else {
LAB_005afa7b:
        iVar13 = FUN_005ec250();
        uVar11 = 0x13;
        if (499 < (int)(iVar13 * 1000 + (iVar13 * 1000 >> 0x1f & 0x7fffU)) >> 0xf)
        goto LAB_005afaab;
      }
      FUN_00594470(uVar11,param_1,0);
      goto LAB_005afabf;
    }
  }
  else {
LAB_005afabf:
    if (*(char *)(param_1 + 0x60) != '\0') goto LAB_005afe9e;
  }
  if ((*(int *)(*(int *)(param_1 + 400) + 0x70) == 0) &&
     ((((iVar13 = *(int *)(*(int *)(param_1 + 400) + 0x40), iVar13 == 0 ||
        (*(int *)(iVar13 + 700) != 0)) && (iVar12 = 0, param_1 != iVar13)) &&
      ((*(int *)(param_1 + 0xac) == 0 ||
       (iVar12 = *(int *)(*(int *)(param_1 + 0xac) + 0x40), iVar12 != 0x17)))))) {
    piVar15 = (int *)FUN_005ee0f0(0x9998,CONCAT22((short)((uint)iVar12 >> 0x10),
                                                  *(undefined2 *)(param_1 + 0x34)));
    FUN_00590aa0(*(int *)(param_1 + 4) + *piVar15,piVar15[1] + *(int *)(param_1 + 8),
                 piVar15[2] + *(int *)(param_1 + 0xc));
    iVar13 = *(int *)(param_1 + 400);
    uVar18 = *(int *)(iVar13 + 4) - local_24;
    uVar19 = (int)uVar18 >> 0x1f;
    if (((int)((uVar18 ^ uVar19) - uVar19) < local_34) &&
       ((uVar18 = *(int *)(iVar13 + 8) - local_20, uVar19 = (int)uVar18 >> 0x1f,
        (int)((uVar18 ^ uVar19) - uVar19) < local_34 &&
        (uVar18 = *(int *)(iVar13 + 0xc) - local_1c, uVar19 = (int)uVar18 >> 0x1f,
        (int)((uVar18 ^ uVar19) - uVar19) < local_34)))) {
      bVar5 = true;
    }
    else {
      bVar5 = false;
    }
    if (!bVar5) {
      piVar15 = (int *)FUN_005ee0f0(0x4ccc,CONCAT22((short)(uVar19 >> 0x10),
                                                    *(undefined2 *)(param_1 + 0x34)));
      FUN_00590aa0(*(int *)(param_1 + 4) + *piVar15,piVar15[1] + *(int *)(param_1 + 8),
                   piVar15[2] + *(int *)(param_1 + 0xc));
      iVar13 = *(int *)(param_1 + 400);
      uVar18 = *(int *)(iVar13 + 4) - local_24;
      uVar19 = (int)uVar18 >> 0x1f;
      if ((((int)((uVar18 ^ uVar19) - uVar19) < local_34) &&
          (uVar18 = *(int *)(iVar13 + 8) - local_20, uVar19 = (int)uVar18 >> 0x1f,
          (int)((uVar18 ^ uVar19) - uVar19) < local_34)) &&
         (uVar18 = *(int *)(iVar13 + 0xc) - local_1c, uVar19 = (int)uVar18 >> 0x1f,
         (int)((uVar18 ^ uVar19) - uVar19) < local_34)) {
        bVar5 = true;
      }
      else {
        bVar5 = false;
      }
      if (!bVar5) {
        uVar18 = *(int *)(iVar13 + 4) - *(int *)(param_1 + 4);
        uVar19 = (int)uVar18 >> 0x1f;
        if ((((int)((uVar18 ^ uVar19) - uVar19) < local_34) &&
            (uVar18 = *(int *)(iVar13 + 8) - *(int *)(param_1 + 8), uVar19 = (int)uVar18 >> 0x1f,
            (int)((uVar18 ^ uVar19) - uVar19) < local_34)) &&
           (uVar18 = *(int *)(iVar13 + 0xc) - *(int *)(param_1 + 0xc), uVar19 = (int)uVar18 >> 0x1f,
           (int)((uVar18 ^ uVar19) - uVar19) < local_34)) {
          bVar5 = true;
        }
        else {
          bVar5 = false;
        }
        if (!bVar5) goto LAB_005afe9e;
      }
    }
    iVar13 = (*(int *)(param_1 + 900) << 0x11) / 100 +
             ((100 - *(int *)(param_1 + 0x390)) * 0x10000) / 100;
    if (iVar13 < 0x8000) {
      iVar12 = FUN_005ec250();
      iVar13 = (int)(iVar12 * iVar13 + (iVar12 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf;
    }
    else {
      iVar12 = FUN_005ec250();
      iVar12 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar12;
      iVar13 = (int)(iVar12 + (iVar12 >> 0x1f & 0x7fU)) >> 7;
    }
    if ((*(int *)(*(int *)(param_1 + 0x18c) + 0x43c) != param_1) && (DAT_006d31c4 == '\0')) {
      *(int *)(*(int *)(param_1 + 0x3b8) + 0x90) = *(int *)(*(int *)(param_1 + 0x3b8) + 0x90) + -1;
      piVar15 = (int *)(*(int *)(param_1 + 0x3b8) + 0x8c);
      *piVar15 = *piVar15 + 1;
    }
    *(undefined1 *)(param_1 + 0x60) = 1;
    if (iVar13 + 0x20000 < 0x10ccd) {
      FUN_0058eca0(param_1);
      if (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 0) {
        uVar11 = FUN_005ec240();
        if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
          FUN_004e9630(*(undefined4 *)(param_1 + 0x2c0),0);
        }
        FUN_005ec230(uVar11);
      }
    }
    else {
      FUN_0058eca0(param_1);
      FUN_0058ed70();
    }
    iVar12 = *(int *)(*(int *)(param_1 + 400) + 0x70);
    if (iVar12 < 0xd) {
      iVar12 = 0xc;
    }
    *(int *)(*(int *)(param_1 + 400) + 0x70) = iVar12;
    iVar14 = ((100 - *(int *)(param_1 + 0x390)) * 0x2000) / 100;
    iVar12 = iVar14 * 2 + 1;
    if (iVar12 < 0x8000) {
      iVar16 = FUN_005ec250();
      iVar12 = (int)(iVar16 * iVar12 + (iVar16 * iVar12 >> 0x1f & 0x7fffU)) >> 0xf;
    }
    else {
      iVar16 = FUN_005ec250();
      iVar16 = ((int)(iVar12 + (iVar12 >> 0x1f & 0xffU)) >> 8) * iVar16;
      iVar12 = (int)(iVar16 + (iVar16 >> 0x1f & 0x7fU)) >> 7;
    }
    iVar16 = *(int *)(param_1 + 400);
    iVar12 = iVar12 - iVar14;
    piVar20 = (int *)(iVar16 + 0x20);
    *piVar20 = (int)(*piVar20 + (*piVar20 >> 0x1f & 0xfU)) >> 4;
    *(int *)(iVar16 + 0x24) =
         (int)(*(int *)(iVar16 + 0x24) + (*(int *)(iVar16 + 0x24) >> 0x1f & 0xfU)) >> 4;
    *(int *)(iVar16 + 0x28) =
         (int)(*(int *)(iVar16 + 0x28) + (*(int *)(iVar16 + 0x28) >> 0x1f & 0xfU)) >> 4;
    FUN_005ee170(local_c,iVar13 + 0x20000);
    piVar15 = (int *)FUN_005ee670(iVar12);
    *piVar20 = *piVar20 + *piVar15;
    *(int *)(iVar16 + 0x24) = *(int *)(iVar16 + 0x24) + piVar15[1];
    *(int *)(iVar16 + 0x28) = *(int *)(iVar16 + 0x28) + piVar15[2];
  }
LAB_005afe9e:
  *(undefined4 *)(param_1 + 0x54) = 0;
  *(undefined4 *)(param_1 + 0x58) = 0;
  return;
}


