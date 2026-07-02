// FUN_004fda70  entry=004fda70  size=125 bytes

undefined4 * __fastcall FUN_004fda70(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00616bf2;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005bc430();
  local_4 = 0;
  FUN_005c9210();
  local_4._0_1_ = 1;
  FUN_005c9210();
  local_4._0_1_ = 2;
  FUN_005c9210();
  local_4 = CONCAT31(local_4._1_3_,3);
  FUN_005c9210();
  *param_1 = &PTR_LAB_0062d6d8;
  ExceptionList = local_c;
  return param_1;
}


