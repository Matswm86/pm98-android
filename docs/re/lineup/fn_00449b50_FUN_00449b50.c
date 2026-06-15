// FUN_00449b50  entry=00449b50  size=116 bytes

int __thiscall FUN_00449b50(int param_1,short param_2)

{
  int iVar1;
  short *psVar2;
  
  iVar1 = 0;
  if (0 < *(int *)(param_1 + 0xa0)) {
    psVar2 = (short *)(*(int *)(param_1 + 0x9c) + 0x44);
    do {
      if (*psVar2 == param_2) {
        return *(int *)(param_1 + 0x9c) + iVar1 * 0x48;
      }
      iVar1 = iVar1 + 1;
      psVar2 = psVar2 + 0x24;
    } while (iVar1 < *(int *)(param_1 + 0xa0));
  }
  iVar1 = 0;
  if (0 < *(int *)(param_1 + 0xa8)) {
    psVar2 = (short *)(*(int *)(param_1 + 0xa4) + 0x44);
    do {
      if (*psVar2 == param_2) {
        return *(int *)(param_1 + 0xa4) + iVar1 * 0x48;
      }
      iVar1 = iVar1 + 1;
      psVar2 = psVar2 + 0x24;
    } while (iVar1 < *(int *)(param_1 + 0xa8));
    return 0;
  }
  return 0;
}


