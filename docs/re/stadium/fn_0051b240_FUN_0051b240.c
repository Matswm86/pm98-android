// FUN_0051b240  entry=0051b240  size=314 bytes

void __fastcall FUN_0051b240(int param_1)

{
  undefined4 *puVar1;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00618a4d;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  puVar1 = operator_new(0x5bc);
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
    FUN_005c9210();
    local_4 = CONCAT31(local_4._1_3_,6);
    FUN_005c9210();
    *puVar1 = &PTR_LAB_00630710;
  }
  local_4 = 0xffffffff;
  if (puVar1 == (undefined4 *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  *(undefined4 **)(param_1 + 0x1990) = puVar1;
  FUN_0051bc70(param_1,*(undefined4 *)(param_1 + 0x480));
  FUN_005c5d30(*(undefined4 *)(param_1 + 0x1990),1);
  ExceptionList = local_c;
  return;
}


