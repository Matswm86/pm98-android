// FUN_0042aa00  entry=0042aa00  size=370 bytes

void __fastcall FUN_0042aa00(CWnd *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_0047f9e9;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *(undefined ***)param_1 = &PTR_LAB_00486910;
  local_4 = 0x10;
  FUN_0045dd50(param_1,0);
  local_4._0_1_ = 0xf;
  FUN_0047e100(param_1 + 0x742c,0x4c,4,thunk_FUN_0044e5d0);
  local_4._0_1_ = 0xe;
  FUN_0047e100(param_1 + 0x72fc,0x4c,4,thunk_FUN_0044e5d0);
  local_4._0_1_ = 0xd;
  FUN_0047e100(param_1 + 0x629c,0x418,4,thunk_FUN_00454120);
  local_4._0_1_ = 0xc;
  FUN_00454120(param_1 + 0x5e84);
  local_4._0_1_ = 0xb;
  FUN_00454120(param_1 + 0x5a6c);
  local_4._0_1_ = 10;
  FUN_00454120(param_1 + 0x5654);
  local_4._0_1_ = 9;
  FUN_00454120(param_1 + 0x523c);
  local_4._0_1_ = 8;
  FUN_00454120(param_1 + 0x4e24);
  local_4._0_1_ = 7;
  FUN_00454120(param_1 + 0x4a0c);
  local_4._0_1_ = 6;
  FUN_00454120(param_1 + 0x45f4);
  local_4._0_1_ = 5;
  FUN_00454120(param_1 + 0x41dc);
  local_4._0_1_ = 4;
  FUN_00454120(param_1 + 0x3dc4);
  local_4._0_1_ = 3;
  FUN_00454120(param_1 + 0x39ac);
  local_4._0_1_ = 2;
  FUN_00454120(param_1 + 0x3594);
  local_4._0_1_ = 1;
  FUN_00454120(param_1 + 0x317c);
  local_4 = (uint)local_4._1_3_ << 8;
  FUN_00454120(param_1 + 0x2d64);
  local_4 = 0xffffffff;
  FUN_00446a10(param_1);
  ExceptionList = local_c;
  return;
}


