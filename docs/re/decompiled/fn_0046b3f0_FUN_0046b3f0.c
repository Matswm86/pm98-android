// FUN_0046b3f0  entry=0046b3f0  size=77 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_0046b3f0(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0060ae58;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005bc430();
  local_4 = 0;
  FUN_005c9210();
  *param_1 = &PTR_LAB_00627fb8;
  ExceptionList = local_c;
  return param_1;
}


