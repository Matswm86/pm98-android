// FUN_005f2ad0  entry=005f2ad0  size=126 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_005f2ad0(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_00622330;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = 0;
  param_1[1] = 0;
  param_1[2] = 0;
  param_1[3] = 0;
  *(undefined2 *)(param_1 + 0x14) = 0;
  param_1[0x10] = 0;
  *(undefined2 *)((int)param_1 + 0x4e) = 0;
  *(undefined2 *)(param_1 + 0x13) = 0;
  param_1[0x11] = 0;
  local_4 = 1;
  param_1[0x12] = 0;
  param_1[0x17] = 0x10000;
  param_1[0x16] = 0x10000;
  param_1[0x15] = 0x10000;
  *(undefined1 *)(param_1 + 0x18) = 1;
  FUN_005eea50(0x10000,0x10000,0x10000);
  ExceptionList = local_c;
  return param_1;
}


