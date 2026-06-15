// FUN_004ccbe0  entry=004ccbe0  size=255 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_004ccbe0(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00613e82;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005c52b0();
  local_4 = 0;
  param_1[0x10c] = 1;
  FUN_005bc430();
  local_4._0_1_ = 1;
  FUN_005c9210();
  param_1[0x10f] = &PTR_LAB_00627fb8;
  local_4._0_1_ = 2;
  FUN_005bc430();
  param_1[0x21f] = &PTR_LAB_00624d08;
  local_4._0_1_ = 3;
  FUN_005bc430();
  param_1[0x325] = &PTR_LAB_00624d08;
  local_4._0_1_ = 4;
  FUN_005bc430();
  param_1[0x42b] = &PTR_LAB_00624d08;
  local_4._0_1_ = 5;
  FUN_005c7e20();
  local_4._0_1_ = 6;
  FUN_005c7e20();
  local_4._0_1_ = 7;
  FUN_005c7e20();
  local_4 = CONCAT31(local_4._1_3_,8);
  FUN_005c7e20();
  *param_1 = &PTR_LAB_0062ba80;
  ExceptionList = local_c;
  return param_1;
}


