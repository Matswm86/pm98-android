// FUN_00410610  entry=00410610  size=1734 bytes

void __fastcall FUN_00410610(int param_1)

{
  char cVar1;
  int iVar2;
  void *pvVar3;
  int iVar4;
  LPSTR pCVar5;
  int local_ef4;
  int local_ef0;
  LPSTR local_eec;
  LPSTR local_ee8;
  LPSTR local_ee4;
  int local_ee0;
  int local_edc;
  char local_ec8 [256];
  undefined4 local_dc8;
  CHAR local_dc4 [512];
  uint local_bc4 [750];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0047ec83;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  local_ef0 = param_1;
  FUN_00401500(&local_ee0);
  local_4 = 0;
  *(undefined4 *)(param_1 + 0x2d5c) = 0;
  *(undefined4 *)(param_1 + 0x2d64) = 0;
  pvVar3 = (void *)FUN_00445a90(&DAT_00497e10,*(uint *)(param_1 + 0x2d50));
  pvVar3 = (void *)FUN_0043b680(pvVar3);
  local_eec = (LPSTR)FUN_0043c2c0(pvVar3,*(int *)(param_1 + 0x2d4c));
  iVar2 = *(int *)(local_eec + 0x2c);
  if ((iVar2 != 0) && (*(int *)(local_eec + 0x28) != 0)) {
    FUN_0043c330(*(undefined4 *)(param_1 + 0x2d50),local_ec8);
    iVar4 = FUN_004015d0(&local_ee0,local_ec8);
    if (iVar4 == 0) {
      sprintf((char *)local_bc4,s_ND_ND_ND_ND_ND_ND_00492400);
    }
    else {
      local_ee0 = iVar2 + local_edc;
      FUN_00401580(&local_ee0,local_bc4);
    }
    pCVar5 = operator_new(0xa4);
    local_4._0_1_ = 1;
    local_ee4 = pCVar5;
    if (pCVar5 == (LPSTR)0x0) {
      pCVar5 = (LPSTR)0x0;
    }
    else {
      *pCVar5 = '\0';
      pCVar5[0x20] = '\0';
      pCVar5[0x60] = '\0';
      pCVar5[0x80] = '\0';
      pCVar5[0x90] = '\0';
      lstrcpyA(pCVar5,&DAT_00496cd0);
      lstrcpyA(pCVar5 + 0x20,&DAT_00496cd0);
      lstrcpyA(pCVar5 + 0x60,&DAT_00496cd0);
      lstrcpyA(pCVar5 + 0x80,&DAT_00496cd0);
      lstrcpyA(pCVar5 + 0x90,&DAT_00496cd0);
      pCVar5[0xa0] = '\0';
      pCVar5[0xa1] = '\0';
      pCVar5[0xa2] = '\0';
      pCVar5[0xa3] = '\0';
      param_1 = local_ef0;
    }
    local_4._0_1_ = 0;
    if (pCVar5 == (LPSTR)0x0) {
      local_dc8 = 0xffff0002;
      lstrcpyA(local_dc4,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_dc8,(ThrowInfo *)&DAT_0048b400);
    }
    *(LPSTR *)(param_1 + 0x2d5c) = pCVar5;
    *(undefined4 *)(param_1 + 0x2d60) = 0;
    local_ef4 = 0;
    cVar1 = (char)local_bc4[0];
    while (local_4._0_1_ = 0, cVar1 != '\0') {
      local_4._0_1_ = 0;
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,0);
      lstrcpyA(pCVar5,local_ec8);
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,0);
      lstrcpyA(pCVar5 + 0x20,local_ec8);
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,0);
      lstrcpyA(pCVar5 + 0x60,local_ec8);
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,0);
      lstrcpyA(pCVar5 + 0x80,local_ec8);
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,0);
      lstrcpyA(pCVar5 + 0x90,local_ec8);
      cVar1 = *(char *)((int)local_bc4 + local_ef4);
      *(int *)(param_1 + 0x2d60) = *(int *)(param_1 + 0x2d60) + 1;
      if (cVar1 == '\0') break;
      local_ee4 = pCVar5;
      pCVar5 = operator_new(0xa4);
      local_4._0_1_ = 2;
      local_ee8 = pCVar5;
      if (pCVar5 == (LPSTR)0x0) {
        pCVar5 = (LPSTR)0x0;
      }
      else {
        *pCVar5 = '\0';
        pCVar5[0x20] = '\0';
        pCVar5[0x60] = '\0';
        pCVar5[0x80] = '\0';
        pCVar5[0x90] = '\0';
        lstrcpyA(pCVar5,&DAT_00496cd0);
        lstrcpyA(pCVar5 + 0x20,&DAT_00496cd0);
        lstrcpyA(pCVar5 + 0x60,&DAT_00496cd0);
        lstrcpyA(pCVar5 + 0x80,&DAT_00496cd0);
        lstrcpyA(pCVar5 + 0x90,&DAT_00496cd0);
        pCVar5[0xa0] = '\0';
        pCVar5[0xa1] = '\0';
        pCVar5[0xa2] = '\0';
        pCVar5[0xa3] = '\0';
        param_1 = local_ef0;
      }
      local_4._0_1_ = 0;
      if (pCVar5 == (LPSTR)0x0) {
        local_dc8 = 0xffff0002;
        lstrcpyA(local_dc4,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_dc8,(ThrowInfo *)&DAT_0048b400);
      }
      *(LPSTR *)(local_ee4 + 0xa0) = pCVar5;
      cVar1 = *(char *)((int)local_bc4 + local_ef4);
    }
    FUN_0043c330(*(undefined4 *)(param_1 + 0x2d50),local_ec8);
    iVar2 = *(int *)(local_eec + 0x28);
    iVar4 = FUN_004015d0(&local_ee0,local_ec8);
    if (iVar4 == 0) {
      sprintf((char *)local_bc4,s_ND_ND_ND_ND_ND_ND_00492400);
    }
    else {
      local_ee0 = iVar2 + local_edc;
      FUN_00401580(&local_ee0,local_bc4);
    }
    pCVar5 = operator_new(0x194);
    local_4._0_1_ = 3;
    local_ee8 = pCVar5;
    if (pCVar5 == (LPSTR)0x0) {
      pCVar5 = (LPSTR)0x0;
    }
    else {
      *pCVar5 = '\0';
      pCVar5[0x20] = '\0';
      pCVar5[0x60] = '\0';
      pCVar5[0x80] = '\0';
      pCVar5[0x90] = '\0';
      lstrcpyA(pCVar5,&DAT_00496cd0);
      lstrcpyA(pCVar5 + 0x20,&DAT_00496cd0);
      lstrcpyA(pCVar5 + 0x60,&DAT_00496cd0);
      lstrcpyA(pCVar5 + 0x80,&DAT_00496cd0);
      lstrcpyA(pCVar5 + 0x90,&DAT_00496cd0);
      pCVar5[400] = '\0';
      pCVar5[0x191] = '\0';
      pCVar5[0x192] = '\0';
      pCVar5[0x193] = '\0';
      param_1 = local_ef0;
    }
    local_4._0_1_ = 0;
    if (pCVar5 == (LPSTR)0x0) {
      local_dc8 = 0xffff0002;
      lstrcpyA(local_dc4,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_dc8,(ThrowInfo *)&DAT_0048b400);
    }
    *(LPSTR *)(param_1 + 0x2d64) = pCVar5;
    *(undefined4 *)(param_1 + 0x2d68) = 0;
    local_ef4 = 0;
    while (local_4._0_1_ = 0, (char)local_bc4[0] != '\0') {
      local_4._0_1_ = 0;
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,0);
      lstrcpyA(pCVar5,local_ec8);
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,0);
      lstrcpyA(pCVar5 + 0x20,local_ec8);
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,0);
      lstrcpyA(pCVar5 + 0x60,local_ec8);
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,0);
      lstrcpyA(pCVar5 + 0x80,local_ec8);
      FUN_0044c400((int)local_bc4,&local_ef4,local_ec8,1);
      lstrcpyA(pCVar5 + 0x90,local_ec8);
      cVar1 = *(char *)((int)local_bc4 + local_ef4);
      *(int *)(param_1 + 0x2d68) = *(int *)(param_1 + 0x2d68) + 1;
      if (cVar1 == '\0') break;
      local_eec = pCVar5;
      pCVar5 = operator_new(0x194);
      local_4._0_1_ = 4;
      local_ee8 = pCVar5;
      if (pCVar5 == (LPSTR)0x0) {
        pCVar5 = (LPSTR)0x0;
      }
      else {
        *pCVar5 = '\0';
        pCVar5[0x20] = '\0';
        pCVar5[0x60] = '\0';
        pCVar5[0x80] = '\0';
        pCVar5[0x90] = '\0';
        lstrcpyA(pCVar5,&DAT_00496cd0);
        lstrcpyA(pCVar5 + 0x20,&DAT_00496cd0);
        lstrcpyA(pCVar5 + 0x60,&DAT_00496cd0);
        lstrcpyA(pCVar5 + 0x80,&DAT_00496cd0);
        lstrcpyA(pCVar5 + 0x90,&DAT_00496cd0);
        pCVar5[400] = '\0';
        pCVar5[0x191] = '\0';
        pCVar5[0x192] = '\0';
        pCVar5[0x193] = '\0';
        param_1 = local_ef0;
      }
      local_4._0_1_ = 0;
      if (pCVar5 == (LPSTR)0x0) {
        local_dc8 = 0xffff0002;
        lstrcpyA(local_dc4,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_dc8,(ThrowInfo *)&DAT_0048b400);
      }
      *(LPSTR *)(local_eec + 400) = pCVar5;
      local_bc4[0]._0_1_ = *(char *)((int)local_bc4 + local_ef4);
    }
    FUN_00401520(&local_ee0);
  }
  local_4 = 0xffffffff;
  FUN_00401520(&local_ee0);
  ExceptionList = local_c;
  return;
}


