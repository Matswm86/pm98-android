// FUN_005f33a0  entry=005f33a0  size=112 bytes
// callers/callees expanded one level from seeds

int __thiscall
FUN_005f33a0(int *param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
            undefined4 param_5,undefined4 param_6,undefined4 param_7)

{
  int iVar1;
  
  for (iVar1 = param_1[1]; iVar1 != 0; iVar1 = iVar1 + -1) {
    FUN_005f1910(param_2,param_3,param_4,param_5,param_6,param_7);
  }
  if (param_1[1] != 0) {
    return *(int *)(*(int *)(*param_1 + 0x100) + 0x14) + -1;
  }
  return 0;
}


