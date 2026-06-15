// FUN_00605ee0  entry=00605ee0  size=111 bytes
// callers/callees expanded one level from seeds

void FUN_00605ee0(undefined4 param_1,undefined4 param_2,int param_3,code *param_4)

{
  int iVar1;
  void *local_14;
  undefined *puStack_10;
  undefined *puStack_c;
  undefined4 local_8;
  
  puStack_c = &DAT_0063aa40;
  puStack_10 = &DAT_006061c6;
  local_14 = ExceptionList;
  local_8 = 0;
  ExceptionList = &local_14;
  for (iVar1 = 0; iVar1 < param_3; iVar1 = iVar1 + 1) {
    (*param_4)();
  }
  local_8 = 0xffffffff;
  FUN_00605f58();
  ExceptionList = local_14;
  return;
}


