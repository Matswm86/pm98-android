// FUN_0051a3e0  entry=0051a3e0  size=458 bytes

undefined4 * FUN_0051a3e0(void)

{
  undefined4 *puVar1;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00618778;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  puVar1 = operator_new(0x3a94);
  local_4 = 0;
  if (puVar1 == (undefined4 *)0x0) {
    puVar1 = (undefined4 *)0x0;
  }
  else {
    FUN_005c52b0();
    local_4._0_1_ = 1;
    FUN_005c9210();
    local_4._0_1_ = 2;
    FUN_00435550();
    local_4._0_1_ = 3;
    FUN_00435d40();
    *puVar1 = &PTR_LAB_006241e0;
    local_4._0_1_ = 4;
    FUN_005c9210();
    local_4._0_1_ = 5;
    FUN_005bc430();
    puVar1[0x665] = &PTR_LAB_00625fe8;
    local_4._0_1_ = 6;
    FUN_005bc430();
    puVar1[0x762] = &PTR_LAB_00625288;
    local_4._0_1_ = 7;
    FUN_005bc430();
    *(undefined1 *)(puVar1 + 0x95c) = 0;
    local_4._0_1_ = 8;
    *(undefined1 *)(puVar1 + 0x96c) = 0;
    FUN_005c9210();
    puVar1[0x85f] = &PTR_LAB_00625170;
    local_4._0_1_ = 9;
    FUN_0043fc70();
    local_4._0_1_ = 10;
    FUN_004360a0();
    local_4._0_1_ = 0xb;
    FUN_004360a0();
    local_4._0_1_ = 0xc;
    FUN_004360a0();
    local_4 = CONCAT31(local_4._1_3_,0xd);
    FUN_0051a5d0();
    *puVar1 = &PTR_LAB_006303c0;
  }
  local_4 = 0xffffffff;
  if (puVar1 == (undefined4 *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  ExceptionList = local_c;
  return puVar1;
}


