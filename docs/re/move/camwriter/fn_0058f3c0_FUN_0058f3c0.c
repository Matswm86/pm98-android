// FUN_0058f3c0  entry=0058f3c0  size=1922 bytes

/* WARNING: Removing unreachable block (ram,0x0058f44a) */

char __fastcall FUN_0058f3c0(int param_1)

{
  int *piVar1;
  bool bVar2;
  char cVar3;
  short sVar4;
  short sVar5;
  int iVar6;
  undefined4 *puVar7;
  int iVar8;
  uint uVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  uint uVar12;
  int iVar13;
  uint uVar14;
  uint uVar15;
  uint uVar16;
  char local_35;
  undefined1 local_24 [12];
  undefined1 local_18 [4];
  int local_14;
  undefined4 local_10;
  int local_c;
  undefined4 local_4;
  
  iVar8 = *(int *)(param_1 + 0x1d4);
  uVar12 = 1 - *(int *)(param_1 + 0x54);
  local_c = *(int *)(iVar8 + 0x1820);
  if ((*(uint *)(iVar8 + 0x19a0) & 1) == uVar12) {
    local_c = -local_c;
  }
  iVar13 = *(int *)(iVar8 + 0x1824);
  iVar6 = *(int *)(iVar8 + 0x1820);
  if ((*(uint *)(iVar8 + 0x19a0) & 1) == uVar12) {
    iVar6 = -iVar6;
  }
  iVar6 = iVar6 * 2;
  local_14 = -iVar13;
  local_10 = 0xffffffff;
  local_4 = 0x3e80000;
  iVar8 = iVar6;
  if (local_c < iVar6) {
    iVar8 = local_c;
    local_c = iVar6;
  }
  iVar6 = iVar13;
  if (iVar13 < local_14) {
    iVar6 = local_14;
    local_14 = iVar13;
  }
  iVar13 = 0x58000 - *(int *)(*(int *)(param_1 + 0x1d4) + 0x1820);
  if ((*(uint *)(*(int *)(param_1 + 0x1d4) + 0x19a0) & 1) != uVar12) {
    iVar13 = -iVar13;
  }
  *(int *)(param_1 + 0x90) = iVar13;
  *(uint *)(param_1 + 0x94) = (((-1 < *(int *)(param_1 + 8)) - 1 & 0xfffffffe) + 1) * 0x928f5;
  *(undefined4 *)(param_1 + 0x98) = 0;
  if ((((*(int *)(param_1 + 4) <= iVar8) || (local_c <= *(int *)(param_1 + 4))) ||
      (*(int *)(param_1 + 8) <= local_14)) ||
     (((iVar6 <= *(int *)(param_1 + 8) || (*(int *)(param_1 + 0xc) < 0)) ||
      (local_35 = '\x01', 0x3e7ffff < *(int *)(param_1 + 0xc))))) {
    local_35 = '\0';
  }
  if (local_35 == '\0') {
    return '\0';
  }
  bVar2 = false;
  if (((*(int *)(param_1 + 0x4c) == 0) && (iVar8 = *(int *)(param_1 + 0x50), iVar8 != 0)) &&
     (DAT_006d31c4 == '\0')) {
    iVar13 = *(int *)(*(int *)(iVar8 + 0x18c) + 0x1820);
    if (1U - *(int *)(iVar8 + 0x2b8) == (*(uint *)(*(int *)(iVar8 + 0x18c) + 0x19a0) & 1)) {
      iVar13 = -iVar13;
    }
    FUN_00590aa0(iVar13,0,0);
    iVar8 = *(int *)(param_1 + 0x50);
    puVar7 = (undefined4 *)FUN_00590ae0(local_24,iVar8 + 4);
    sVar4 = FUN_005ee080(*puVar7,puVar7[1]);
    iVar13 = *(int *)(param_1 + 0x50);
    puVar7 = (undefined4 *)FUN_00590ae0(local_18,iVar13 + 4);
    sVar5 = FUN_005ee080(*puVar7,puVar7[1]);
    uVar12 = (uint)(short)(((*(short *)(iVar8 + 0x34) - *(short *)(iVar13 + 0x34)) + sVar5) - sVar4)
    ;
    uVar14 = (int)uVar12 >> 0x1f;
    if ((int)((uVar12 ^ uVar14) - uVar14) < 0x3555) {
      iVar8 = *(int *)(param_1 + 0x50);
      if (iVar8 == 0) {
        iVar8 = 0xc80000;
      }
      else {
        uVar12 = *(int *)(iVar8 + 0x3a4) + *(int *)(iVar8 + 4);
        uVar14 = (int)uVar12 >> 0x1f;
        iVar8 = (uVar12 ^ uVar14) - uVar14;
      }
      if (iVar8 < 0x370000) {
        FUN_005909f0(0);
      }
    }
  }
  if (*(int *)(param_1 + 0xc) < 0x2828e) {
    uVar12 = *(uint *)(param_1 + 8);
    iVar8 = (uVar12 ^ (int)uVar12 >> 0x1f) - ((int)uVar12 >> 0x1f);
    if (iVar8 < 0x3deb7) {
      uVar9 = iVar8 - 0x3deb7;
      uVar15 = (int)uVar9 >> 0x1f;
      uVar14 = *(int *)(param_1 + 0xc) - 0x2828e;
      uVar16 = (int)uVar14 >> 0x1f;
      if ((int)((uVar14 ^ uVar16) - uVar16) < (int)((uVar9 ^ uVar15) - uVar15)) {
        *(undefined4 *)(param_1 + 0xc) = 0x2828e;
        if (*(int *)(param_1 + 0x28) < 0) {
          bVar2 = true;
          *(int *)(param_1 + 0x28) = -*(int *)(param_1 + 0x28);
        }
      }
      else {
        bVar2 = true;
        *(uint *)(param_1 + 8) = (((-1 < (int)uVar12) - 1 & 0xfffffffe) + 1) * 0x3deb7;
        *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
      }
      if ((bVar2) && (FUN_005ee1c0(0x9eb8), *(char *)(*(int *)(param_1 + 0x1d4) + 0x180a) != '\0'))
      {
        FUN_00590f00();
      }
    }
  }
  uVar12 = (int)*(uint *)(param_1 + 8) >> 0x1f;
  if (((int)((*(uint *)(param_1 + 8) ^ uVar12) - uVar12) < 0x528f5) &&
     (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180c) != '\0')) {
    FUN_00590f00();
  }
  if ((*(int *)(param_1 + 0x4c) == 0) && (iVar8 = *(int *)(param_1 + 0x50), iVar8 != 0)) {
    uVar12 = (int)*(uint *)(param_1 + 8) >> 0x1f;
    iVar13 = (*(uint *)(param_1 + 8) ^ uVar12) - uVar12;
    if (0x528f4 < iVar13) {
      cVar3 = FUN_00590c10(*(int *)(iVar8 + 0x18c) + 0x1828);
      if (((cVar3 == '\0') ||
          (uVar12 = *(uint *)(iVar8 + 4), uVar14 = (int)uVar12 >> 0x1f,
          (int)((uVar12 ^ uVar14) - uVar14) <=
          *(int *)(*(int *)(iVar8 + 0x18c) + 0x1820) + -0x108000)) ||
         (uVar12 = (int)*(uint *)(iVar8 + 8) >> 0x1f,
         0x1428f4 < (int)((*(uint *)(iVar8 + 8) ^ uVar12) - uVar12))) {
        bVar2 = false;
      }
      else {
        bVar2 = true;
      }
      if ((bVar2) &&
         (((-1 < (int)*(uint *)(iVar8 + 4)) - 1 & 0xfffffffe) + 1 !=
          ((-1 < *(int *)(iVar8 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
        bVar2 = true;
      }
      else {
        bVar2 = false;
      }
      if (bVar2) {
        FUN_00594470(0x17,0,0);
        uVar12 = (int)*(uint *)(param_1 + 8) >> 0x1f;
        if ((int)((*(uint *)(param_1 + 8) ^ uVar12) - uVar12) < 0x60001) {
          uVar10 = FUN_005ec240();
          if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180b) != '\0') {
            iVar8 = *(int *)(param_1 + 0x50);
            cVar3 = FUN_00590c10(*(int *)(iVar8 + 0x18c) + 0x1828);
            if (((cVar3 == '\0') ||
                (uVar12 = *(uint *)(iVar8 + 4), uVar14 = (int)uVar12 >> 0x1f,
                (int)((uVar12 ^ uVar14) - uVar14) <=
                *(int *)(*(int *)(iVar8 + 0x18c) + 0x1820) + -0x58000)) ||
               (uVar12 = (int)*(uint *)(iVar8 + 8) >> 0x1f,
               0x928f4 < (int)((*(uint *)(iVar8 + 8) ^ uVar12) - uVar12))) {
              bVar2 = false;
            }
            else {
              bVar2 = true;
            }
            if ((bVar2) &&
               (((-1 < (int)*(uint *)(iVar8 + 4)) - 1 & 0xfffffffe) + 1 !=
                ((-1 < *(int *)(iVar8 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
              uVar11 = 1;
            }
            else {
              uVar11 = 0;
            }
            FUN_004eb840(uVar11);
          }
        }
        else {
          uVar10 = FUN_005ec240();
          if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180b) != '\0') {
            FUN_005ed810(0);
          }
        }
      }
      else {
        FUN_00594470(0x18,0,0);
        uVar10 = FUN_005ec240();
        if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180b) != '\0') {
          FUN_004eb240(0);
        }
      }
      goto LAB_0058fb27;
    }
    if ((0x270a3 < *(int *)(param_1 + 0xc)) && (iVar13 < 0x3cccc)) {
      uVar10 = FUN_005ec240();
      if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180b) != '\0') {
        iVar8 = *(int *)(param_1 + 0x50);
        piVar1 = (int *)(iVar8 + 4);
        cVar3 = FUN_0058fb50(piVar1);
        if ((cVar3 == '\0') ||
           (((-1 < *piVar1) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *(int *)(iVar8 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
          bVar2 = false;
        }
        else {
          bVar2 = true;
        }
        if ((bVar2) &&
           (uVar12 = *(uint *)(*(int *)(param_1 + 0x50) + 8), uVar14 = (int)uVar12 >> 0x1f,
           (int)((uVar12 ^ uVar14) - uVar14) < 0xc0000)) {
          uVar11 = 1;
        }
        else {
          uVar11 = 0;
        }
        FUN_004eb970(0x58000 < *(int *)(param_1 + 0xc),uVar11);
      }
      FUN_005ec230(uVar10);
      FUN_00594470(0x19,0,2);
      *(undefined4 *)(param_1 + 0x50) = 0;
      return local_35;
    }
    if (*(int *)(param_1 + 0xc) < 0x26666) {
      FUN_00594470(0x18,0,2);
      if ((*(byte *)(*(int *)(param_1 + 0x1d4) + 0x462) & 0x60) == 0) {
        uVar10 = FUN_005ec240();
        if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180b) != '\0') {
          FUN_004ebbf0();
        }
      }
      else {
        uVar10 = FUN_005ec240();
        if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180b) != '\0') {
          FUN_004ebac0();
        }
      }
      goto LAB_0058fb27;
    }
    cVar3 = FUN_00590c10(*(int *)(iVar8 + 0x18c) + 0x1828);
    if (((cVar3 == '\0') ||
        (uVar12 = *(uint *)(iVar8 + 4), uVar14 = (int)uVar12 >> 0x1f,
        (int)((uVar12 ^ uVar14) - uVar14) <= *(int *)(*(int *)(iVar8 + 0x18c) + 0x1820) + -0x108000)
        ) || (uVar12 = (int)*(uint *)(iVar8 + 8) >> 0x1f,
             0x1428f4 < (int)((*(uint *)(iVar8 + 8) ^ uVar12) - uVar12))) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    if ((bVar2) &&
       (((-1 < (int)*(uint *)(iVar8 + 4)) - 1 & 0xfffffffe) + 1 !=
        ((-1 < *(int *)(iVar8 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
      bVar2 = true;
    }
    else {
      bVar2 = false;
    }
    if (bVar2) {
      FUN_00594470(0x17,0,0);
      uVar10 = FUN_005ec240();
      if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180b) != '\0') {
        FUN_005ed810(0);
      }
      goto LAB_0058fb27;
    }
    FUN_00594470(0x18,0,0);
    uVar10 = FUN_005ec240();
    cVar3 = *(char *)(*(int *)(param_1 + 0x1d4) + 0x180b);
  }
  else {
    uVar10 = FUN_005ec240();
    cVar3 = *(char *)(*(int *)(param_1 + 0x1d4) + 0x180b);
  }
  if (cVar3 != '\0') {
    FUN_004eafe0();
  }
LAB_0058fb27:
  FUN_005ec230(uVar10);
  *(undefined4 *)(param_1 + 0x50) = 0;
  return local_35;
}


