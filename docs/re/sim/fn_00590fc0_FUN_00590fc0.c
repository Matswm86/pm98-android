// FUN_00590fc0  entry=00590fc0  size=177 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_00590fc0(int *param_1,undefined4 param_2)

{
  void *pvVar1;
  int iVar2;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0062042d;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_00591080();
  pvVar1 = operator_new(0x5fb8);
  local_4 = 0;
  if (pvVar1 == (void *)0x0) {
    iVar2 = 0;
  }
  else {
    iVar2 = FUN_00591180();
  }
  local_4 = 0xffffffff;
  if (iVar2 == 0) {
    local_210 = 0xffff0002;
    lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  *param_1 = iVar2;
  FUN_005923f0(param_2);
  ExceptionList = local_c;
  return;
}


