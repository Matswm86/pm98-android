// FUN_005c7e20  entry=005c7e20  size=112 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_005c7e20(undefined4 *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00621348;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005bc430();
  local_4 = 0;
  *param_1 = &PTR_LAB_006399a0;
  param_1[0x2d] = 3;
  lstrcpyA((LPSTR)(param_1 + 0x97),s_curbot1_0065d9f0);
  lstrcpyA((LPSTR)(param_1 + 0xb7),s_curbot2_0065d9e8);
  ExceptionList = local_c;
  return param_1;
}


