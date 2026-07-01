// FUN_0058f140  entry=0058f140  size=636 bytes

undefined4 __fastcall FUN_0058f140(int param_1)

{
  int iVar1;
  bool bVar2;
  short sVar3;
  short sVar4;
  undefined4 uVar5;
  int iVar6;
  undefined4 *puVar7;
  int iVar8;
  byte bVar9;
  uint uVar10;
  uint uVar11;
  byte bVar12;
  int iVar13;
  int iVar14;
  undefined1 local_30 [24];
  int local_18;
  int local_14;
  int local_10;
  int local_c;
  int local_8;
  int local_4;
  
  iVar8 = *(int *)(param_1 + 0x1d4);
  FUN_00590ac0(iVar8 + 0x1828);
  FUN_00590ac0(iVar8 + 0x1834);
  uVar5 = FUN_00590ba0(0xccc);
  FUN_00590be0(uVar5);
  if (((((*(int *)(param_1 + 4) < local_18) || (local_c < *(int *)(param_1 + 4))) ||
       (*(int *)(param_1 + 8) < local_14)) ||
      ((local_8 < *(int *)(param_1 + 8) || (*(int *)(param_1 + 0xc) < local_10)))) ||
     (local_4 < *(int *)(param_1 + 0xc))) {
    bVar2 = false;
  }
  else {
    bVar2 = true;
  }
  if ((bVar2) ||
     (((uVar10 = (int)*(uint *)(param_1 + 8) >> 0x1f,
       (int)((*(uint *)(param_1 + 8) ^ uVar10) - uVar10) < 0x3a8f5 &&
       (uVar10 = (int)*(uint *)(param_1 + 4) >> 0x1f,
       (int)((*(uint *)(param_1 + 4) ^ uVar10) - uVar10) <=
       *(int *)(*(int *)(param_1 + 0x1d4) + 0x1820) + 0x10000)) &&
      (*(int *)(param_1 + 0xc) < 0x270a3)))) {
    bVar12 = 0;
  }
  else {
    bVar12 = 1;
  }
  bVar9 = *(byte *)(param_1 + 0x61) | bVar12 == 0;
  iVar8 = 0;
  *(byte *)(param_1 + 0x61) = bVar9;
  bVar12 = bVar12 & bVar9;
  if (bVar12 != 0) {
    if ((*(int *)(param_1 + 0x4c) == 0) && (iVar8 = *(int *)(param_1 + 0x50), iVar8 != 0)) {
      if (DAT_006d31c4 == '\0') {
        iVar6 = *(int *)(*(int *)(iVar8 + 0x18c) + 0x1820);
        if (1U - *(int *)(iVar8 + 0x2b8) == (*(uint *)(*(int *)(iVar8 + 0x18c) + 0x19a0) & 1)) {
          iVar6 = -iVar6;
        }
        FUN_00590aa0(iVar6,0,0);
        iVar8 = *(int *)(param_1 + 0x50);
        puVar7 = (undefined4 *)FUN_00590ae0(local_30,iVar8 + 4);
        sVar3 = FUN_005ee080(*puVar7,puVar7[1]);
        iVar6 = *(int *)(param_1 + 0x50);
        puVar7 = (undefined4 *)FUN_00590ae0(&local_18,iVar6 + 4);
        sVar4 = FUN_005ee080(*puVar7,puVar7[1]);
        uVar10 = (uint)(short)(((*(short *)(iVar8 + 0x34) - *(short *)(iVar6 + 0x34)) - sVar3) +
                              sVar4);
        uVar11 = (int)uVar10 >> 0x1f;
        if ((int)((uVar10 ^ uVar11) - uVar11) < 0x3555) {
          iVar8 = *(int *)(param_1 + 0x50);
          if (iVar8 == 0) {
            iVar8 = 0xc80000;
          }
          else {
            uVar10 = *(int *)(iVar8 + 0x3a4) + *(int *)(iVar8 + 4);
            uVar11 = (int)uVar10 >> 0x1f;
            iVar8 = (uVar10 ^ uVar11) - uVar11;
          }
          if (iVar8 < 0x370000) {
            FUN_005909f0(0);
          }
        }
      }
      *(undefined4 *)(param_1 + 0x50) = 0;
    }
    iVar8 = *(int *)(param_1 + 0x1d4);
    iVar6 = *(int *)(iVar8 + 0x182c);
    iVar1 = *(int *)(param_1 + 8);
    iVar13 = iVar6;
    if (iVar6 <= iVar1) {
      iVar13 = iVar1;
    }
    iVar14 = *(int *)(iVar8 + 0x1838);
    if ((iVar13 <= *(int *)(iVar8 + 0x1838)) && (iVar14 = iVar6, iVar6 <= iVar1)) {
      iVar14 = iVar1;
    }
    iVar6 = *(int *)(iVar8 + 0x1828);
    iVar1 = *(int *)(param_1 + 4);
    iVar13 = iVar6;
    if (iVar6 <= iVar1) {
      iVar13 = iVar1;
    }
    iVar8 = *(int *)(iVar8 + 0x1834);
    if ((iVar13 <= iVar8) && (iVar8 = iVar1, iVar1 < iVar6)) {
      iVar8 = iVar6;
    }
    *(int *)(param_1 + 0x90) = iVar8;
    *(int *)(param_1 + 0x94) = iVar14;
    *(undefined4 *)(param_1 + 0x98) = 0;
    iVar6 = ((-1 < *(int *)(param_1 + 0x94)) - 1 & 0xfffffffe) + 1;
    iVar8 = iVar6 * 0x3333;
    *(int *)(param_1 + 0x94) = *(int *)(param_1 + 0x94) + iVar6 * 0x6666;
  }
  return CONCAT31((int3)((uint)iVar8 >> 8),bVar12);
}


