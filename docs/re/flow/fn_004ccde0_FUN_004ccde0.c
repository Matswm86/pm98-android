// FUN_004ccde0  entry=004ccde0  size=201 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_004ccde0(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00613f4a;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005bc430();
  local_4 = 0;
  FUN_005bc430();
  local_4._0_1_ = 1;
  FUN_005bc430();
  param_1[0x1fa] = &PTR_LAB_00624d08;
  local_4._0_1_ = 2;
  FUN_005bc430();
  param_1[0x300] = &PTR_LAB_0062bcb0;
  local_4._0_1_ = 3;
  param_1[0x3fe] = 0;
  param_1[0x3ff] = 0;
  param_1[0x400] = 0;
  param_1[0x411] = 1;
  FUN_005bc430();
  local_4 = CONCAT31(local_4._1_3_,4);
  FUN_005c9210();
  param_1[0x412] = &PTR_LAB_00627fb8;
  *param_1 = &PTR_LAB_0062bb98;
  ExceptionList = local_c;
  return param_1;
}


