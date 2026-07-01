// FUN_005b1190  entry=005b1190  size=89 bytes

undefined4 * __thiscall FUN_005b1190(undefined4 *param_1,int param_2)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_00620d28;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = 0;
  param_1[1] = 0;
  local_4 = 0;
  if (param_2 != 0) {
    FUN_005bbf10(param_1,param_2 * 0x24);
    param_1[1] = param_2;
  }
  ExceptionList = local_c;
  return param_1;
}


