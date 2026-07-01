// FUN_005a44f0  entry=005a44f0  size=28 bytes

int __thiscall FUN_005a44f0(int param_1,uint param_2)

{
  int iVar1;
  
  iVar1 = *(int *)(param_1 + 0x1820);
  if ((*(uint *)(param_1 + 0x19a0) & 1) == param_2) {
    iVar1 = -iVar1;
  }
  return iVar1;
}


