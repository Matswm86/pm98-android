// FUN_005f3410  entry=005f3410  size=104 bytes
// callers/callees expanded one level from seeds

int __thiscall
FUN_005f3410(int *param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
            undefined4 param_5)

{
  int iVar1;
  
  for (iVar1 = param_1[1]; iVar1 != 0; iVar1 = iVar1 + -1) {
    FUN_005f1910(param_2,param_3,param_4,param_4,param_5,param_5);
  }
  if (param_1[1] != 0) {
    return *(int *)(*(int *)(*param_1 + 0x100) + 0x14) + -1;
  }
  return 0;
}


