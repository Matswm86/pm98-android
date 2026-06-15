// FUN_005884f0  entry=005884f0  size=130 bytes

int __thiscall FUN_005884f0(int param_1,uint param_2)

{
  int iVar1;
  int iVar2;
  uint *puVar3;
  int local_4;
  
  iVar2 = *(int *)(param_1 + 0x24);
  local_4 = 0;
  for (; iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x100)) {
    if ((*(byte *)(iVar2 + 0x1c) == param_2) &&
       ((uint)*(ushort *)(iVar2 + 0x6c) == *(uint *)(param_1 + 0x10))) {
      local_4 = local_4 + 1;
    }
  }
  iVar2 = *(int *)(param_1 + 0x48);
  if (iVar2 != 0) {
    puVar3 = *(uint **)(param_1 + 0x44);
    do {
      if (*puVar3 < DAT_0066c150) {
        iVar1 = *(int *)(DAT_0066c158 + *puVar3 * 4);
      }
      else {
        iVar1 = 0;
      }
      if ((iVar1 != 0) && (*(byte *)(iVar1 + 0x1c) == param_2)) {
        local_4 = local_4 + 1;
      }
      puVar3 = puVar3 + 1;
      iVar2 = iVar2 + -1;
    } while (iVar2 != 0);
  }
  return local_4;
}


