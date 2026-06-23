// FUN_005a8680  entry=005a8680  size=820 bytes

void __fastcall FUN_005a8680(int param_1)

{
  short sVar1;
  int iVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  char *pcVar6;
  int iVar7;
  uint uVar8;
  bool bVar9;
  
  if ((*(int *)(param_1 + 700) != 0) && (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 0)) {
    FUN_005b1420();
  }
  iVar2 = *(int *)(param_1 + 0x18c);
  iVar7 = *(int *)(iVar2 + 0x448);
  if (((((iVar7 == 3) || (iVar7 == 4)) || (iVar7 == 5)) || (iVar7 == 7)) &&
     (param_1 == *(int *)(iVar2 + 0x438))) {
    bVar9 = iVar7 == 7;
    iVar2 = (uint)(*(int *)(param_1 + 4) < 0) +
            ((uint)(0 < *(int *)(param_1 + 8)) + ((uint)(iVar7 == 4) + (uint)bVar9 * 2) * 2) * 2;
    uVar4 = (uint)*(ushort *)(param_1 + 0x34);
    if (*(char *)(*(int *)(param_1 + 0x184) + 0x210) != '\0') {
      uVar4 = uVar4 - 0x80;
    }
    if (*(char *)(*(int *)(param_1 + 0x184) + 0x212) != '\0') {
      uVar4 = uVar4 + 0x80;
    }
    if (bVar9) {
      uVar4 = uVar4 + 0x4000;
    }
    uVar5 = uVar4;
    if (iVar7 != 5) {
      sVar1 = *(short *)(&DAT_00665562 + iVar2 * 4);
      uVar3 = CONCAT22((short)((uint)iVar7 >> 0x10),sVar1);
      uVar8 = uVar4;
      if (sVar1 <= (short)uVar4) {
        uVar8 = uVar3;
      }
      uVar5 = (uint)*(ushort *)(&DAT_00665560 + iVar2 * 4);
      if (((short)*(ushort *)(&DAT_00665560 + iVar2 * 4) <= (short)uVar8) &&
         (uVar5 = uVar4, sVar1 <= (short)uVar4)) {
        uVar5 = uVar3;
      }
    }
    if (bVar9) {
      uVar5 = uVar5 - 0x4000;
    }
  }
  else {
    if ((*(int *)(param_1 + 0x40) < 0) || (3 < *(int *)(param_1 + 0x40))) {
      bVar9 = false;
    }
    else {
      bVar9 = true;
    }
    if ((!bVar9) || (iVar7 != 0)) goto LAB_005a8854;
    uVar5 = 0;
    pcVar6 = (char *)(*(int *)(param_1 + 0x184) + 0x213);
    iVar7 = 4;
    do {
      uVar5 = uVar5 * 2;
      if (*pcVar6 != '\0') {
        uVar5 = uVar5 | 1;
      }
      iVar7 = iVar7 + -1;
      pcVar6 = pcVar6 + -1;
    } while (iVar7 != 0);
    *(bool *)(param_1 + 0x5d) = uVar5 != 0;
    iVar7 = CONCAT22((short)(uVar5 >> 0x10),*(short *)(&DAT_00665590 + uVar5 * 2));
    if ((*(short *)(&DAT_00665590 + uVar5 * 2) != -1) &&
       (iVar7 = iVar7 + -0x4000 + ((ushort)(*(short *)(iVar2 + 0x181c) + 0x1000) & 0xffffe000),
       (short)iVar7 != -1)) {
      FUN_005a8ac0(iVar7,100);
      goto LAB_005a8854;
    }
    uVar5 = CONCAT22((short)((uint)iVar7 >> 0x10),*(undefined2 *)(param_1 + 0x34));
  }
  FUN_005a8f20(uVar5);
LAB_005a8854:
  iVar2 = *(int *)(param_1 + 0x40);
  if ((((iVar2 == 4) || (iVar2 == 5)) || (iVar2 == 8)) || (iVar2 == 9)) {
    bVar9 = false;
  }
  else {
    bVar9 = true;
  }
  if (bVar9) {
    if ((iVar2 == 0x25) || (iVar2 == 0x24)) {
      bVar9 = false;
    }
    else {
      bVar9 = true;
    }
    if (((bVar9) && ((iVar2 != 0xb || (4 < *(int *)(param_1 + 0x2c))))) &&
       (((iVar2 != 0xd || (8 < *(int *)(param_1 + 0x2c))) &&
        ((iVar2 != 0x1d || (0 < *(int *)(param_1 + 0x48))))))) {
      if (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40)) {
        iVar2 = *(int *)(*(int *)(param_1 + 0x18c) + 0x448);
        if ((iVar2 != 7) &&
           ((*(char *)(*(int *)(param_1 + 0x184) + 0x214) != '\0' ||
            ((iVar2 == 2 && (*(char *)(*(int *)(param_1 + 0x184) + 0x215) != '\0')))))) {
          FUN_005aa4d0();
          return;
        }
        if (*(char *)(*(int *)(param_1 + 0x184) + 0x215) != '\0') {
          FUN_005aa870(0);
          return;
        }
      }
      else {
        if (*(char *)(*(int *)(param_1 + 0x184) + 0x214) != '\0') {
          FUN_005aafd0(1);
          return;
        }
        if (((*(char *)(*(int *)(param_1 + 0x184) + 0x215) == '\0') &&
            (*(int *)(param_1 + 0x54) != 0)) &&
           ((iVar2 = *(int *)(*(int *)(param_1 + 400) + 0x4c), iVar2 == 0 ||
            (*(int *)(param_1 + 0x2b8) != *(int *)(iVar2 + 0x2b8))))) {
          FUN_005b8ce0(1);
          *(undefined4 *)(param_1 + 0x54) = 0;
        }
      }
    }
  }
  return;
}


