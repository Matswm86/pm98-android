// FUN_0051b440  entry=0051b440  size=438 bytes

void __fastcall FUN_0051b440(int param_1)

{
  int *piVar1;
  undefined4 local_210;
  CHAR local_20c [504];
  void *pvStack_14;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00618b82;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  piVar1 = operator_new(0x21cc);
  local_4 = 0;
  if (piVar1 == (int *)0x0) {
    piVar1 = (int *)0x0;
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
    FUN_005c7e20();
    local_4._0_1_ = 6;
    FUN_005c7e20();
    local_4._0_1_ = 7;
    FUN_005c7e20();
    local_4._0_1_ = 8;
    FUN_005c7e20();
    local_4._0_1_ = 9;
    FUN_0043e8c0();
    piVar1[0x561] = (int)&PTR_LAB_00624d08;
    local_4._0_1_ = 10;
    FUN_0043e8c0();
    piVar1[0x667] = (int)&PTR_LAB_00624d08;
    local_4 = CONCAT31(local_4._1_3_,0xb);
    FUN_005c7e20();
    piVar1[0x76d] = (int)&PTR_LAB_006287c8;
    *piVar1 = (int)&PTR_LAB_00630828;
  }
  local_4 = 0xffffffff;
  if (piVar1 == (int *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  *(int **)(param_1 + 0x1988) = piVar1;
  (**(code **)(*piVar1 + 0x114))(param_1,*(undefined4 *)(param_1 + 0x480));
  FUN_005c5d30(*(undefined4 *)(param_1 + 0x1988),1);
  ExceptionList = pvStack_14;
  return;
}


