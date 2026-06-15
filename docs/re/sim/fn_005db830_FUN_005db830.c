// FUN_005db830  entry=005db830  size=376 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_005db830(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0062166e;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005bc430();
  *param_1 = &PTR_LAB_00625c90;
  local_4 = 0;
  FUN_005c7e20();
  param_1[0x10c] = &PTR_LAB_00639c08;
  local_4._0_1_ = 1;
  FUN_005c7e20();
  param_1[0x213] = &PTR_LAB_00639c08;
  local_4._0_1_ = 2;
  FUN_005c7e20();
  param_1[0x31a] = &PTR_LAB_00639c08;
  local_4._0_1_ = 3;
  FUN_005c7e20();
  param_1[0x421] = &PTR_LAB_00639c08;
  local_4._0_1_ = 4;
  FUN_005c7e20();
  param_1[0x528] = &PTR_LAB_00639c08;
  param_1[0x630] = 0x70000000;
  param_1[0x62f] = 0x70000000;
  param_1[0x632] = 0x90000000;
  param_1[0x631] = 0x90000000;
  param_1[0x634] = 0x70000000;
  param_1[0x633] = 0x70000000;
  param_1[0x636] = 0x90000000;
  param_1[0x635] = 0x90000000;
  param_1[0x638] = 0x70000000;
  param_1[0x637] = 0x70000000;
  param_1[0x63a] = 0x90000000;
  param_1[0x639] = 0x90000000;
  param_1[0x63c] = 0x70000000;
  param_1[0x63b] = 0x70000000;
  param_1[0x63e] = 0x90000000;
  param_1[0x63d] = 0x90000000;
  param_1[0x640] = 0x70000000;
  param_1[0x63f] = 0x70000000;
  param_1[0x642] = 0x90000000;
  param_1[0x641] = 0x90000000;
  param_1[0x644] = 0x70000000;
  param_1[0x643] = 0x70000000;
  param_1[0x646] = 0x90000000;
  param_1[0x645] = 0x90000000;
  local_4 = CONCAT31(local_4._1_3_,5);
  *param_1 = &PTR_LAB_00639af0;
  param_1[0x10a] = 0;
  FUN_005dbe70(0x100,0x20,1,0x20);
  ExceptionList = local_c;
  return param_1;
}


