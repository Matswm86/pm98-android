// FUN_0059a1e0  entry=0059a1e0  size=122 bytes

void __thiscall FUN_0059a1e0(int param_1,int *param_2,int param_3)

{
  int iVar1;
  int iVar2;
  
  if (*(int *)(param_1 + 0x3a4) < 0) {
    iVar1 = ((param_3 + -0x32) * *(int *)(*(int *)(param_1 + 0x18c) + 0x1820)) / 0x32;
    iVar2 = *param_2;
    if (iVar1 < *param_2) {
      *param_2 = iVar1;
      return;
    }
  }
  else {
    iVar1 = ((0x32 - param_3) * *(int *)(*(int *)(param_1 + 0x18c) + 0x1820)) / 0x32;
    iVar2 = *param_2;
    if (*param_2 < iVar1) {
      iVar2 = iVar1;
    }
  }
  *param_2 = iVar2;
  return;
}


