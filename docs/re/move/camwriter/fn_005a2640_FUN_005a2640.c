// FUN_005a2640  entry=005a2640  size=482 bytes

undefined4 * __thiscall FUN_005a2640(undefined4 *param_1,int param_2)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00620cbe;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *(undefined1 *)(param_1 + 7) = 0;
  *param_1 = &PTR_FUN_00639224;
  FUN_00590aa0(0,0,0);
  param_1[0xb] = 0;
  param_1[0xc] = 0;
  *(undefined2 *)(param_1 + 0xd) = 0;
  FUN_005b1190(0);
  *param_1 = &PTR_FUN_00639238;
  param_1[0x61] = 0;
  param_1[0x62] = 0;
  param_1[99] = param_2;
  local_4 = 0;
  param_1[100] = param_2 + 0x1610;
  FUN_005c9210();
  param_1[0x86] = 0x70000000;
  param_1[0x85] = 0x70000000;
  param_1[0x84] = 0x70000000;
  param_1[0x89] = 0x90000000;
  param_1[0x88] = 0x90000000;
  param_1[0x87] = 0x90000000;
  param_1[0x8b] = 0x70000000;
  param_1[0x8a] = 0x70000000;
  param_1[0x8d] = 0x90000000;
  param_1[0x8c] = 0x90000000;
  *(undefined1 *)(param_1 + 0x8e) = 0;
  param_1[0xec] = 0;
  param_1[0xed] = 0;
  param_1[0xee] = 0;
  *param_1 = &PTR_FUN_00639228;
  param_1[0xb0] = 0;
  param_1[0xb3] = 0;
  param_1[0xb1] = 0;
  *(undefined1 *)((int)param_1 + 0x2da) = 0;
  *(undefined1 *)((int)param_1 + 0x2d9) = 0;
  *(undefined1 *)((int)param_1 + 0x2d5) = 0;
  param_1[0xc] = 0;
  *(undefined1 *)(param_1 + 0xb5) = 0;
  *(undefined1 *)(param_1 + 0x17) = 0;
  *(undefined1 *)((int)param_1 + 0x5d) = 0;
  *(undefined1 *)((int)param_1 + 99) = 0;
  param_1[0xb2] = 0;
  param_1[0xde] = 0;
  param_1[0xdf] = 0;
  param_1[0xe0] = 0;
  param_1[0xe1] = 0;
  param_1[0xe2] = 0;
  param_1[0xe3] = 0;
  param_1[0xe4] = 0;
  param_1[0xe5] = 0;
  param_1[0xe6] = 0;
  param_1[0xe7] = 0;
  param_1[0xe8] = 0;
  param_1[0xb4] = 0;
  param_1[0x12] = 0;
  param_1[0xea] = 0x999;
  param_1[0xeb] = 0x62f;
  param_1[0x1d] = 0;
  param_1[0x1c] = 0;
  param_1[0x1e] = 0;
  param_1[0x13] = 0;
  param_1[0x14] = 0;
  param_1[0x22] = 0;
  *(undefined1 *)((int)param_1 + 0x2d6) = 0;
  param_1[0x2c] = 0;
  *(undefined1 *)((int)param_1 + 0x61) = 0;
  *(undefined1 *)((int)param_1 + 0x5e) = 0;
  *(undefined1 *)((int)param_1 + 0x5f) = 0;
  param_1[0x23] = 0;
  param_1[0x1a] = 0;
  param_1[0x1b] = 0;
  param_1[8] = 0;
  param_1[9] = 0;
  param_1[10] = 0;
  param_1[0x10] = 0;
  param_1[0x60] = 0;
  param_1[0x5f] = 0;
  ExceptionList = local_c;
  return param_1;
}


