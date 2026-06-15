// FUN_004709e0  entry=004709e0  size=392 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_004709e0(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_0060b6e6;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = &PTR_FUN_00627fa8;
  local_4 = 0;
  FUN_005bc430();
  local_4._0_1_ = 1;
  FUN_005bc430();
  param_1[0x102] = &PTR_LAB_00624d08;
  local_4._0_1_ = 2;
  FUN_005bc430();
  local_4._0_1_ = 3;
  FUN_005bc430();
  local_4._0_1_ = 4;
  FUN_005bc430();
  local_4._0_1_ = 5;
  FUN_005bc430();
  local_4._0_1_ = 6;
  FUN_005bc430();
  local_4._0_1_ = 7;
  FUN_0043e8c0();
  param_1[0x6fa] = &PTR_LAB_00624d08;
  local_4._0_1_ = 8;
  FUN_0043e8c0();
  param_1[0x800] = &PTR_LAB_00624d08;
  local_4._0_1_ = 9;
  FUN_0043e8c0();
  param_1[0x906] = &PTR_LAB_00624d08;
  local_4._0_1_ = 10;
  FUN_00435550();
  local_4._0_1_ = 0xb;
  FUN_005bc430();
  local_4._0_1_ = 0xc;
  FUN_005c9210();
  local_4._0_1_ = 0xd;
  FUN_005bc430();
  param_1[0xc22] = &PTR_LAB_00624d08;
  local_4 = CONCAT31(local_4._1_3_,0xe);
  FUN_005bc430();
  param_1[0xe25] = 1;
  param_1[0xe26] = 0;
  param_1[0xe27] = 0;
  param_1[0xd28] = &PTR_LAB_00628540;
  *param_1 = &PTR_FUN_00628530;
  param_1[3] = 0;
  *(undefined2 *)((int)param_1 + 0x12) = 0;
  ExceptionList = local_c;
  return param_1;
}


