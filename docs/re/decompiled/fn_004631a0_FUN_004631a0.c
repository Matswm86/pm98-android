// FUN_004631a0  entry=004631a0  size=91 bytes

undefined4 * __thiscall FUN_004631a0(undefined4 *param_1,undefined4 param_2)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_0060a8a8;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *(undefined1 *)((int)param_1 + 0x12) = 0;
  *(undefined1 *)((int)param_1 + 0x13) = 0;
  *(undefined2 *)(param_1 + 4) = 0;
  local_4 = 0;
  *(undefined1 *)((int)param_1 + 0x16) = 0;
  *(undefined1 *)((int)param_1 + 0x17) = 0;
  *(undefined2 *)(param_1 + 5) = 0;
  *param_1 = &PTR_FUN_00627698;
  FUN_00462f80(param_2);
  ExceptionList = local_c;
  return param_1;
}


