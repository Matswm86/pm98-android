// FUN_005acc40  entry=005acc40  size=975 bytes

void __fastcall FUN_005acc40(int param_1)

{
  int *piVar1;
  bool bVar2;
  char cVar3;
  short sVar4;
  undefined4 *puVar5;
  int iVar6;
  int *piVar7;
  int iVar8;
  int iVar9;
  undefined4 local_30;
  undefined4 local_2c;
  int local_18;
  int local_14;
  int local_10;
  int local_c;
  int local_8;
  int local_4;
  
  if ((*(int *)(param_1 + 0x2c) == 4) && (*(int *)(param_1 + 0x30) == 3)) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  if ((bVar2) && (*(int *)(*(int *)(param_1 + 400) + 0x4c) != 0)) {
    *(undefined1 *)(*(int *)(param_1 + 400) + 0x62) = 0;
    piVar1 = (int *)(param_1 + 0xa0);
    iVar8 = *(int *)(*(int *)(param_1 + 400) + 0x4c);
    *piVar1 = *(int *)(iVar8 + 4);
    *(undefined4 *)(param_1 + 0xa4) = *(undefined4 *)(iVar8 + 8);
    *(undefined4 *)(param_1 + 0xa8) = *(undefined4 *)(iVar8 + 0xc);
    if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
       (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    if ((bVar2) && (*(char *)(param_1 + 0x5c) != '\0')) {
      bVar2 = true;
    }
    else {
      bVar2 = false;
    }
    if (((bVar2) && (*(int *)(param_1 + 0x58) == 0x10)) && (*(int *)(param_1 + 0x54) != 0)) {
      piVar7 = (int *)(param_1 + 4);
      cVar3 = FUN_0058fb50(piVar7);
      if ((cVar3 == '\0') ||
         (((-1 < *piVar7) - 1 & 0xfffffffe) + 1 ==
          ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if (!bVar2) {
        cVar3 = FUN_005ac0e0(piVar7);
        if ((cVar3 == '\0') ||
           (((-1 < *piVar7) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
          bVar2 = false;
        }
        else {
          bVar2 = true;
        }
        if ((!bVar2) && (*(int *)(*(int *)(param_1 + 0x18c) + 0x44c) != 2)) {
          *(undefined1 *)(param_1 + 0x5f) = 1;
          *(undefined4 *)(param_1 + 0x58) = 4;
        }
      }
    }
    if (*(char *)(param_1 + 0x5f) != '\0') {
      iVar9 = *piVar1 - *(int *)(param_1 + 4);
      iVar8 = *(int *)(param_1 + 0xa4) - *(int *)(param_1 + 8);
      sVar4 = FUN_005ee080(iVar9,iVar8);
      FUN_00436fb0(*(undefined4 *)(&DAT_006d31c8 + (sVar4 + 8 >> 4 & 0xfffU) * 4),
                   *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar4 >> 4 & 0xfffU) * 4));
      iVar9 = FUN_005edfb0(iVar9,local_30,iVar8,local_2c);
      iVar8 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
      if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
        iVar8 = -iVar8;
      }
      FUN_00590aa0(iVar8,0,0);
      iVar8 = *(int *)(*(int *)(param_1 + 400) + 0x4c);
      puVar5 = (undefined4 *)FUN_00590ae0(&local_18,iVar8 + 4);
      iVar6 = FUN_005ee080(*puVar5,puVar5[1]);
      iVar6 = CONCAT22((short)((uint)*(int *)(param_1 + 400) >> 0x10),
                       *(short *)(*(int *)(*(int *)(param_1 + 400) + 0x4c) + 0x34) -
                       *(short *)(iVar8 + 0x34)) + iVar6;
      piVar7 = (int *)FUN_005ee0f0((int)(iVar9 + (iVar9 >> 0x1f & 3U)) >> 2,
                                   (int)(short)((-(ushort)((*(uint *)(*(int *)(param_1 + 0x18c) +
                                                                     0x19a0) & 1) !=
                                                          *(uint *)(param_1 + 0x2b8)) & 0x8000) -
                                               (short)iVar6) / 2 + iVar6);
      *piVar1 = *piVar1 + *piVar7;
      *(int *)(param_1 + 0xa4) = *(int *)(param_1 + 0xa4) + piVar7[1];
      *(int *)(param_1 + 0xa8) = *(int *)(param_1 + 0xa8) + piVar7[2];
      if (0x1e0000 < iVar9) {
        *(undefined1 *)(*(int *)(param_1 + 400) + 0x62) = 1;
      }
    }
    iVar8 = *(int *)(param_1 + 0x18c);
    FUN_00590ac0(iVar8 + 0x1828);
    FUN_00590ac0(iVar8 + 0x1834);
    FUN_00590b10(0x4ccc);
    FUN_005b1210(0x4ccc);
    FUN_00590be0(&local_30);
    iVar8 = *piVar1;
    iVar9 = local_18;
    if (local_18 <= iVar8) {
      iVar9 = iVar8;
    }
    if ((iVar9 <= local_c) && (local_c = iVar8, iVar8 < local_18)) {
      local_c = local_18;
    }
    *piVar1 = local_c;
    iVar8 = *(int *)(param_1 + 0xa4);
    iVar9 = local_14;
    if (local_14 <= iVar8) {
      iVar9 = iVar8;
    }
    if ((iVar9 <= local_8) && (local_8 = iVar8, iVar8 < local_14)) {
      local_8 = local_14;
    }
    *(int *)(param_1 + 0xa4) = local_8;
    iVar8 = *(int *)(param_1 + 0xa8);
    iVar9 = local_10;
    if (local_10 <= iVar8) {
      iVar9 = iVar8;
    }
    if ((iVar9 <= local_4) && (local_4 = iVar8, iVar8 < local_10)) {
      local_4 = local_10;
    }
    *(int *)(param_1 + 0xa8) = local_4;
    if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
       (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    if ((bVar2) && (*(char *)(param_1 + 0x5c) != '\0')) {
      bVar2 = true;
    }
    else {
      bVar2 = false;
    }
    if (bVar2) {
      *(bool *)(param_1 + 0x5e) = *(int *)(param_1 + 0x54) != 0;
    }
    FUN_005ac1a0();
    if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180a) != '\0') {
      FUN_00590f00();
    }
  }
  return;
}


