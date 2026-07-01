// FUN_0059a0e0  entry=0059a0e0  size=64 bytes

void __thiscall FUN_0059a0e0(int param_1,int *param_2,int *param_3)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  
  iVar3 = param_3[1];
  uVar1 = *(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1 ^ *(uint *)(param_1 + 0x2b8);
  if (uVar1 != 0) {
    iVar3 = -iVar3;
  }
  iVar2 = *param_3;
  if (uVar1 != 0) {
    iVar2 = -iVar2;
  }
  param_2[2] = param_3[2];
  *param_2 = iVar2;
  param_2[1] = iVar3;
  return;
}


