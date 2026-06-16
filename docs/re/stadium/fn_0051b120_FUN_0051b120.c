// FUN_0051b120  entry=0051b120  size=275 bytes

void __fastcall FUN_0051b120(int param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_006189d6;
  local_c = ExceptionList;
  local_4 = 0xb;
  ExceptionList = &local_c;
  FUN_005bc6a0();
  local_4._0_1_ = 10;
  FUN_005bc6a0();
  local_4._0_1_ = 9;
  FUN_005bc6a0();
  local_4._0_1_ = 8;
  FUN_005bc6a0();
  local_4._0_1_ = 7;
  FUN_005bc6a0();
  local_4._0_1_ = 6;
  FUN_005bc6a0();
  local_4._0_1_ = 5;
  FUN_00605da0(param_1 + 0x6a0,0x4c,4,thunk_FUN_005cb040);
  local_4._0_1_ = 4;
  FUN_00605da0(param_1 + 0x524,0x4c,5,thunk_FUN_005cb040);
  local_4._0_1_ = 3;
  thunk_FUN_005cb040();
  local_4._0_1_ = 2;
  thunk_FUN_005cb040();
  local_4._0_1_ = 1;
  thunk_FUN_005cb040();
  local_4 = (uint)local_4._1_3_ << 8;
  thunk_FUN_005cb040();
  local_4 = 0xffffffff;
  FUN_005bc6a0();
  ExceptionList = local_c;
  return;
}


