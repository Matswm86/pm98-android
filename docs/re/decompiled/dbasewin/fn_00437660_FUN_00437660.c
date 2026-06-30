// FUN_00437660  entry=00437660  size=191 bytes

void __fastcall FUN_00437660(CWnd *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_0048051a;
  local_c = ExceptionList;
  local_4 = 7;
  ExceptionList = &local_c;
  FUN_00454120(param_1 + 0x20e8);
  local_4._0_1_ = 6;
  FUN_00454120(param_1 + 0x1cd0);
  local_4._0_1_ = 5;
  FUN_00454120(param_1 + 0x18b8);
  local_4._0_1_ = 4;
  FUN_00454120(param_1 + 0x14a0);
  local_4._0_1_ = 3;
  FUN_00454120(param_1 + 0x1088);
  local_4._0_1_ = 2;
  FUN_00454120(param_1 + 0xc70);
  local_4._0_1_ = 1;
  FUN_00454120(param_1 + 0x858);
  local_4 = (uint)local_4._1_3_ << 8;
  FUN_00454120(param_1 + 0x440);
  local_4 = 0xffffffff;
  FUN_0045d2d0(param_1);
  ExceptionList = local_c;
  return;
}


