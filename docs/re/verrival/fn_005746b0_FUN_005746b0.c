// FUN_005746b0  entry=005746b0  size=370 bytes

void __thiscall FUN_005746b0(int param_1,int param_2)

{
  int *piVar1;
  int iVar2;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0061fd0d;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  piVar1 = operator_new(0x1a80);
  local_4 = 0;
  if (piVar1 == (int *)0x0) {
    piVar1 = (int *)0x0;
  }
  else {
    FUN_005c52b0();
    local_4._0_1_ = 1;
    FUN_005c9210();
    local_4._0_1_ = 2;
    FUN_00435550();
    local_4._0_1_ = 3;
    FUN_00435590();
    local_4._0_1_ = 4;
    FUN_00435550();
    local_4._0_1_ = 5;
    FUN_004fda70();
    local_4 = CONCAT31(local_4._1_3_,6);
    FUN_004fdb70();
    piVar1[0x10c] = 0;
    piVar1[0x10d] = 0;
    piVar1[0x10e] = 0;
    *piVar1 = (int)&PTR_LAB_006380e8;
  }
  local_4 = 0xffffffff;
  if (piVar1 == (int *)0x0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  iVar2 = FUN_005266c0(param_1,*(undefined4 *)
                                (param_1 + -0x634ec + *(int *)(param_2 + 0xa8) * 0x41c),
                       *(undefined4 *)(param_1 + 0x1928));
  if (iVar2 != 0) {
    FUN_005bce40(0);
  }
  if (piVar1 != (int *)0x0) {
    (**(code **)(*piVar1 + 4))(1);
  }
  ExceptionList = local_c;
  return;
}


