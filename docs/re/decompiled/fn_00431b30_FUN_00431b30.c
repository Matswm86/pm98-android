// FUN_00431b30  entry=00431b30  size=81 bytes

undefined4 * __thiscall FUN_00431b30(undefined4 *param_1,undefined4 param_2)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_00607518;
  local_c = ExceptionList;
  local_4 = 0;
  ExceptionList = &local_c;
  *(undefined1 *)((int)param_1 + 0x12) = 0;
  *(undefined1 *)((int)param_1 + 0x13) = 0;
  *(undefined2 *)(param_1 + 4) = 0;
  *param_1 = &PTR_LAB_00623f70;
  FUN_004319d0(param_2);
  ExceptionList = local_c;
  return param_1;
}


