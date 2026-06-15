// FUN_005d40b0  entry=005d40b0  size=231 bytes
// callers/callees expanded one level from seeds

undefined4 __thiscall FUN_005d40b0(int param_1,undefined4 param_2)

{
  int iVar1;
  undefined4 local_40;
  CFile local_3c [24];
  undefined4 *local_24;
  int local_1c;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00621528;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005f7ca0(param_2,1,0xffffffff);
  local_40 = *(undefined4 *)(param_1 + 4);
  local_4 = 0;
  param_2 = 0x5047464c;
  if (local_1c == 0) {
    CFile::Write(local_3c,&param_2,4);
  }
  else {
    *local_24 = 0x5047464c;
    local_24 = local_24 + 1;
  }
  if (local_1c == 0) {
    CFile::Write(local_3c,&local_40,4);
  }
  else {
    *local_24 = local_40;
    local_24 = local_24 + 1;
  }
  for (iVar1 = *(int *)(param_1 + 4); iVar1 != 0; iVar1 = iVar1 + -1) {
    FUN_005cb7b0(local_3c);
  }
  local_4 = 0xffffffff;
  FUN_005f7f90();
  ExceptionList = local_c;
  return 1;
}


