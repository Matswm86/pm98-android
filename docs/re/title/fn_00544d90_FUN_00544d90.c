// FUN_00544d90  entry=00544d90  size=90 bytes

undefined4 * __thiscall FUN_00544d90(undefined4 *param_1,int param_2)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_0061b4e8;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = 0;
  param_1[1] = 0;
  local_4 = 0;
  if (param_2 != 0) {
    FUN_005bbf10(param_1,param_2 * 4);
    param_1[1] = param_2;
  }
  ExceptionList = local_c;
  return param_1;
}


