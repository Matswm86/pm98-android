// FUN_0042b540  entry=0042b540  size=2788 bytes

void __fastcall FUN_0042b540(void *param_1)

{
  int iVar1;
  CWnd *pCVar2;
  int *piVar3;
  int *piVar4;
  undefined4 uVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  undefined1 *puVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  char *lpString2;
  int local_288;
  CWnd *local_284 [2];
  int local_27c [2];
  int local_274;
  int local_270;
  uint local_26c;
  undefined4 local_268;
  undefined4 local_264;
  int local_260;
  undefined4 local_25c;
  undefined1 local_258 [8];
  undefined1 local_250 [16];
  undefined1 local_240 [16];
  CHAR local_230 [32];
  undefined4 local_210;
  CHAR local_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0047fa68;
  local_c = ExceptionList;
  local_230[0] = '\0';
  if (*(int *)((int)param_1 + 0x2d4c) == 0) {
    lpString2 = s_Proman10_004913b4;
    local_25c = 3;
    local_270 = 0x15;
    local_260 = 0x12;
    local_268 = 0xc4;
    local_264 = 0x10;
    local_26c = 0;
  }
  else {
    lpString2 = s_Futuri18_00493b24;
    local_25c = 9;
    local_270 = 0x19;
    local_260 = 0x28;
    local_268 = 0xbb;
    local_264 = 0x24;
    local_26c = 8;
  }
  ExceptionList = &local_c;
  lstrcpyA(local_230,lpString2);
  iVar8 = (-(uint)(*(int *)((int)param_1 + 0x2d4c) != 0) & 0xfffffffe) + 4;
  local_274 = iVar8;
  FUN_0045dd50(param_1,1);
  if (iVar8 < DAT_00497484) {
    pCVar2 = operator_new(0x418);
    local_4 = 0;
    if (pCVar2 == (CWnd *)0x0) {
      pCVar2 = (CWnd *)0x0;
    }
    else {
      FUN_00460c60(pCVar2);
      *(undefined ***)pCVar2 = &PTR_LAB_00486a38;
    }
    local_4 = 0xffffffff;
    if (pCVar2 == (CWnd *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0048b400);
    }
    iVar7 = *(int *)pCVar2;
    FUN_004042d0(&stack0xfffffd60,0);
    uVar11 = 0xdd;
    uVar10 = 0x200000;
    puVar9 = &DAT_00496cd0;
    piVar3 = (int *)FUN_00404120(local_284,0x25,0x13);
    piVar4 = (int *)FUN_00404120(local_27c,0xa2,2);
    uVar5 = FUN_00404180(local_250,piVar4,piVar3);
    (**(code **)(iVar7 + 0xc0))((int)param_1 + 0x45f4,uVar5,puVar9,uVar10,uVar11);
    *(int *)(pCVar2 + 0x54) = 0;
    FUN_0045dbf0(param_1,pCVar2,1);
  }
  iVar7 = 0;
  if (0 < DAT_00497484) {
    local_288 = 0;
    local_27c[0] = local_270;
    do {
      if (iVar8 <= iVar7) break;
      pCVar2 = operator_new(0x418);
      local_4 = 1;
      local_284[0] = pCVar2;
      if (pCVar2 == (CWnd *)0x0) {
        pCVar2 = (CWnd *)0x0;
      }
      else {
        FUN_00460c60(pCVar2);
        *(undefined ***)pCVar2 = &PTR_LAB_00486a38;
      }
      local_4 = 0xffffffff;
      if (pCVar2 == (CWnd *)0x0) {
        local_210 = 0xffff0002;
        lstrcpyA(local_20c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0048b400);
      }
      local_284[0] = (CWnd *)&stack0xfffffd60;
      iVar1 = *(int *)pCVar2;
      FUN_004042d0(&stack0xfffffd60,0);
      iVar8 = iVar7 + 0x96;
      uVar6 = local_26c | 0x200820;
      puVar9 = &DAT_00496cd0;
      piVar3 = (int *)FUN_00404120(local_258,local_268,local_264);
      piVar4 = (int *)FUN_00404120(local_250,local_25c,local_27c[0]);
      uVar5 = FUN_00404180(local_240,piVar4,piVar3);
      (**(code **)(iVar1 + 0xc0))((int)param_1 + 0x45f4,uVar5,puVar9,uVar6,iVar8);
      FUN_00456560(pCVar2,local_230);
      FUN_0042c1c0(pCVar2,*(int *)((int)param_1 + 0x2d4c),*(uint *)(DAT_00497480 + local_288));
      FUN_0042c030(pCVar2,(byte *)(DAT_00497480 + 0xc + local_288),*(int *)((int)param_1 + 0x2d4c));
      FUN_0045dbf0(param_1,pCVar2,1);
      iVar7 = iVar7 + 1;
      local_27c[0] = local_27c[0] + local_260;
      local_288 = local_288 + 0x50;
      iVar8 = local_274;
    } while (iVar7 < DAT_00497484);
  }
  iVar8 = (-(uint)(*(int *)((int)param_1 + 0x2d4c) != 0) & 0xfffffff8) + 0xf;
  local_274 = iVar8;
  FUN_0045dd50(param_1,2);
  if (iVar8 < DAT_0049749c) {
    pCVar2 = operator_new(0x418);
    local_4 = 2;
    local_284[0] = pCVar2;
    if (pCVar2 == (CWnd *)0x0) {
      pCVar2 = (CWnd *)0x0;
    }
    else {
      FUN_00460c60(pCVar2);
      *(undefined ***)pCVar2 = &PTR_LAB_00486a38;
    }
    local_4 = 0xffffffff;
    if (pCVar2 == (CWnd *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0048b400);
    }
    local_284[0] = (CWnd *)&stack0xfffffd60;
    iVar7 = *(int *)pCVar2;
    FUN_004042d0(&stack0xfffffd60,0);
    uVar11 = 0xde;
    uVar10 = 0x200000;
    puVar9 = &DAT_00496cd0;
    piVar3 = (int *)FUN_00404120(local_250,0x25,0x13);
    piVar4 = (int *)FUN_00404120(local_258,0xa2,2);
    uVar5 = FUN_00404180(local_240,piVar4,piVar3);
    (**(code **)(iVar7 + 0xc0))((int)param_1 + 0x4a0c,uVar5,puVar9,uVar10,uVar11);
    *(int *)(pCVar2 + 0x54) = 2;
    FUN_0045dbf0(param_1,pCVar2,2);
  }
  iVar7 = 0;
  if (0 < DAT_0049749c) {
    local_288 = 0;
    local_27c[0] = local_270;
    do {
      if (iVar8 <= iVar7) break;
      pCVar2 = operator_new(0x418);
      local_4 = 3;
      local_284[0] = pCVar2;
      if (pCVar2 == (CWnd *)0x0) {
        pCVar2 = (CWnd *)0x0;
      }
      else {
        FUN_00460c60(pCVar2);
        *(undefined ***)pCVar2 = &PTR_LAB_00486a38;
      }
      local_4 = 0xffffffff;
      if (pCVar2 == (CWnd *)0x0) {
        local_210 = 0xffff0002;
        lstrcpyA(local_20c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0048b400);
      }
      local_284[0] = (CWnd *)&stack0xfffffd60;
      iVar1 = *(int *)pCVar2;
      FUN_004042d0(&stack0xfffffd60,0);
      iVar8 = iVar7 + 0xa0;
      uVar6 = local_26c | 0x200820;
      puVar9 = &DAT_00496cd0;
      piVar3 = (int *)FUN_00404120(local_250,local_268,local_264);
      piVar4 = (int *)FUN_00404120(local_258,local_25c,local_27c[0]);
      uVar5 = FUN_00404180(local_240,piVar4,piVar3);
      (**(code **)(iVar1 + 0xc0))((int)param_1 + 0x4a0c,uVar5,puVar9,uVar6,iVar8);
      FUN_00456560(pCVar2,local_230);
      FUN_0042c1c0(pCVar2,*(int *)((int)param_1 + 0x2d4c),*(uint *)(DAT_00497498 + local_288));
      FUN_0042c030(pCVar2,(byte *)(DAT_00497498 + 0xc + local_288),*(int *)((int)param_1 + 0x2d4c));
      FUN_0045dbf0(param_1,pCVar2,2);
      iVar7 = iVar7 + 1;
      local_288 = local_288 + 0x50;
      local_27c[0] = local_27c[0] + local_260;
      iVar8 = local_274;
    } while (iVar7 < DAT_0049749c);
  }
  FUN_0045dd50(param_1,3);
  if (iVar8 < DAT_0049748c) {
    pCVar2 = operator_new(0x418);
    local_4 = 4;
    local_284[0] = pCVar2;
    if (pCVar2 == (CWnd *)0x0) {
      pCVar2 = (CWnd *)0x0;
    }
    else {
      FUN_00460c60(pCVar2);
      *(undefined ***)pCVar2 = &PTR_LAB_00486a38;
    }
    local_4 = 0xffffffff;
    if (pCVar2 == (CWnd *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0048b400);
    }
    local_284[0] = (CWnd *)&stack0xfffffd60;
    iVar7 = *(int *)pCVar2;
    FUN_004042d0(&stack0xfffffd60,0);
    uVar11 = 0xdf;
    uVar10 = 0x200000;
    puVar9 = &DAT_00496cd0;
    piVar3 = (int *)FUN_00404120(local_250,0x25,0x13);
    piVar4 = (int *)FUN_00404120(local_258,0xa2,2);
    uVar5 = FUN_00404180(local_240,piVar4,piVar3);
    (**(code **)(iVar7 + 0xc0))((int)param_1 + 0x4e24,uVar5,puVar9,uVar10,uVar11);
    *(int *)(pCVar2 + 0x54) = 2;
    FUN_0045dbf0(param_1,pCVar2,3);
  }
  iVar7 = 0;
  if (0 < DAT_0049748c) {
    local_288 = 0;
    local_27c[0] = local_270;
    do {
      if (iVar8 <= iVar7) break;
      pCVar2 = operator_new(0x418);
      local_4 = 5;
      local_284[0] = pCVar2;
      if (pCVar2 == (CWnd *)0x0) {
        pCVar2 = (CWnd *)0x0;
      }
      else {
        FUN_00460c60(pCVar2);
        *(undefined ***)pCVar2 = &PTR_LAB_00486a38;
      }
      local_4 = 0xffffffff;
      if (pCVar2 == (CWnd *)0x0) {
        local_210 = 0xffff0002;
        lstrcpyA(local_20c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0048b400);
      }
      local_284[0] = (CWnd *)&stack0xfffffd60;
      iVar1 = *(int *)pCVar2;
      FUN_004042d0(&stack0xfffffd60,0);
      iVar8 = iVar7 + 0xb4;
      uVar6 = local_26c | 0x200820;
      puVar9 = &DAT_00496cd0;
      piVar3 = (int *)FUN_00404120(local_250,local_268,local_264);
      piVar4 = (int *)FUN_00404120(local_258,local_25c,local_27c[0]);
      uVar5 = FUN_00404180(local_240,piVar4,piVar3);
      (**(code **)(iVar1 + 0xc0))((int)param_1 + 0x4e24,uVar5,puVar9,uVar6,iVar8);
      FUN_00456560(pCVar2,local_230);
      FUN_0042c1c0(pCVar2,*(int *)((int)param_1 + 0x2d4c),*(uint *)(DAT_00497488 + local_288));
      FUN_0042c030(pCVar2,(byte *)(DAT_00497488 + 0xc + local_288),*(int *)((int)param_1 + 0x2d4c));
      FUN_0045dbf0(param_1,pCVar2,3);
      iVar7 = iVar7 + 1;
      local_27c[0] = local_27c[0] + local_260;
      local_288 = local_288 + 0x50;
      iVar8 = local_274;
    } while (iVar7 < DAT_0049748c);
  }
  iVar8 = (-(uint)(*(int *)((int)param_1 + 0x2d4c) != 0) & 0xfffffff8) + 0xe;
  local_274 = iVar8;
  FUN_0045dd50(param_1,4);
  if (iVar8 < DAT_00497494) {
    pCVar2 = operator_new(0x418);
    local_4 = 6;
    local_284[0] = pCVar2;
    if (pCVar2 == (CWnd *)0x0) {
      pCVar2 = (CWnd *)0x0;
    }
    else {
      FUN_00460c60(pCVar2);
      *(undefined ***)pCVar2 = &PTR_LAB_00486a38;
    }
    local_4 = 0xffffffff;
    if (pCVar2 == (CWnd *)0x0) {
      local_210 = 0xffff0002;
      lstrcpyA(local_20c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0048b400);
    }
    local_284[0] = (CWnd *)&stack0xfffffd60;
    iVar7 = *(int *)pCVar2;
    FUN_004042d0(&stack0xfffffd60,0);
    uVar11 = 0xe0;
    uVar10 = 0x200000;
    puVar9 = &DAT_00496cd0;
    piVar3 = (int *)FUN_00404120(local_250,0x25,0x13);
    piVar4 = (int *)FUN_00404120(local_258,0xa2,2);
    uVar5 = FUN_00404180(local_240,piVar4,piVar3);
    (**(code **)(iVar7 + 0xc0))((int)param_1 + 0x523c,uVar5,puVar9,uVar10,uVar11);
    *(int *)(pCVar2 + 0x54) = 2;
    FUN_0045dbf0(param_1,pCVar2,4);
  }
  iVar7 = 0;
  if (0 < DAT_00497494) {
    local_288 = 0;
    local_27c[0] = local_270;
    do {
      if (iVar8 <= iVar7) {
        ExceptionList = local_c;
        return;
      }
      pCVar2 = operator_new(0x418);
      local_4 = 7;
      local_284[0] = pCVar2;
      if (pCVar2 == (CWnd *)0x0) {
        pCVar2 = (CWnd *)0x0;
      }
      else {
        FUN_00460c60(pCVar2);
        *(undefined ***)pCVar2 = &PTR_LAB_00486a38;
      }
      local_4 = 0xffffffff;
      if (pCVar2 == (CWnd *)0x0) {
        local_210 = 0xffff0002;
        lstrcpyA(local_20c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
        _CxxThrowException(&local_210,(ThrowInfo *)&DAT_0048b400);
      }
      local_284[0] = (CWnd *)&stack0xfffffd60;
      iVar1 = *(int *)pCVar2;
      FUN_004042d0(&stack0xfffffd60,0);
      iVar8 = iVar7 + 200;
      uVar6 = local_26c | 0x200820;
      puVar9 = &DAT_00496cd0;
      piVar3 = (int *)FUN_00404120(local_250,local_268,local_264);
      piVar4 = (int *)FUN_00404120(local_258,local_25c,local_27c[0]);
      uVar5 = FUN_00404180(local_240,piVar4,piVar3);
      (**(code **)(iVar1 + 0xc0))((int)param_1 + 0x523c,uVar5,puVar9,uVar6,iVar8);
      FUN_00456560(pCVar2,local_230);
      FUN_0042c1c0(pCVar2,*(int *)((int)param_1 + 0x2d4c),*(uint *)(DAT_00497490 + local_288));
      FUN_0042c030(pCVar2,(byte *)(DAT_00497490 + 0xc + local_288),*(int *)((int)param_1 + 0x2d4c));
      FUN_0045dbf0(param_1,pCVar2,4);
      iVar7 = iVar7 + 1;
      local_27c[0] = local_27c[0] + local_260;
      local_288 = local_288 + 0x50;
      iVar8 = local_274;
    } while (iVar7 < DAT_00497494);
  }
  ExceptionList = local_c;
  return;
}


