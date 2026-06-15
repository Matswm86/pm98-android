// FUN_005d7240  entry=005d7240  size=312 bytes
// callers/callees expanded one level from seeds

int __fastcall FUN_005d7240(int param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00621594;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005c9210();
  *(undefined4 *)(param_1 + 0x10c) = 0x70000000;
  *(undefined4 *)(param_1 + 0x108) = 0x70000000;
  *(undefined4 *)(param_1 + 0x114) = 0x90000000;
  *(undefined4 *)(param_1 + 0x110) = 0x90000000;
  *(undefined1 *)(param_1 + 0x120) = 0;
  *(undefined4 *)(param_1 + 0x150) = 0;
  *(undefined4 *)(param_1 + 0x154) = 0;
  *(undefined4 *)(param_1 + 0x18c) = 0;
  *(undefined4 *)(param_1 + 400) = 0;
  local_4 = 4;
  *(undefined4 *)(param_1 + 0x140) = 0;
  *(undefined4 *)(param_1 + 0x144) = 0;
  *(undefined1 *)(param_1 + 0x148) = 0;
  *(undefined1 *)(param_1 + 0x149) = 0;
  *(undefined1 *)(param_1 + 0x14a) = 0;
  *(undefined1 *)(param_1 + 0x14b) = 0;
  *(undefined1 *)(param_1 + 0x14c) = 0;
  *(undefined4 *)(param_1 + 0x100) = 0x10000;
  *(undefined4 *)(param_1 + 0x104) = 0x1900000;
  *(undefined4 *)(param_1 + 0x168) = 0;
  *(undefined4 *)(param_1 + 0x16c) = 0;
  *(undefined4 *)(param_1 + 0x170) = 0;
  *(undefined4 *)(param_1 + 0x174) = 0;
  *(undefined4 *)(param_1 + 0x178) = 0;
  *(undefined4 *)(param_1 + 0x17c) = 0;
  *(undefined4 *)(param_1 + 0x158) = 0;
  *(undefined4 *)(param_1 + 0x15c) = 0;
  *(undefined4 *)(param_1 + 0x160) = 0;
  *(undefined1 *)(param_1 + 0x180) = 0;
  *(undefined1 *)(param_1 + 0x181) = 1;
  *(undefined1 *)(param_1 + 0x182) = 0;
  *(undefined1 *)(param_1 + 0x183) = 0;
  *(undefined1 *)(param_1 + 0x184) = 0;
  *(undefined1 *)(param_1 + 0x185) = 0;
  *(undefined1 *)(param_1 + 0x188) = 0;
  FUN_005ee9f0();
  *(undefined1 *)(param_1 + 0x186) = 1;
  *(undefined1 *)(param_1 + 0x187) = 0;
  ExceptionList = local_c;
  return param_1;
}


