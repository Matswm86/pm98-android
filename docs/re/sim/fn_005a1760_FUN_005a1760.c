// FUN_005a1760  entry=005a1760  size=181 bytes
// callers/callees expanded one level from seeds

int * __thiscall FUN_005a1760(int *param_1,int param_2)

{
  int iVar1;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_00620bd8;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = 0;
  param_1[1] = 0;
  local_4 = 0;
  if (param_2 != 0) {
    if (param_2 < 0) {
      do {
        iVar1 = param_1[1];
        param_1[1] = iVar1 + -1;
        if (*param_1 + (iVar1 + -1) * 0x4c != 0) {
          thunk_FUN_005cb040();
        }
      } while (param_2 < param_1[1]);
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
  }
  ExceptionList = local_c;
  return param_1;
}


