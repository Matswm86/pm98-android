// FUN_005e65e0  entry=005e65e0  size=259 bytes

undefined4 * __fastcall FUN_005e65e0(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_00621d57;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = &PTR_FUN_0063a008;
  DAT_006dc4d0 = 0;
  local_4 = 0;
  FUN_005e6450(&DAT_00666f70);
  param_1[0x26] = 0;
  param_1[0x27] = 0;
  FUN_005e6750();
  local_4._0_1_ = 1;
  FUN_005e6750();
  param_1[0x32] = 0;
  param_1[0x33] = 0;
  param_1[0x36] = 0;
  param_1[0x35] = 0;
  param_1[0x34] = 0;
  param_1[0x37] = 0;
  local_4._0_1_ = 3;
  FUN_005e6750();
  local_4._0_1_ = 4;
  FUN_005e6750();
  local_4._0_1_ = 5;
  FUN_005e6750();
  local_4._0_1_ = 6;
  FUN_005e6750();
  local_4 = CONCAT31(local_4._1_3_,7);
  *param_1 = &PTR_FUN_00639fe0;
  param_1[0x7e] = 0;
  param_1[0x3b] = 0;
  param_1[0x3a] = 0;
  *(undefined1 *)(param_1 + 1) = 0;
  FUN_005e7df0();
  ExceptionList = local_c;
  return param_1;
}


