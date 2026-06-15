// FUN_00590c90  entry=00590c90  size=523 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_00590c90(uint *param_1)

{
  int iVar1;
  undefined4 *puVar2;
  void *pvVar3;
  uint uVar4;
  undefined4 *puVar5;
  LPCSTR pCVar6;
  CHAR local_410;
  undefined4 local_40f;
  CHAR local_310;
  undefined4 local_30f;
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0062040e;
  local_c = ExceptionList;
  if (*param_1 < 0x100) {
    iVar1 = *param_1 * 0x14;
    param_1[4] = *(uint *)(&DAT_00663c50 + iVar1);
    *(undefined *)(param_1 + 2) = (&DAT_00663c48)[iVar1];
  }
  else if ((char)param_1[2] == '\0') {
    ExceptionList = &local_c;
    pvVar3 = operator_new(4);
    local_4 = 0;
    if (pvVar3 == (void *)0x0) {
      uVar4 = 0;
    }
    else {
      uVar4 = FUN_005e09e0();
    }
    local_4 = 0xffffffff;
    if (uVar4 == 0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    param_1[4] = uVar4;
    pCVar6 = (LPCSTR)*param_1;
    lstrcpyA(&local_410,s_sfx_ambiente__00664b84);
    iVar1 = lstrlenA(&local_410);
    lstrcpyA(&local_410 + iVar1,pCVar6);
    lstrcpyA(&local_310,&local_410);
    puVar2 = &local_40f;
    puVar5 = &local_30f;
    for (iVar1 = 0x3f; iVar1 != 0; iVar1 = iVar1 + -1) {
      *puVar5 = *puVar2;
      puVar2 = puVar2 + 1;
      puVar5 = puVar5 + 1;
    }
    *(undefined2 *)puVar5 = *(undefined2 *)puVar2;
    *(undefined1 *)((int)puVar5 + 2) = *(undefined1 *)((int)puVar2 + 2);
    FUN_005e0ab0(&local_310,11000,8,0);
    if (DAT_00674e78 == 1) {
      FUN_005e0bf0(0x4b);
    }
  }
  else {
    ExceptionList = &local_c;
    puVar2 = operator_new(0x1c);
    if (puVar2 == (undefined4 *)0x0) {
      puVar2 = (undefined4 *)0x0;
    }
    else {
      *puVar2 = 0;
      puVar2[1] = 0;
      puVar2[2] = 0;
      puVar2[3] = 0;
      puVar2[5] = 0;
    }
    if (puVar2 == (undefined4 *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0063ac98);
    }
    param_1[4] = (uint)puVar2;
    pCVar6 = (LPCSTR)*param_1;
    lstrcpyA(&local_410,s_sfx_ambiente__00664b84);
    iVar1 = lstrlenA(&local_410);
    lstrcpyA(&local_410 + iVar1,pCVar6);
    FUN_0051fd00(&local_410);
    FUN_005e0560(&local_310,11000,8,0);
    if (DAT_00674e78 == 1) {
      FUN_005e0970(0x4b);
    }
  }
  ExceptionList = local_c;
  return;
}


