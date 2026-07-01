// FUN_0058f0b0  entry=0058f0b0  size=70 bytes

bool __thiscall FUN_0058f0b0(int param_1,uint param_2)

{
  int iVar1;
  
  iVar1 = *(int *)(*(int *)(param_1 + 0x1d4) + 0x1820);
  if ((*(uint *)(*(int *)(param_1 + 0x1d4) + 0x19a0) & 1) == param_2) {
    iVar1 = -iVar1;
  }
  return ((-1 < *(int *)(param_1 + 4)) - 1 & 0xfffffffe) + 1 != ((-1 < iVar1) - 1 & 0xfffffffe) + 1;
}


