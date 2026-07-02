// FUN_00605da0  entry=00605da0  size=115 bytes

void FUN_00605da0(undefined4 param_1,undefined4 param_2,int param_3,code *param_4)

{
  void *local_14;
  undefined *puStack_10;
  undefined *puStack_c;
  undefined4 local_8;
  
  puStack_c = &DAT_0063aa20;
  puStack_10 = &DAT_006061c6;
  local_14 = ExceptionList;
  local_8 = 0;
  ExceptionList = &local_14;
  while( true ) {
    param_3 = param_3 + -1;
    if (param_3 < 0) break;
    (*param_4)();
  }
  local_8 = 0xffffffff;
  FUN_00605e19();
  ExceptionList = local_14;
  return;
}


