// FUN_00493100  entry=00493100  size=1167 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_00493100(int param_1,int param_2,undefined4 *param_3)

{
  undefined4 *puVar1;
  int local_310;
  int local_30c;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_0060f0f4;
  local_c = ExceptionList;
  param_2 = param_2 - (int)param_3;
  puVar1 = (undefined4 *)(param_1 + 0x35d8);
  local_310 = 8;
  ExceptionList = &local_c;
  do {
    puVar1[-8] = *(undefined4 *)(param_2 + (int)param_3);
    *puVar1 = *param_3;
    param_3 = param_3 + 1;
    puVar1 = puVar1 + 1;
    local_310 = local_310 + -1;
  } while (local_310 != 0);
  local_30c = 8;
  do {
    local_4 = 1;
    FUN_00405ce0();
    local_4 = CONCAT31(local_4._1_3_,2);
    FUN_00405ce0();
    local_4 = 3;
    FUN_004144c0();
    local_4._0_1_ = 4;
    FUN_00405ce0();
    local_4._0_1_ = 5;
    FUN_00405ce0();
    local_4._0_1_ = 6;
    FUN_00448530();
    FUN_00448530();
    if (&stack0x00000000 == (undefined1 *)0x240) {
      FUN_00401cd0();
      local_4._0_1_ = 7;
      FUN_00448530();
      local_4._0_1_ = 6;
      FUN_0040a690();
    }
    else {
      FUN_00448530();
    }
    if (&stack0x00000000 == (undefined1 *)0x2fc) {
      FUN_00401cd0();
      local_4._0_1_ = 8;
      FUN_00448530();
      local_4._0_1_ = 6;
      FUN_0040a690();
    }
    else {
      FUN_00448530();
    }
    FUN_00493590(0);
    FUN_005bec80();
    local_4._0_1_ = 0xb;
    operator_delete((void *)0x0);
    local_4._0_1_ = 10;
    FUN_00591880();
    local_4._0_1_ = 9;
    FUN_00591880();
    local_4 = CONCAT31(local_4._1_3_,3);
    FUN_00591880();
    local_4 = 0xffffffff;
    FUN_0040a690();
    local_30c = local_30c + -1;
  } while (local_30c != 0);
  ExceptionList = local_c;
  return;
}


