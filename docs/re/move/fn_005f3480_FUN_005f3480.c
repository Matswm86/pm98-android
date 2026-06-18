// FUN_005f3480  entry=005f3480  size=54 bytes

void __thiscall FUN_005f3480(int param_1,undefined4 param_2)

{
  int iVar1;
  
  for (iVar1 = *(int *)(param_1 + 4); iVar1 != 0; iVar1 = iVar1 + -1) {
    FUN_005f1aa0(param_2);
  }
  *(undefined4 *)(param_1 + 8) = param_2;
  return;
}


