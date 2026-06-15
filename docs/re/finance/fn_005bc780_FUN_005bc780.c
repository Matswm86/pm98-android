// FUN_005bc780  entry=005bc780  size=1269 bytes

CWnd __thiscall
FUN_005bc780(CWnd *param_1,int param_2,int *param_3,char *param_4,undefined4 param_5,
            undefined4 param_6,int param_7,int param_8)

{
  CWnd *pCVar1;
  ulong dwExStyle;
  uint uVar2;
  int iVar3;
  HINSTANCE__ *hInstance;
  HICON pHVar4;
  HBRUSH__ *pHVar5;
  char *lpString2;
  undefined4 *puVar6;
  CWnd *pCVar7;
  int iVar8;
  uint dwStyle;
  HWND__ *pHVar9;
  CWnd CVar10;
  bool bVar11;
  LPCSTR lpIconName;
  tagRECT local_20;
  int iStack_10;
  undefined4 uStack_c;
  int iStack_8;
  undefined4 uStack_4;
  
  iVar3 = *(int *)(param_1 + 0xb4);
  *(undefined4 *)(param_1 + 0xac) = param_5;
  uVar2 = FUN_005bcc80(param_5,&DAT_00639510);
  dwExStyle = *(ulong *)(&DAT_00665900 + iVar3 * 4);
  local_20.left = *param_3;
  local_20.top = param_3[1];
  uVar2 = uVar2 | *(uint *)(&DAT_00665918 + iVar3 * 4);
  CVar10 = (CWnd)0x1;
  local_20.right = param_3[2];
  local_20.bottom = param_3[3];
  (**(code **)(*(int *)param_1 + 0xc4))();
  pCVar1 = param_1 + 0x40;
  pCVar7 = param_1 + 0x24c;
  *(undefined4 *)(param_1 + 0x50) = 0;
  *(undefined4 *)(param_1 + 0x4c) = 0;
  *(undefined4 *)(param_1 + 0x48) = 0;
  *(undefined4 *)(param_1 + 0x44) = 0;
  *(int *)pCVar1 = 0;
  *(undefined4 *)(param_1 + 0x74) = 0;
  *(uint *)(param_1 + 0x6c) = *(uint *)(param_1 + 0xac) >> 7 & 1;
  *(undefined4 *)(param_1 + 0x70) = 0;
  *(undefined4 *)(param_1 + 600) = 0;
  param_1[0x3ee] = (CWnd)0x1;
  param_1[0x3ef] = (CWnd)0x1;
  *(undefined4 *)(param_1 + 0x254) = 0;
  param_1[0x69] = (CWnd)0x0;
  iVar3 = 0x13;
  do {
    *(undefined4 *)pCVar7 = 0;
    iVar3 = iVar3 + -1;
    pCVar7 = pCVar7 + -8;
  } while (iVar3 != 0);
  CString::operator=((CString *)(param_1 + 0xb8),param_4);
  dwStyle = uVar2;
  if (((*(int *)(param_1 + 0xb4) == 4) && ((*(uint *)(param_1 + 0xac) & 0x60) != 0)) &&
     (dwStyle = uVar2 & 0xfffffffe, (*(uint *)(param_1 + 0xac) & 0x4000000) == 0)) {
    dwStyle = uVar2 & 0xfffffffa;
  }
  if ((dwStyle & 0x80000000) != 0) {
    dwStyle = dwStyle & 0xbfffffff;
  }
  if (DAT_00674660 == '\0') {
    AfxGetModuleState();
    lpIconName = (LPCSTR)0x80;
    hInstance = AfxFindResourceHandle((char *)0x80,(char *)0xe);
    pHVar4 = LoadIconA(hInstance,lpIconName);
    pHVar5 = GetStockObject(4);
    lpString2 = AfxRegisterWndClass(0xb,(HICON__ *)0x0,pHVar5,pHVar4);
    lstrcpyA(&DAT_00674660,lpString2);
  }
  if (param_8 == -1) {
    if (param_2 == 0) {
      param_5 = 0xc0c0c0;
      puVar6 = &param_5;
    }
    else {
      puVar6 = (undefined4 *)(param_2 + 0x60);
    }
  }
  else {
    puVar6 = &param_8;
  }
  *(undefined4 *)(param_1 + 0x60) = *puVar6;
  if (param_7 == -1) {
    if (param_2 == 0) {
      param_8 = 0;
      puVar6 = &param_8;
    }
    else {
      puVar6 = (undefined4 *)(param_2 + 0x5c);
    }
  }
  else {
    puVar6 = &param_7;
  }
  *(undefined4 *)(param_1 + 0x5c) = *puVar6;
  *(LONG *)(param_1 + 0x78) = local_20.left;
  *(LONG *)(param_1 + 0x7c) = local_20.top;
  *(LONG *)(param_1 + 0x80) = local_20.right;
  *(LONG *)(param_1 + 0x84) = local_20.bottom;
  AdjustWindowRectEx(&local_20,dwStyle,0,dwExStyle);
  DAT_00674c44 = 1;
  *(undefined4 *)(param_1 + 0xa8) = param_6;
  iVar3 = param_2;
  if (**(char **)(&DAT_00674e80 + *(int *)(param_1 + 0xb4) * 4) != '\0') {
    for (; (iVar3 != 0 && (*(int *)(iVar3 + 0x20) == 0)); iVar3 = *(int *)(iVar3 + 0x40)) {
      FUN_00495f20(iVar3 + 0x78);
    }
    if (iVar3 == 0) {
      pHVar9 = (HWND__ *)0x0;
    }
    else {
      pHVar9 = *(HWND__ **)(iVar3 + 0x20);
    }
    iVar3 = CWnd::CreateEx(param_1,dwExStyle,
                           *(char **)(&DAT_00674e80 + *(int *)(param_1 + 0xb4) * 4),param_4,dwStyle,
                           local_20.left,local_20.top,local_20.right - local_20.left,
                           local_20.bottom - local_20.top,pHVar9,*(HMENU__ **)(param_1 + 0xa8),
                           (void *)0x0);
    CVar10 = (CWnd)(iVar3 != 0);
  }
  pCVar7 = param_1 + 0x78;
  FUN_00437be0(&iStack_10,pCVar7);
  *(int *)(param_1 + 0x88) = iStack_10;
  *(undefined4 *)(param_1 + 0x8c) = uStack_c;
  *(int *)(param_1 + 0x90) = iStack_8;
  *(undefined4 *)(param_1 + 0x94) = uStack_4;
  DAT_00674c44 = 0;
  if (CVar10 != (CWnd)0x0) {
    if (*(int *)(param_1 + 0x20) != 0) {
      CWnd::SetWindowPos(param_1,(CWnd *)wndTop_exref,0,0,0,0,0xb);
    }
    uVar2 = *(uint *)(param_1 + 0xac) & 1;
    if (uVar2 != 0) {
      *(int *)(param_1 + 0x90) = *(int *)(param_1 + 0x90) + -6;
      *(int *)(param_1 + 0x94) = *(int *)(param_1 + 0x94) + -6;
    }
    if ((*(uint *)(param_1 + 0xac) & 0x400) == 0) {
      *(undefined4 *)(param_1 + 0x9c) = 0x70000000;
      *(undefined4 *)(param_1 + 0x98) = 0x70000000;
      *(undefined4 *)(param_1 + 0xa4) = 0x90000000;
      *(undefined4 *)(param_1 + 0xa0) = 0x90000000;
    }
    else if (uVar2 == 0) {
      FUN_00437be0(&iStack_10,pCVar7);
      *(int *)(param_1 + 0x98) = iStack_10;
      *(undefined4 *)(param_1 + 0x9c) = uStack_c;
      *(int *)(param_1 + 0xa0) = iStack_8;
      *(undefined4 *)(param_1 + 0xa4) = uStack_4;
    }
    else {
      FUN_00437be0(&iStack_10,pCVar7);
      *(undefined4 *)(param_1 + 0x98) = 0;
      *(undefined4 *)(param_1 + 0x9c) = 0;
      *(int *)(param_1 + 0xa0) = (iStack_8 - iStack_10) + -6;
      *(undefined4 *)(param_1 + 0xa4) = 0x1c;
    }
    FUN_005bc420(param_2);
    FUN_005bc370(param_1);
    if (param_2 != 0) {
      iVar3 = *(int *)pCVar1;
      pCVar7 = param_1 + 0x390;
      *(undefined4 *)(param_1 + 600) = *(undefined4 *)(iVar3 + 600);
      param_1[100] = *(CWnd *)(iVar3 + 100);
      param_1[0x65] = *(CWnd *)(iVar3 + 0x65);
      param_1[0x66] = *(CWnd *)(iVar3 + 0x66);
      param_1[0x67] = *(CWnd *)(iVar3 + 0x67);
      iVar3 = 4;
      do {
        iVar8 = iVar3;
        if (iVar3 < 0) {
          iVar8 = *(int *)(*(int *)pCVar1 + 0x70);
        }
        *(undefined2 *)pCVar7 = *(undefined2 *)(*(int *)pCVar1 + 0x388 + iVar8 * 2);
        pCVar7 = pCVar7 + -2;
        bVar11 = iVar3 != 0;
        iVar3 = iVar3 + -1;
      } while (bVar11);
      param_1[0x68] = *(CWnd *)(*(int *)pCVar1 + 0x68);
      FUN_005beae0(*(int *)pCVar1 + 0x3b4);
      iVar3 = 0x3b0;
      do {
        *(undefined4 *)(param_1 + iVar3) = *(undefined4 *)(iVar3 + *(int *)pCVar1);
        bVar11 = iVar3 != 0x394;
        iVar3 = iVar3 + -4;
      } while (bVar11);
      iVar3 = *(int *)pCVar1;
      if (((*(int *)(param_1 + 0x78) < 0) ||
          (*(int *)(iVar3 + 0x80) - *(int *)(iVar3 + 0x78) < *(int *)(param_1 + 0x80))) ||
         ((*(int *)(param_1 + 0x7c) < 0 ||
          (*(int *)(iVar3 + 0x84) - *(int *)(iVar3 + 0x7c) < *(int *)(param_1 + 0x84))))) {
        bVar11 = false;
      }
      else {
        bVar11 = true;
      }
      if (!bVar11) {
        param_1[0x3f0] = (CWnd)0x1;
        DAT_00674c34 = DAT_00674c34 + 1;
      }
    }
    param_1[0x3ec] = (CWnd)0x1;
    FUN_005bec80(0);
    FUN_005c1e10();
  }
  param_1[0x3ec] = CVar10;
  return CVar10;
}


