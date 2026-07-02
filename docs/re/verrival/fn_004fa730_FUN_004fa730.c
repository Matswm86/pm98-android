// FUN_004fa730  entry=004fa730  size=193 bytes

void __fastcall FUN_004fa730(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_006163c6;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = &PTR_LAB_006241e0;
  local_4 = 3;
  FUN_005c1df0(&DAT_00658a58);
  local_4._0_1_ = 6;
  FUN_005bc6a0();
  local_4._0_1_ = 5;
  FUN_005bc6a0();
  local_4._0_1_ = 4;
  FUN_005bc6a0();
  local_4._0_1_ = 2;
  FUN_005c5410();
  local_4._0_1_ = 1;
  FUN_005bc6a0();
  local_4 = (uint)local_4._1_3_ << 8;
  thunk_FUN_005cb040();
  local_4 = 0xffffffff;
  FUN_005c5410();
  ExceptionList = local_c;
  return;
}


