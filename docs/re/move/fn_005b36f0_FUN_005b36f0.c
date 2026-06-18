// FUN_005b36f0  entry=005b36f0  size=788 bytes

int __fastcall FUN_005b36f0(int param_1)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  bool bVar8;
  int local_1c;
  int local_18;
  int local_14;
  int local_10;
  int local_8;
  
  iVar6 = *(int *)(param_1 + 0xb0);
  if (iVar6 != 0) {
    iVar7 = *(int *)(param_1 + 0x184);
    if (*(int *)(iVar7 + 0x310) == 0) {
      if ((((*(int *)(iVar6 + 4) < *(int *)(param_1 + 0x210)) ||
           (*(int *)(param_1 + 0x21c) < *(int *)(iVar6 + 4))) ||
          (*(int *)(iVar6 + 8) < *(int *)(param_1 + 0x214))) ||
         (((*(int *)(param_1 + 0x220) < *(int *)(iVar6 + 8) ||
           (*(int *)(iVar6 + 0xc) < *(int *)(param_1 + 0x218))) ||
          (*(int *)(param_1 + 0x224) < *(int *)(iVar6 + 0xc))))) {
        bVar8 = false;
      }
      else {
        bVar8 = true;
      }
    }
    else {
      iVar2 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
      iVar5 = *(int *)(iVar7 + 0x300) + iVar2;
      uVar1 = *(int *)(param_1 + 0x1e0) - *(int *)(param_1 + 0x3a4);
      uVar4 = (int)uVar1 >> 0x1f;
      if ((int)((uVar1 ^ uVar4) - uVar4) < iVar5) {
        uVar1 = *(int *)(iVar6 + 4) + *(int *)(iVar6 + 0x3a4);
        uVar4 = (int)uVar1 >> 0x1f;
        iVar3 = (uVar1 ^ uVar4) - uVar4;
        bVar8 = SBORROW4(iVar3,iVar5);
        iVar3 = iVar3 - iVar5;
      }
      else {
        uVar1 = *(int *)(iVar6 + 4) + *(int *)(iVar6 + 0x3a4);
        uVar4 = (int)uVar1 >> 0x1f;
        iVar3 = (uVar1 ^ uVar4) - uVar4;
        iVar2 = *(int *)(iVar7 + 0x2fc) + iVar2;
        bVar8 = SBORROW4(iVar3,iVar2);
        iVar3 = iVar3 - iVar2;
      }
      bVar8 = bVar8 != iVar3 < 0;
    }
    if (bVar8) {
      return iVar6;
    }
  }
  local_10 = 0x3e80000;
  local_8 = (*(int **)(param_1 + 0x188))[1];
  iVar7 = **(int **)(param_1 + 0x188);
  local_18 = iVar6;
  while (local_8 != 0) {
    local_8 = local_8 + -1;
    if (*(int *)(iVar7 + 0x154) == 0) {
      if (iVar7 == 0) {
        local_1c = 0xc80000;
      }
      else {
        local_1c = *(int *)(param_1 + 0xe4 +
                           (*(int *)(iVar7 + 0x2c4) + *(int *)(iVar7 + 0x2b8) * 0xb) * 4);
      }
      if (((*(int *)(param_1 + 0x210) < *(int *)(iVar7 + 4)) &&
          (*(int *)(iVar7 + 4) < *(int *)(param_1 + 0x21c))) &&
         ((*(int *)(param_1 + 0x214) < *(int *)(iVar7 + 8) &&
          (((*(int *)(iVar7 + 8) < *(int *)(param_1 + 0x220) &&
            (*(int *)(param_1 + 0x218) < *(int *)(iVar7 + 0xc))) &&
           (*(int *)(iVar7 + 0xc) < *(int *)(param_1 + 0x224))))))) {
        bVar8 = true;
      }
      else {
        bVar8 = false;
      }
      if (!bVar8) {
        local_1c = FUN_005edfa0(local_1c,(-(uint)(*(int *)(*(int *)(param_1 + 0x184) + 0x310) != 0)
                                         & 0xffffb333) + 0x18000);
      }
      if (*(int *)(param_1 + 0x2b8) == *(int *)(iVar7 + 0x2b8)) {
        if (iVar7 == 0) {
          iVar5 = 0xc80000;
        }
        else {
          uVar1 = *(int *)(iVar7 + 4) - *(int *)(iVar7 + 0x3a4);
          uVar4 = (int)uVar1 >> 0x1f;
          iVar5 = (uVar1 ^ uVar4) - uVar4;
        }
      }
      else {
        iVar5 = FUN_005b1c60();
      }
      iVar2 = FUN_005b1c40();
      if (iVar5 <= iVar2) {
        uVar1 = *(int *)(iVar7 + 4) - *(int *)(param_1 + 4);
        uVar4 = (int)uVar1 >> 0x1f;
        local_1c = FUN_005edfa0(local_1c,(int)((uVar1 ^ uVar4) - uVar4) / 0xf + 0x10000);
      }
      if ((*(int *)(iVar7 + 700) != 0) && (local_1c < local_10)) {
        iVar2 = 0x3e80000;
        local_14 = 0;
        iVar6 = (*(int **)(param_1 + 0x184))[1];
        iVar5 = **(int **)(param_1 + 0x184);
        while (iVar6 != 0) {
          iVar6 = iVar6 + -1;
          if (*(int *)(iVar5 + 700) != 0) {
            if (iVar5 == 0) {
              iVar3 = 0xc80000;
            }
            else {
              iVar3 = *(int *)(iVar7 + 0xe4 +
                              (*(int *)(iVar5 + 0x2c4) + *(int *)(iVar5 + 0x2b8) * 0xb) * 4);
            }
            if (iVar3 < iVar2) {
              iVar2 = iVar3;
              local_14 = iVar5;
            }
          }
          iVar5 = iVar5 + 0x3bc;
        }
        iVar6 = local_18;
        if (local_14 == param_1) {
          local_10 = local_1c;
          iVar6 = iVar7;
          local_18 = iVar7;
        }
      }
    }
    iVar7 = iVar7 + 0x3bc;
  }
  return iVar6;
}


