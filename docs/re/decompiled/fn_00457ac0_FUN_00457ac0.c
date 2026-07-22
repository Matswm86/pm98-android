// FUN_00457ac0  entry=00457ac0  size=131 bytes

undefined4 * __thiscall FUN_00457ac0(undefined4 *param_1,undefined4 param_2)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_0060a1c4;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  param_1[6] = 0;
  param_1[7] = 0;
  param_1[8] = 0;
  param_1[9] = 0;
  param_1[10] = 0;
  param_1[0xb] = 0;
  param_1[0xd] = 0;
  param_1[0xe] = 0;
  param_1[0xf] = 0;
  param_1[0x10] = 0;
  param_1[0x11] = 0;
  param_1[0x12] = 0;
  *(undefined1 *)((int)param_1 + 0x92) = 0;
  *(undefined1 *)((int)param_1 + 0x93) = 0;
  *(undefined2 *)(param_1 + 0x24) = 0;
  local_4 = 8;
  *param_1 = &PTR_FUN_00627438;
  FUN_004576c0(param_2);
  ExceptionList = local_c;
  return param_1;
}


