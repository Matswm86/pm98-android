// FUN_00545000  entry=00545000  size=257 bytes

undefined4 * FUN_00545000(void)

{
  undefined4 *puVar1;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0061b545;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  puVar1 = operator_new(0x1d40);
  local_4 = 0;
  if (puVar1 == (undefined4 *)0x0) {
    puVar1 = (undefined4 *)0x0;
  }
  else {
    FUN_005c52b0();
    local_4._0_1_ = 1;
    FUN_005c9210();
    local_4._0_1_ = 2;
    FUN_0043e8c0();
    puVar1[0x121] = &PTR_LAB_00624d08;
    local_4._0_1_ = 3;
    FUN_00435d40();
    *puVar1 = &PTR_LAB_006241e0;
    local_4 = CONCAT31(local_4._1_3_,4);
    FUN_005bc430();
    puVar1[0x64a] = &PTR_LAB_00624d08;
    *puVar1 = &PTR_LAB_00633670;
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


