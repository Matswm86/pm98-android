// FUN_005f34c0  entry=005f34c0  size=66 bytes

void __thiscall FUN_005f34c0(int param_1,undefined4 param_2,undefined4 param_3)

{
  int iVar1;
  
  for (iVar1 = *(int *)(param_1 + 4); iVar1 != 0; iVar1 = iVar1 + -1) {
    FUN_005f1ac0(param_2,param_3);
  }
  *(undefined4 *)(param_1 + 0xc) = param_2;
  return;
}


