// FUN_0051af20  entry=0051af20  size=476 bytes

void __fastcall FUN_0051af20(int param_1)

{
  undefined4 *puVar1;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00618907;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  puVar1 = operator_new(0x2060);
  local_4 = 0;
  if (puVar1 == (undefined4 *)0x0) {
    puVar1 = (undefined4 *)0x0;
  }
  else {
    FUN_005bc430();
    local_4._0_1_ = 1;
    FUN_005c9210();
    local_4._0_1_ = 2;
    FUN_005c9210();
    local_4._0_1_ = 3;
    FUN_005c9210();
    local_4._0_1_ = 4;
    FUN_005c9210();
    local_4._0_1_ = 5;
    FUN_00605ee0(puVar1 + 0x149,0x4c,5,FUN_005c9210,thunk_FUN_005cb040);
    local_4._0_1_ = 6;
    FUN_00605ee0(puVar1 + 0x1a8,0x4c,4,FUN_005c9210,thunk_FUN_005cb040);
    local_4._0_1_ = 7;
    FUN_005c7e20();
    local_4._0_1_ = 8;
    FUN_005c7e20();
    local_4._0_1_ = 9;
    FUN_005c7e20();
    local_4._0_1_ = 10;
    FUN_005c7e20();
    local_4._0_1_ = 0xb;
    FUN_005bc430();
    puVar1[0x60c] = &PTR_LAB_00624d08;
    local_4 = CONCAT31(local_4._1_3_,0xc);
    FUN_0043e8c0();
    puVar1[0x712] = &PTR_LAB_00624d08;
    *puVar1 = &PTR_LAB_006305f8;
  }
  local_4 = 0xffffffff;
  if (puVar1 == (undefined4 *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  *(undefined4 **)(param_1 + 0x198c) = puVar1;
  FUN_0051bd80(param_1,*(undefined4 *)(param_1 + 0x480));
  FUN_005c5d30(*(undefined4 *)(param_1 + 0x198c),1);
  ExceptionList = local_c;
  return;
}


