// FUN_004cd630  entry=004cd630  size=220 bytes
// callers/callees expanded one level from seeds

int __fastcall FUN_004cd630(int param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0061445d;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005bc430();
  local_4 = 0;
  FUN_005bc430();
  local_4._0_1_ = 1;
  FUN_005bc430();
  local_4._0_1_ = 2;
  FUN_005bc430();
  local_4._0_1_ = 3;
  FUN_005bc430();
  local_4._0_1_ = 4;
  FUN_005bc430();
  *(undefined ***)(param_1 + 0x13c8) = &PTR_LAB_00624d08;
  local_4._0_1_ = 5;
  FUN_005bc430();
  *(undefined ***)(param_1 + 0x17e0) = &PTR_LAB_00624d08;
  local_4._0_1_ = 6;
  FUN_005bc430();
  *(undefined ***)(param_1 + 0x1bf8) = &PTR_LAB_00624d08;
  local_4 = CONCAT31(local_4._1_3_,7);
  FUN_005bc430();
  *(undefined ***)(param_1 + 0x2010) = &PTR_LAB_00624d08;
  ExceptionList = local_c;
  return param_1;
}


