// FUN_005b3d00  entry=005b3d00  size=309 bytes

undefined4 __fastcall FUN_005b3d00(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int local_c [3];
  
  if (param_1 != *(int *)(*(int *)(param_1 + 400) + 0x40)) {
    if (*(int *)(*(int *)(param_1 + 0x184) + 0x30c) != 0) {
      FUN_005a89c0(param_1 + 0x1ec,9);
      return 1;
    }
    FUN_005a89c0(param_1 + 0x1ec,0x28);
    return 1;
  }
  iVar3 = 0;
  local_c[0] = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
  if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1)) {
    local_c[0] = -local_c[0];
  }
  local_c[1] = 0;
  local_c[2] = 0;
  FUN_005a89c0(local_c,0x5a);
  iVar1 = *(int *)(*(int *)(param_1 + 0x184) + 0x304);
  iVar2 = FUN_005ec250();
  if ((int)(iVar2 * 1000 + (iVar2 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < (100 - iVar1) * 10) {
    iVar3 = FUN_005b31a0(1,0);
  }
  if (((iVar3 == 0) && (iVar3 = FUN_005b31a0(2,1), iVar3 == 0)) &&
     (iVar3 = FUN_005b31a0(0,1), iVar3 == 0)) {
    return 1;
  }
  FUN_005b3a10(iVar3,0,0);
  return 1;
}


