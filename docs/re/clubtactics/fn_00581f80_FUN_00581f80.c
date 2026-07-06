// FUN_00581f80  entry=00581f80  size=358 bytes

undefined4 __thiscall FUN_00581f80(int param_1,undefined4 param_2)

{
  ushort uVar1;
  undefined2 uVar2;
  undefined4 uVar3;
  int iVar4;
  void *pvVar5;
  undefined2 *puVar6;
  uint local_330;
  undefined2 *local_32c;
  int local_328;
  int local_324;
  undefined1 local_314;
  undefined3 uStack_313;
  undefined4 local_310;
  CHAR local_30c [512];
  undefined1 local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_006200ab;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_0058c790();
  local_4 = 0;
  uVar3 = FUN_00584d60(param_2,local_10c);
  iVar4 = FUN_0058c900(uVar3,0x10);
  if (iVar4 == 0) {
    uVar3 = 0;
  }
  else {
    uVar1 = local_32c[0x12];
    local_32c = local_32c + 0x13;
    local_330 = 0;
    if (*(void **)(param_1 + 0x10) != (void *)0x0) {
      operator_delete(*(void **)(param_1 + 0x10));
    }
    pvVar5 = operator_new((uint)uVar1);
    if (pvVar5 == (void *)0x0) {
      local_310 = 0xffff0002;
      lstrcpyA(local_30c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_310,(ThrowInfo *)&DAT_0063ac98);
    }
    *(void **)(param_1 + 0x10) = pvVar5;
    uVar2 = *local_32c;
    puVar6 = local_32c + 1;
    local_32c = (undefined2 *)((int)local_32c + 3);
    _local_314 = CONCAT31(uStack_313,*(undefined1 *)puVar6);
    uVar3 = FUN_005820f0(pvVar5,&local_330,&local_32c,uVar2,*(undefined1 *)puVar6);
    if (((local_328 == 0) || ((undefined2 *)(local_324 + local_328) < local_32c)) ||
       (uVar1 < local_330)) {
      uVar3 = 0;
    }
    FUN_0058c7b0();
  }
  local_4 = 0xffffffff;
  FUN_0058c7b0();
  ExceptionList = local_c;
  return uVar3;
}


