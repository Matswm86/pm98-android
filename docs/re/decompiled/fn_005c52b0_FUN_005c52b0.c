// FUN_005c52b0  entry=005c52b0  size=166 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_005c52b0(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_00621246;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005bc430();
  param_1[0x100] = 0x70000000;
  param_1[0xff] = 0x70000000;
  param_1[0x102] = 0x90000000;
  param_1[0x101] = 0x90000000;
  param_1[0x106] = 0x90000000;
  param_1[0x105] = 0x90000000;
  param_1[0x104] = 0x70000000;
  param_1[0x103] = 0x70000000;
  param_1[0x107] = 0;
  *(undefined2 *)(param_1 + 0x108) = 0;
  param_1[0x109] = 0;
  param_1[0x10a] = 0;
  param_1[0xfd] = 0;
  param_1[0xfe] = 0;
  param_1[0x10b] = 0;
  *param_1 = &PTR_LAB_00639888;
  param_1[0x2d] = 1;
  ExceptionList = local_c;
  return param_1;
}


