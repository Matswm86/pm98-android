// FUN_004cca50  entry=004cca50  size=348 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_004cca50(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00613dfa;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005c52b0();
  param_1[0x138] = 0;
  param_1[0x139] = 0;
  param_1[0x13a] = 0;
  param_1[0x13b] = 0;
  param_1[0x13c] = 0;
  param_1[0x13d] = 0;
  *(undefined1 *)((int)param_1 + 0x483) = 0xff;
  *(undefined1 *)((int)param_1 + 0x482) = 0xff;
  *(undefined1 *)((int)param_1 + 0x481) = 0xff;
  *(undefined1 *)(param_1 + 0x120) = 0xff;
  param_1[0x113] = 0;
  param_1[0x141] = 0xffffffff;
  param_1[0x140] = 0xffffffff;
  param_1[0x114] = 0;
  param_1[0x11f] = 0;
  *(undefined2 *)(param_1 + 0x124) = 0;
  *(undefined2 *)((int)param_1 + 0x486) = 0;
  *(undefined2 *)(param_1 + 0x121) = 0;
  param_1[0x123] = 0;
  param_1[0x125] = 0;
  *(undefined1 *)((int)param_1 + 0x499) = 0;
  *(undefined1 *)(param_1 + 0x126) = 0;
  param_1[0x129] = 0;
  param_1[0x127] = 0;
  *(undefined1 *)((int)param_1 + 0x4a1) = 0;
  *(undefined1 *)(param_1 + 0x128) = 0;
  param_1[0x12a] = 0;
  param_1[299] = 0;
  *(undefined2 *)(param_1 + 300) = 0;
  *(undefined2 *)(param_1 + 0x13e) = 0;
  param_1[0x11a] = 5;
  param_1[0x11c] = 1;
  param_1[0x11b] = 3;
  param_1[0x11e] = 1;
  param_1[0x11d] = 3;
  *(undefined2 *)((int)param_1 + 0x466) = 0;
  *(undefined2 *)(param_1 + 0x119) = 0;
  local_4 = 6;
  FUN_005db830();
  *param_1 = &PTR_LAB_00627c50;
  param_1[0x111] = 0;
  param_1[0x112] = 0;
  param_1[0x110] = 0;
  ExceptionList = local_c;
  return param_1;
}


