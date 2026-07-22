// FUN_0045dfb0  entry=0045dfb0  size=100 bytes

undefined4 * __thiscall FUN_0045dfb0(undefined4 *param_1,undefined4 param_2)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_0060a5e1;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  param_1[5] = 0;
  param_1[6] = 0;
  param_1[8] = 0;
  param_1[9] = 0;
  param_1[10] = 0;
  param_1[0xb] = 0;
  param_1[0xc] = 0;
  param_1[0xd] = 0;
  local_4 = 6;
  *param_1 = &PTR_FUN_00627568;
  FUN_0045db30(param_2);
  ExceptionList = local_c;
  return param_1;
}


