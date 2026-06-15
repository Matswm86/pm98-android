// FUN_005a1b30  entry=005a1b30  size=116 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_005a1b30(int *param_1,int param_2)

{
  int iVar1;
  
  iVar1 = param_1[1];
  while (param_2 < iVar1) {
    param_1[1] = iVar1 + -1;
    if (*param_1 + (iVar1 + -1) * 0x4c != 0) {
      thunk_FUN_005cb040();
    }
    iVar1 = param_1[1];
  }
  FUN_005bbf10(param_1,param_2 * 0x4c);
  iVar1 = param_1[1];
  param_1[1] = iVar1;
  while (iVar1 < param_2) {
    if (*param_1 + param_1[1] * 0x4c != 0) {
      FUN_005c9210();
    }
    iVar1 = param_1[1] + 1;
    param_1[1] = iVar1;
  }
  return;
}


