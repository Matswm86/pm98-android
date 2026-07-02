// FUN_005b4f70  entry=005b4f70  size=474 bytes

undefined4 __fastcall FUN_005b4f70(int param_1)

{
  int iVar1;
  int iVar2;
  int local_18;
  int local_14;
  int local_10;
  int local_c;
  int local_8;
  int local_4;
  
  if (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40)) {
    iVar1 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
    if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1)) {
      iVar1 = -iVar1;
    }
    FUN_00590aa0(iVar1,0,0);
    iVar1 = *(int *)(param_1 + 0x218);
    iVar2 = iVar1;
    if (iVar1 <= local_10) {
      iVar2 = local_10;
    }
    local_4 = *(int *)(param_1 + 0x224);
    if ((iVar2 <= *(int *)(param_1 + 0x224)) && (local_4 = iVar1, iVar1 <= local_10)) {
      local_4 = local_10;
    }
    iVar1 = *(int *)(param_1 + 0x214);
    iVar2 = iVar1;
    if (iVar1 <= local_14) {
      iVar2 = local_14;
    }
    local_8 = *(int *)(param_1 + 0x220);
    if ((iVar2 <= local_8) && (local_8 = iVar1, iVar1 <= local_14)) {
      local_8 = local_14;
    }
    iVar1 = *(int *)(param_1 + 0x210);
    iVar2 = iVar1;
    if (iVar1 <= local_18) {
      iVar2 = local_18;
    }
    local_c = *(int *)(param_1 + 0x21c);
    if ((iVar2 <= *(int *)(param_1 + 0x21c)) && (local_c = iVar1, iVar1 <= local_18)) {
      local_c = local_18;
    }
    FUN_005a89c0(&local_c,9);
    iVar1 = *(int *)(*(int *)(param_1 + 0x184) + 0x304);
    iVar2 = FUN_005ec250();
    if (((int)(iVar2 * 1000 + (iVar2 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < (100 - iVar1) * 10) &&
       (iVar1 = FUN_005b31a0(3,1), iVar1 != 0)) {
      FUN_005b3a10(iVar1,0,1);
      return 1;
    }
    iVar1 = FUN_005b31a0(0,1);
    if (iVar1 != 0) {
      FUN_005b3a10(iVar1,0,0);
      return 1;
    }
  }
  else {
    local_18 = *(int *)(param_1 + 0x1ec);
    local_14 = *(undefined4 *)(param_1 + 0x1f0);
    local_10 = *(undefined4 *)(param_1 + 500);
    iVar1 = *(int *)(*(int *)(param_1 + 0x184) + 0x200);
    if (param_1 != iVar1) {
      local_18 = *(int *)(iVar1 + 4);
    }
    if (*(int *)(*(int *)(param_1 + 0x184) + 0x30c) == 0) {
      FUN_005a89c0(&local_18,0x28);
      return 1;
    }
    FUN_005a89c0(&local_18,9);
  }
  return 1;
}


