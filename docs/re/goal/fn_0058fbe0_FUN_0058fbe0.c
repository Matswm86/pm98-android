// FUN_0058fbe0  entry=0058fbe0  size=445 bytes

/* WARNING: Removing unreachable block (ram,0x0058fc5f) */

char __fastcall FUN_0058fbe0(int param_1)

{
  uint uVar1;
  int iVar2;
  uint uVar3;
  bool bVar4;
  int iVar5;
  int iVar6;
  uint uVar7;
  uint uVar8;
  uint uVar9;
  char local_19;
  int local_18;
  int local_c;
  int local_8;
  
  iVar6 = *(int *)(param_1 + 0x1d4);
  local_c = *(int *)(iVar6 + 0x1820);
  if ((*(uint *)(iVar6 + 0x19a0) & 1) == *(uint *)(param_1 + 0x54)) {
    local_c = -local_c;
  }
  iVar2 = *(int *)(iVar6 + 0x1824);
  iVar5 = *(int *)(iVar6 + 0x1820);
  if ((*(uint *)(iVar6 + 0x19a0) & 1) == *(uint *)(param_1 + 0x54)) {
    iVar5 = -iVar5;
  }
  iVar5 = iVar5 * 2;
  iVar6 = -iVar2;
  local_18 = iVar5;
  if (local_c < iVar5) {
    local_18 = local_c;
    local_c = iVar5;
  }
  iVar5 = iVar6;
  local_8 = iVar2;
  if (-iVar2 != iVar2 && iVar2 <= iVar6) {
    iVar5 = iVar2;
    local_8 = iVar6;
  }
  if ((((*(int *)(param_1 + 4) <= local_18) || (local_c <= *(int *)(param_1 + 4))) ||
      (*(int *)(param_1 + 8) <= iVar5)) ||
     (((local_8 <= *(int *)(param_1 + 8) || (*(int *)(param_1 + 0xc) < 0)) ||
      (local_19 = '\x01', 0x3e7ffff < *(int *)(param_1 + 0xc))))) {
    local_19 = '\0';
  }
  if (local_19 != '\0') {
    iVar6 = 0x4ccc - *(int *)(*(int *)(param_1 + 0x1d4) + 0x1820);
    if ((*(uint *)(*(int *)(param_1 + 0x1d4) + 0x19a0) & 1) != *(uint *)(param_1 + 0x54)) {
      iVar6 = -iVar6;
    }
    *(int *)(param_1 + 0x90) = iVar6;
    bVar4 = false;
    *(uint *)(param_1 + 0x94) =
         (iVar2 + -0xb333) * (((-1 < *(int *)(param_1 + 8)) - 1 & 0xfffffffe) + 1);
    *(undefined4 *)(param_1 + 0x98) = 0;
    if (*(int *)(param_1 + 0xc) < 0x2828e) {
      uVar3 = *(uint *)(param_1 + 8);
      iVar6 = (uVar3 ^ (int)uVar3 >> 0x1f) - ((int)uVar3 >> 0x1f);
      if (iVar6 < 0x3deb7) {
        uVar7 = iVar6 - 0x3deb7;
        uVar8 = (int)uVar7 >> 0x1f;
        uVar1 = *(int *)(param_1 + 0xc) - 0x2828e;
        uVar9 = (int)uVar1 >> 0x1f;
        if ((int)((uVar1 ^ uVar9) - uVar9) < (int)((uVar7 ^ uVar8) - uVar8)) {
          *(undefined4 *)(param_1 + 0xc) = 0x2828e;
          if (*(int *)(param_1 + 0x28) < 0) {
            bVar4 = true;
            *(int *)(param_1 + 0x28) = -*(int *)(param_1 + 0x28);
          }
        }
        else {
          bVar4 = true;
          *(uint *)(param_1 + 8) = (((-1 < (int)uVar3) - 1 & 0xfffffffe) + 1) * 0x3deb7;
          *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
        }
        if (bVar4) {
          FUN_005ee1c0(0x9eb8);
          if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x180a) != '\0') {
            FUN_00590f00();
          }
        }
      }
    }
  }
  return local_19;
}


