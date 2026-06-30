// FUN_004589b0  entry=004589b0  size=722 bytes

undefined1 __thiscall FUN_004589b0(void *this,uint param_1)

{
  LPCSTR lpString;
  int iVar1;
  undefined4 *puVar2;
  LPSTR pCVar3;
  uint uVar4;
  undefined1 uVar5;
  char *lpString2;
  CHAR local_810 [256];
  CHAR local_710 [256];
  undefined4 local_610;
  CHAR local_60c [512];
  CHAR local_40c [256];
  char local_30c [256];
  CHAR local_20c [256];
  CHAR local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00482bdc;
  local_c = ExceptionList;
  if (param_1 == 0xffffffff) {
    param_1 = *(uint *)((int)this + 0x70);
  }
  if ((((int)param_1 < 0) || (4 < (int)param_1)) || (*(int *)((int)this + param_1 * 8 + 0x364) == 0)
     ) {
    uVar5 = 0;
  }
  else {
    uVar4 = *(int *)((int)this + 0x74) % *(int *)((int)this + param_1 * 8 + 0x364) & 0xffff;
    ExceptionList = &local_c;
    *(uint *)((int)this + 0x74) = uVar4;
    iVar1 = *(int *)((int)this + param_1 * 8 + 0x360);
    lpString = (LPCSTR)(iVar1 + uVar4 * 0x94);
    if ((*(int *)(iVar1 + 0x80 + uVar4 * 0x94) == 0) && (iVar1 = lstrlenA(lpString), iVar1 != 0)) {
      puVar2 = operator_new(0x4c);
      iVar1 = 0;
      local_4 = 0;
      if (puVar2 != (undefined4 *)0x0) {
        iVar1 = FUN_0044c790(puVar2);
      }
      local_4 = 0xffffffff;
      if (iVar1 == 0) {
        local_610 = 0xffff0002;
        lstrcpyA(local_60c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_610,(ThrowInfo *)&DAT_0048b400);
      }
      *(int *)(lpString + 0x80) = iVar1;
      lpString[0x84] = '\x01';
      lpString[0x85] = '\0';
      lpString[0x86] = '\0';
      lpString[0x87] = '\0';
      FUN_0044d4e0(*(void **)(lpString + 0x80),lpString,0,-1);
      if ((lpString[0x90] & 0x40U) != 0) {
        puVar2 = operator_new(0x4c);
        local_4 = 1;
        if (puVar2 == (undefined4 *)0x0) {
          iVar1 = 0;
        }
        else {
          iVar1 = FUN_0044c790(puVar2);
        }
        local_4 = 0xffffffff;
        if (iVar1 == 0) {
          local_610 = 0xffff0002;
          lstrcpyA(local_60c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
          _CxxThrowException(&local_610,(ThrowInfo *)&DAT_0048b400);
        }
        *(int *)(lpString + 0x88) = iVar1;
        lpString[0x8c] = '\x01';
        lpString[0x8d] = '\0';
        lpString[0x8e] = '\0';
        lpString[0x8f] = '\0';
        pCVar3 = FUN_00465930(lpString,local_10c,4);
        lstrcpyA(local_810,pCVar3);
        lpString2 = s__ALPHA_00495a10;
        iVar1 = lstrlenA(local_810);
        lstrcpyA(local_810 + iVar1,lpString2);
        FUN_0040d1f0(local_40c,local_810);
        pCVar3 = FUN_004658a0(lpString,local_20c,0xfffffffc);
        lstrcpyA(local_710,local_40c);
        iVar1 = lstrlenA(local_710);
        lstrcpyA(local_710 + iVar1,pCVar3);
        FUN_0040d1f0(local_30c,local_710);
        FUN_0044d4e0(*(void **)(lpString + 0x88),local_30c,0,-1);
      }
    }
    if (*(int *)(lpString + 0x80) == 0) {
      uVar5 = 0;
    }
    else {
      uVar5 = 1;
      if (((*(uint *)((int)this + 0x70) != param_1) || (*(char *)((int)this + 0x3ee) != '\0')) &&
         ((*(uint *)((int)this + 0x70) = param_1 & 0xffff,
          1 < *(int *)((int)this + (param_1 & 0xffff) * 8 + 0x364) ||
          (*(int *)(*(int *)(lpString + 0x80) + 0xc) != 0)))) {
        FUN_00456bc0(this,0x80000000,10);
      }
    }
  }
  ExceptionList = local_c;
  return uVar5;
}


