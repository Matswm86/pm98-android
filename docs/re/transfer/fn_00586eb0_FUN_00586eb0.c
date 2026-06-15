// FUN_00586eb0  entry=00586eb0  size=84 bytes

int __thiscall FUN_00586eb0(int *param_1,uint param_2)

{
  int iVar1;
  uint *puVar2;
  int iVar3;
  int local_4;
  
  puVar2 = (uint *)param_1[1];
  iVar3 = *param_1;
  local_4 = 0;
  for (; iVar3 != 0; iVar3 = iVar3 + -1) {
    if (*puVar2 < DAT_0066c150) {
      iVar1 = *(int *)(DAT_0066c158 + *puVar2 * 4);
    }
    else {
      iVar1 = 0;
    }
    if (*(byte *)(iVar1 + 0x1c) == param_2) {
      local_4 = local_4 + 1;
    }
    puVar2 = puVar2 + 1;
  }
  return local_4;
}


