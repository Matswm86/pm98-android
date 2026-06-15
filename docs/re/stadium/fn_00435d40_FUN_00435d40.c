// FUN_00435d40  entry=00435d40  size=109 bytes

undefined4 * __fastcall FUN_00435d40(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00607fc4;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005c52b0();
  local_4 = 0;
  FUN_005c7e20();
  local_4._0_1_ = 1;
  FUN_005c7e20();
  local_4 = CONCAT31(local_4._1_3_,2);
  FUN_005c7e20();
  *param_1 = &PTR_LAB_00624f40;
  ExceptionList = local_c;
  return param_1;
}


