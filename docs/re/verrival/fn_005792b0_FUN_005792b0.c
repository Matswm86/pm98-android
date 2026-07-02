// FUN_005792b0  entry=005792b0  size=221 bytes

undefined4 __thiscall FUN_005792b0(uint *param_1,uint param_2)

{
  void *pvVar1;
  int iVar2;
  undefined4 uVar3;
  uint uVar4;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0061fe2e;
  local_c = ExceptionList;
  uVar3 = 1;
  if (param_2 < *param_1) {
    uVar4 = 0;
    ExceptionList = &local_c;
    if (param_1[4] == 0) {
      ExceptionList = &local_c;
      pvVar1 = operator_new(0x2a4);
      local_4 = 0;
      if (pvVar1 != (void *)0x0) {
        uVar4 = FUN_00579880(param_1[1]);
      }
      local_4 = 0xffffffff;
      if (uVar4 == 0) {
        local_210 = 0xffff0002;
        lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
      }
      param_1[4] = uVar4;
    }
    local_4 = 0xffffffff;
    iVar2 = FUN_00579b80(param_2);
    if (iVar2 == 0) {
      FUN_005792a0();
      uVar3 = 0;
    }
    else {
      FUN_00579460(param_2);
    }
  }
  ExceptionList = local_c;
  return uVar3;
}


