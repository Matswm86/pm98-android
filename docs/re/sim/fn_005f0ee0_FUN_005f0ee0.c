// FUN_005f0ee0  entry=005f0ee0  size=139 bytes
// callers/callees expanded one level from seeds

void FUN_005f0ee0(undefined4 param_1)

{
  undefined1 local_120 [264];
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_006222ab;
  local_c = ExceptionList;
  local_120[0] = 0;
  local_18 = 0;
  local_14 = 0;
  local_10 = 0;
  ExceptionList = &local_c;
  FUN_005ec020(param_1);
  local_4 = 0;
  FUN_005f0f70(local_120);
  local_4 = 0xffffffff;
  FUN_005ec0e0();
  ExceptionList = local_c;
  return;
}


