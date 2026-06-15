// FUN_005f69b0  entry=005f69b0  size=1027 bytes
// callers/callees expanded one level from seeds

LPCSTR __thiscall FUN_005f69b0(int *param_1,undefined4 param_2,LPCSTR param_3,undefined4 param_4)

{
  char cVar1;
  LPCSTR pCVar2;
  undefined4 *puVar3;
  int iVar4;
  int iVar5;
  code *pcVar6;
  undefined4 *puVar7;
  code *pcVar8;
  LPCSTR local_814;
  LPCSTR local_810;
  undefined1 *local_80c;
  int local_808 [2];
  CHAR local_800;
  undefined4 local_7ff;
  undefined1 auStack_714 [8];
  undefined1 auStack_70c [4];
  undefined1 auStack_708 [8];
  CHAR local_700 [236];
  undefined1 auStack_614 [20];
  CHAR local_600;
  undefined4 local_5ff;
  undefined1 local_500 [240];
  undefined1 local_410 [248];
  undefined1 auStack_318 [8];
  undefined4 local_310;
  undefined1 local_30c [512];
  undefined1 local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  uint local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00622734;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005f6410(param_2);
  local_80c = local_500;
  local_810 = (LPCSTR)0x0;
  local_808[0] = 0;
  local_808[1] = 0;
  local_4 = 1;
  iVar5 = param_1[1] + -1;
  local_814 = (LPCSTR)0x0;
  iVar4 = param_1[1] / 2;
  if (-1 < iVar5) {
    do {
      if (param_1[1] <= iVar5) break;
      cVar1 = FUN_005f6e00(&local_80c);
      if (cVar1 == '\0') break;
      cVar1 = FUN_005f6e20(&local_80c);
      if (cVar1 == '\0') {
        iVar5 = iVar4 + -1;
      }
      else {
        local_814 = (LPCSTR)(iVar4 + 1);
      }
      iVar4 = (int)(local_814 + iVar5 + 1) / 2;
    } while ((int)local_814 <= iVar5);
  }
  if (iVar4 < param_1[1]) {
    cVar1 = FUN_005f6dc0(local_80c);
    if (cVar1 != '\0') {
      iVar5 = *param_1 + iVar4 * 0xc;
      *(int *)(iVar5 + 8) = *(int *)(iVar5 + 8) + 1;
      local_810 = *(LPCSTR *)(*param_1 + iVar4 * 0xc);
      goto LAB_005f6d56;
    }
  }
  pcVar8 = lstrcpyA_exref;
  if (param_3 != (LPCSTR)0x0) {
    lstrcpyA(&local_800,param_3);
    if (DAT_006dc2f8 != '\0') {
      iVar5 = FUN_005e5e00(0x5c);
      FUN_005e5c50(local_410,iVar5 + 1);
      FUN_005e5d50(iVar5 + 1);
      pcVar6 = lstrlenA_exref;
      iVar5 = lstrlenA(&DAT_006dc2f8);
      pCVar2 = (LPCSTR)FUN_005e5c50(&local_600,iVar5);
      iVar5 = lstrcmpA(pCVar2,&DAT_006dc2f8);
      if (iVar5 == 0) {
        iVar5 = lstrlenA(&DAT_006dc2f8);
        local_814 = (LPCSTR)FUN_005e5d20(local_10c,iVar5);
        lstrcpyA(local_700,&DAT_006dc1f0);
        pCVar2 = local_814;
        iVar5 = lstrlenA(local_700);
        lstrcpyA(local_700 + iVar5,pCVar2);
        FUN_0051fd00(local_700);
        lstrcpyA(&local_800,&local_600);
        puVar3 = &local_5ff;
        puVar7 = &local_7ff;
        for (iVar5 = 0x3f; iVar5 != 0; iVar5 = iVar5 + -1) {
          *puVar7 = *puVar3;
          puVar3 = puVar3 + 1;
          puVar7 = puVar7 + 1;
        }
        *(undefined2 *)puVar7 = *(undefined2 *)puVar3;
        *(undefined1 *)((int)puVar7 + 2) = *(undefined1 *)((int)puVar3 + 2);
        pcVar6 = lstrlenA_exref;
        pcVar8 = lstrcpyA_exref;
      }
      (*pcVar8)(local_700,local_410);
      iVar5 = (*pcVar6)(auStack_708,local_808);
      (*pcVar8)(auStack_70c + iVar5);
      FUN_0051fd00(auStack_714);
      (*pcVar8)(&local_814,auStack_614);
      puVar3 = &local_5ff;
      puVar7 = &local_7ff;
      for (iVar5 = 0x3f; iVar5 != 0; iVar5 = iVar5 + -1) {
        *puVar7 = *puVar3;
        puVar3 = puVar3 + 1;
        puVar7 = puVar7 + 1;
      }
      *(undefined2 *)puVar7 = *(undefined2 *)puVar3;
      *(undefined1 *)((int)puVar7 + 2) = *(undefined1 *)((int)puVar3 + 2);
      pcVar8 = lstrcpyA_exref;
    }
    local_814 = operator_new(0xf0);
    local_4._0_1_ = 2;
    if (local_814 == (LPCSTR)0x0) {
      local_814 = (LPCSTR)0x0;
    }
    else {
      local_814 = (LPCSTR)FUN_005f6410(param_2);
    }
    pCVar2 = local_814;
    local_4 = CONCAT31(local_4._1_3_,1);
    if (local_814 == (LPCSTR)0x0) {
      local_310 = 0xffff0002;
      (*pcVar8)(local_30c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(auStack_318,(ThrowInfo *)&DAT_0063ac98);
    }
    local_810 = local_814;
    cVar1 = FUN_005f6530(&local_800,0,param_4);
    if (cVar1 == '\0') {
      if (pCVar2 != (LPCSTR)0x0) {
        FUN_005f64b0();
        operator_delete(pCVar2);
      }
      local_810 = (LPCSTR)0x0;
    }
    else {
      FUN_005bbf10(param_1,(param_1[1] + 1) * 0xc);
      iVar5 = param_1[1];
      param_1[1] = iVar5 + 1;
      memmove((void *)(*param_1 + (iVar4 + 1) * 0xc),(void *)(*param_1 + iVar4 * 0xc),
              iVar5 * 0xc + iVar4 * -0xc);
      if (*param_1 + iVar4 * 0xc == 0) {
        pCRam00000000 = local_814;
        uRam00000004 = 1;
      }
      else {
        puVar3 = (undefined4 *)FUN_005f6de0(0,1);
        puVar3[1] = 1;
        *puVar3 = local_814;
      }
    }
  }
LAB_005f6d56:
  local_4 = local_4 & 0xffffff00;
  if ((local_808[0] != 0) && (local_80c != (undefined1 *)0x0)) {
    FUN_005f7130(1);
  }
  local_80c = (undefined1 *)0x0;
  local_4 = 0xffffffff;
  FUN_005f64b0();
  ExceptionList = local_c;
  return local_810;
}


