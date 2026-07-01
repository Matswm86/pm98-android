// FUN_005f3700  entry=005f3700  size=66 bytes

undefined4 __thiscall FUN_005f3700(int param_1,undefined4 param_2)

{
  int iVar1;
  
  FUN_005f3600();
  FUN_005d82b0(param_1 + 0x10);
  for (iVar1 = *(int *)(param_1 + 4); iVar1 != 0; iVar1 = iVar1 + -1) {
    FUN_005f1e80(param_2);
  }
  return 1;
}


