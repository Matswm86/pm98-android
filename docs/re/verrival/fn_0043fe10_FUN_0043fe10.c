// FUN_0043fe10  entry=0043fe10  size=179 bytes

void __fastcall FUN_0043fe10(int param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_006091d8;
  local_c = ExceptionList;
  local_4 = 5;
  ExceptionList = &local_c;
  FUN_00605da0(param_1 + 0xa80,0x4c,10,thunk_FUN_005cb040);
  local_4._0_1_ = 4;
  thunk_FUN_005cb040();
  local_4._0_1_ = 3;
  thunk_FUN_005cb040();
  local_4._0_1_ = 2;
  thunk_FUN_005cb040();
  local_4._0_1_ = 1;
  thunk_FUN_005cb040();
  local_4 = (uint)local_4._1_3_ << 8;
  FUN_00605da0(param_1 + 0x3f8,0x4c,0x12,thunk_FUN_005cb040);
  local_4 = 0xffffffff;
  FUN_005bc6a0();
  ExceptionList = local_c;
  return;
}


