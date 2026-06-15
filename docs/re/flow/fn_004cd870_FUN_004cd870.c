// FUN_004cd870  entry=004cd870  size=233 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_004cd870(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00614556;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005c52b0();
  local_4 = 0;
  FUN_005bc430();
  local_4._0_1_ = 1;
  FUN_005c9210();
  param_1[0x10f] = &PTR_LAB_00627fb8;
  local_4._0_1_ = 2;
  FUN_005bc430();
  param_1[0x31c] = 1;
  param_1[0x31d] = 1;
  param_1[0x21f] = &PTR_LAB_00627d78;
  local_4._0_1_ = 3;
  FUN_005bc430();
  param_1[0x321] = &PTR_LAB_00624d08;
  local_4._0_1_ = 4;
  FUN_005bc430();
  param_1[0x427] = &PTR_LAB_00624d08;
  local_4._0_1_ = 5;
  FUN_005c7e20();
  local_4 = CONCAT31(local_4._1_3_,6);
  FUN_005c7e20();
  *param_1 = &PTR_LAB_0062bee0;
  ExceptionList = local_c;
  return param_1;
}


