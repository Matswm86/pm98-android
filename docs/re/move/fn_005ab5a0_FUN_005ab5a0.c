// FUN_005ab5a0  entry=005ab5a0  size=2880 bytes

void __fastcall FUN_005ab5a0(int param_1)

{
  int *piVar1;
  bool bVar2;
  char cVar3;
  short sVar4;
  int iVar5;
  undefined4 uVar6;
  uint uVar7;
  uint uVar8;
  int iVar9;
  int iVar10;
  int local_24;
  undefined4 local_20;
  undefined4 local_1c;
  int local_18;
  uint local_14;
  undefined4 local_10;
  int local_c;
  int local_8;
  
  FUN_0058fda0();
  iVar5 = *(int *)(param_1 + 400);
  local_18 = *(int *)(iVar5 + 0xcc);
  local_14 = *(uint *)(iVar5 + 0xd0);
  local_10 = *(undefined4 *)(iVar5 + 0xd4);
  *(int *)(iVar5 + 0x50) = param_1;
  if ((DAT_006d31c4 == '\0') && (*(int *)(*(int *)(param_1 + 400) + 0x4c) != 0)) {
    piVar1 = (int *)(*(int *)(param_1 + 0x3b8) + 0x88);
    *piVar1 = *piVar1 + 1;
  }
  if (*(int *)(param_1 + 0x40) != 0x13) {
    cVar3 = FUN_005ac120(param_1 + 4);
    if (cVar3 != '\0') {
      cVar3 = FUN_0058fb50(&local_18);
      if ((cVar3 == '\0') ||
         (((-1 < local_18) - 1 & 0xfffffffe) + 1 ==
          ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if (!bVar2) {
        cVar3 = FUN_005ac0e0(&local_18);
        if ((cVar3 == '\0') ||
           (((-1 < local_18) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
          bVar2 = false;
        }
        else {
          bVar2 = true;
        }
        if (!bVar2) goto LAB_005ab7c9;
      }
      FUN_00590ae0(&local_c,param_1 + 4);
      iVar5 = FUN_005b1260();
      if (0xa0000 < iVar5) {
        iVar5 = (local_14 ^ (int)local_14 >> 0x1f) - ((int)local_14 >> 0x1f);
        if (iVar5 < 0x20000) {
          uVar6 = FUN_005ec240();
          if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
            FUN_004ea2d0();
          }
        }
        else if (((-1 < (int)local_14) - 1 & 0xfffffffe) + 1 ==
                 ((-1 < *(int *)(param_1 + 8)) - 1 & 0xfffffffe) + 1) {
          uVar6 = FUN_005ec240();
          if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
            FUN_004ea1a0();
          }
        }
        else if (iVar5 < 0x1a0000) {
          uVar6 = FUN_005ec240();
          if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
            FUN_004ea400();
          }
        }
        else {
          uVar6 = FUN_005ec240();
          if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
            FUN_00606220();
          }
        }
        FUN_005ec230(uVar6);
        if (*(int *)(*(int *)(param_1 + 0x18c) + 0x44c) != 4) {
          FUN_00594470(0x10,param_1,0);
        }
      }
    }
  }
LAB_005ab7c9:
  if (param_1 == *(int *)(*(int *)(param_1 + 0x18c) + 0x438)) goto LAB_005ac069;
  piVar1 = (int *)(param_1 + 4);
  iVar9 = *(int *)(param_1 + 0xa4) - *(int *)(param_1 + 8);
  iVar10 = *(int *)(param_1 + 0xa0) - *(int *)(param_1 + 4);
  sVar4 = FUN_005ee080(iVar10,iVar9);
  FUN_00436fb0(*(undefined4 *)(&DAT_006d31c8 + (sVar4 + 8 >> 4 & 0xfffU) * 4),
               *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar4 >> 4 & 0xfffU) * 4));
  iVar5 = FUN_005edfb0(iVar10,local_20,iVar9,local_1c);
  if (iVar5 < 0x370000) {
    sVar4 = FUN_005ee080(iVar10,iVar9);
    FUN_00436fb0(*(undefined4 *)(&DAT_006d31c8 + (sVar4 + 8 >> 4 & 0xfffU) * 4),
                 *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar4 >> 4 & 0xfffU) * 4));
    local_20 = FUN_005edfb0(iVar10,local_20,iVar9,local_1c);
  }
  else {
    local_20 = 0x370000;
  }
  if (param_1 == 0) {
    local_24 = 0xc80000;
  }
  else {
    uVar7 = *(int *)(param_1 + 0x3a4) + *piVar1;
    uVar8 = (int)uVar7 >> 0x1f;
    local_24 = (uVar7 ^ uVar8) - uVar8;
  }
  bVar2 = false;
  if ((*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 0) &&
     (((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1 !=
      ((-1 < *(int *)(*(int *)(param_1 + 400) + 0x20)) - 1 & 0xfffffffe) + 1)) {
    if (*(int *)(*(int *)(param_1 + 400) + 0x4c) == 0) {
LAB_005ab955:
      bVar2 = false;
    }
    else {
      uVar6 = FUN_005ee080(iVar10,iVar9);
      cVar3 = FUN_005b0bb0(piVar1,uVar6,local_20,local_24);
      bVar2 = true;
      if (cVar3 == '\0') goto LAB_005ab955;
    }
    if (bVar2) goto LAB_005ac069;
    local_c = **(int **)(param_1 + 0x184);
    bVar2 = false;
    iVar5 = (*(int **)(param_1 + 0x184))[1];
    while (local_8 = iVar5 + -1, iVar5 != 0) {
      if ((local_c != param_1) && (local_c != *(int *)(*(int *)(param_1 + 400) + 0x4c))) {
        uVar6 = FUN_005ee080(iVar10,iVar9);
        cVar3 = FUN_005b0bb0(piVar1,uVar6,local_20,local_24);
        if (cVar3 != '\0') {
          bVar2 = true;
          local_8 = 0;
        }
      }
      local_c = local_c + 0x3bc;
      iVar5 = local_8;
    }
  }
  if (bVar2) goto LAB_005ac069;
  iVar5 = *(int *)(*(int *)(param_1 + 400) + 0x48);
  if ((iVar5 == 0) || (*(int *)(param_1 + 0x2b8) == *(int *)(iVar5 + 0x2b8))) {
LAB_005abbe8:
    if (*(int *)(*(int *)(param_1 + 400) + 0x4c) == 0) {
      iVar5 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
      if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
        iVar5 = -iVar5;
      }
      FUN_00590aa0(iVar5 - *piVar1,-*(int *)(param_1 + 8),-*(int *)(param_1 + 0xc));
      sVar4 = FUN_005ee080(local_c,local_8);
      uVar7 = (uint)(short)(sVar4 - *(short *)(param_1 + 0x34));
      uVar8 = (int)uVar7 >> 0x1f;
      if (0x3554 < (int)((uVar7 ^ uVar8) - uVar8)) goto LAB_005ac069;
      *(int *)(*(int *)(param_1 + 0x184) + 0x2e4) = *(int *)(*(int *)(param_1 + 0x184) + 0x2e4) + 1;
      iVar5 = *(int *)(param_1 + 0x18c);
      if ((*(byte *)(iVar5 + 0x462) & 0x60) != 0) goto LAB_005ac069;
      iVar9 = *(int *)(iVar5 + 0x1820);
      if ((*(uint *)(iVar5 + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
        iVar9 = -iVar9;
      }
      FUN_00590aa0(iVar9 - *piVar1,-*(int *)(param_1 + 8),-*(int *)(param_1 + 0xc));
      sVar4 = FUN_005ee080(local_c,local_8);
      uVar7 = (uint)(short)(sVar4 - *(short *)(param_1 + 0x34));
      uVar8 = (int)uVar7 >> 0x1f;
      if (0x2e38 < (int)((uVar7 ^ uVar8) - uVar8)) goto LAB_005ac069;
      if (param_1 == 0) {
        iVar5 = 0xc80000;
      }
      else {
        uVar7 = *(int *)(param_1 + 0x3a4) + *piVar1;
        uVar8 = (int)uVar7 >> 0x1f;
        iVar5 = (uVar7 ^ uVar8) - uVar8;
      }
      if (iVar5 < 0x98001) goto LAB_005ac069;
      if (DAT_00674e78 == 1) {
        if (param_1 == 0) {
          iVar5 = 0xc80000;
        }
        else {
          uVar7 = *(int *)(param_1 + 0x3a4) + *piVar1;
          uVar8 = (int)uVar7 >> 0x1f;
          iVar5 = (uVar7 ^ uVar8) - uVar8;
        }
        if (iVar5 < 0x1e0001) goto LAB_005ac069;
        if (param_1 == 0) {
          iVar5 = 0xc80000;
        }
        else {
          uVar7 = *(int *)(param_1 + 0x3a4) + *piVar1;
          uVar8 = (int)uVar7 >> 0x1f;
          iVar5 = (uVar7 ^ uVar8) - uVar8;
        }
        if (0x27ffff < iVar5) {
          if (param_1 == 0) {
            iVar5 = 0xc80000;
          }
          else {
            uVar7 = *(int *)(param_1 + 0x3a4) + *piVar1;
            uVar8 = (int)uVar7 >> 0x1f;
            iVar5 = (uVar7 ^ uVar8) - uVar8;
          }
          if (0x2cffff < iVar5) goto LAB_005ac069;
          uVar6 = FUN_005ec240();
          cVar3 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180b);
          goto joined_r0x005ac049;
        }
        uVar6 = FUN_005ec240();
        cVar3 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180b);
      }
      else {
        if (param_1 == 0) {
          iVar5 = 0xc80000;
        }
        else {
          uVar7 = *(int *)(param_1 + 0x3a4) + *piVar1;
          uVar8 = (int)uVar7 >> 0x1f;
          iVar5 = (uVar7 ^ uVar8) - uVar8;
        }
        if (0x22ffff < iVar5) {
          if (param_1 == 0) {
            iVar5 = 0xc80000;
          }
          else {
            uVar7 = *(int *)(param_1 + 0x3a4) + *piVar1;
            uVar8 = (int)uVar7 >> 0x1f;
            iVar5 = (uVar7 ^ uVar8) - uVar8;
          }
          if (0x2cffff < iVar5) goto LAB_005ac069;
          uVar6 = FUN_005ec240();
          cVar3 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180b);
joined_r0x005ac049:
          if (cVar3 != '\0') {
            FUN_004eb370(*(undefined4 *)(param_1 + 0x2c0));
          }
          goto LAB_005ac060;
        }
        uVar6 = FUN_005ec240();
        cVar3 = *(char *)(*(int *)(param_1 + 0x18c) + 0x180b);
      }
      if (cVar3 != '\0') {
        FUN_004eb110(*(undefined4 *)(param_1 + 0x2c0));
      }
    }
    else {
      uVar7 = *(uint *)(param_1 + 0xa4);
      uVar8 = *(uint *)(param_1 + 8);
      if (((((-1 < (int)uVar8) - 1 & 0xfffffffe) + 1 == ((-1 < (int)uVar7) - 1 & 0xfffffffe) + 1) ||
          ((int)((uVar8 ^ (int)uVar8 >> 0x1f) - ((int)uVar8 >> 0x1f)) < 0xf0001)) ||
         ((int)((uVar7 ^ (int)uVar7 >> 0x1f) - ((int)uVar7 >> 0x1f)) < 0xf0001)) {
        iVar5 = *(int *)(param_1 + 0xa0);
        iVar9 = ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1;
        if ((iVar5 - *piVar1) * iVar9 < 0x190001) {
          if (((*piVar1 - iVar5) * iVar9 < 0x140001) ||
             (uVar7 = iVar5 + *(int *)(param_1 + 0x3a4), uVar8 = (int)uVar7 >> 0x1f,
             0x1dffff < (int)((uVar7 ^ uVar8) - uVar8))) {
            iVar9 = *(int *)(param_1 + 0xa4) - *(int *)(param_1 + 8);
            iVar5 = *(int *)(param_1 + 0xa0) - *piVar1;
            sVar4 = FUN_005ee080(iVar5,iVar9);
            iVar5 = FUN_005edfb0(iVar5,*(undefined4 *)
                                        (&DAT_006d31c8 + (sVar4 + 8 >> 4 & 0xfffU) * 4),iVar9,
                                 *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar4 >> 4 & 0xfffU) * 4)
                                );
            if ((0x7ffff < iVar5) ||
               ((((-1 < *piVar1) - 1 & 0xfffffffe) + 1 ==
                 ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1 ||
                (iVar5 = FUN_005ec250(),
                499 < (int)(iVar5 * 1000 + (iVar5 * 1000 >> 0x1f & 0x7fffU)) >> 0xf))))
            goto LAB_005ac069;
            uVar6 = FUN_005ec240();
            if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
              FUN_004ea9f0();
            }
          }
          else {
            uVar6 = FUN_005ec240();
            if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
              FUN_004ea790();
            }
          }
        }
        else {
          uVar6 = FUN_005ec240();
          if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
            FUN_004ead80();
          }
        }
      }
      else {
        uVar6 = FUN_005ec240();
        if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
          FUN_004ea8c0();
        }
      }
    }
  }
  else {
    cVar3 = FUN_0058fb50(piVar1);
    if ((cVar3 == '\0') ||
       (((-1 < *piVar1) - 1 & 0xfffffffe) + 1 !=
        ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    if (!bVar2) {
      cVar3 = FUN_005ac0e0(piVar1);
      if ((cVar3 == '\0') ||
         (((-1 < *piVar1) - 1 & 0xfffffffe) + 1 !=
          ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if (!bVar2) goto LAB_005abbe8;
    }
    uVar7 = *(uint *)(param_1 + 0xa0);
    if ((((-1 < (int)uVar7) - 1 & 0xfffffffe) + 1 ==
         ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1) &&
       (0xeffff < (int)((uVar7 ^ (int)uVar7 >> 0x1f) - ((int)uVar7 >> 0x1f)))) goto LAB_005abbe8;
    FUN_00594470(0xe,param_1,0);
    if (0x18ccc < *(int *)(*(int *)(param_1 + 400) + 0xc)) {
      uVar6 = FUN_005ec240();
      if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
        FUN_00606220();
      }
      FUN_005ec230(uVar6);
    }
    iVar5 = *(int *)(param_1 + 400);
    sVar4 = FUN_005ee080(*(undefined4 *)(iVar5 + 0x20),*(undefined4 *)(iVar5 + 0x24));
    FUN_00436fb0(*(undefined4 *)(&DAT_006d31c8 + (sVar4 + 8 >> 4 & 0xfffU) * 4),
                 *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar4 >> 4 & 0xfffU) * 4));
    iVar5 = FUN_005edfb0(*(undefined4 *)(iVar5 + 0x20),local_20,*(undefined4 *)(iVar5 + 0x24),
                         local_1c);
    if (iVar5 < 0x7333) {
      uVar6 = FUN_005ec240();
      if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
        FUN_00606220();
      }
    }
    else {
      uVar6 = FUN_005ec240();
      if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
        FUN_00606220();
      }
    }
  }
LAB_005ac060:
  FUN_005ec230(uVar6);
LAB_005ac069:
  FUN_0058eca0(param_1);
  FUN_0058ed70();
  if (param_1 == *(int *)(*(int *)(param_1 + 0x18c) + 0x438)) {
    *(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x438) = 0;
  }
  FUN_005942e0(0);
  if (param_1 == 0) {
    iVar5 = 0xc80000;
  }
  else {
    uVar7 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
    uVar8 = (int)uVar7 >> 0x1f;
    iVar5 = (uVar7 ^ uVar8) - uVar8;
  }
  *(bool *)(*(int *)(param_1 + 400) + 100) = 0x1e0000 < iVar5;
  return;
}


