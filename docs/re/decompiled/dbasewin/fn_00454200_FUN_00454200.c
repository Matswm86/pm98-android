// FUN_00454200  entry=00454200  size=1269 bytes

CWnd __thiscall
FUN_00454200(CWnd *param_1,int param_2,int *param_3,char *param_4,uint param_5,undefined4 param_6,
            int param_7,int param_8)

{
  CWnd *this;
  ulong dwExStyle;
  uint uVar1;
  int iVar2;
  HINSTANCE__ *hInstance;
  HICON pHVar3;
  HBRUSH__ *pHVar4;
  char *lpString2;
  uint *puVar5;
  int *piVar6;
  CWnd *pCVar7;
  undefined *this_00;
  int iVar8;
  uint dwStyle;
  HWND__ *pHVar9;
  bool bVar10;
  LPCSTR lpIconName;
  tagRECT local_20;
  int iStack_10;
  undefined4 uStack_c;
  int iStack_8;
  undefined4 uStack_4;
  
  piVar6 = param_3;
  iVar2 = *(int *)(param_1 + 0xb4);
  *(uint *)(param_1 + 0xac) = param_5;
  uVar1 = FUN_00454700(param_5,(uint *)&DAT_00489f68);
  dwExStyle = *(ulong *)(&DAT_004959c8 + iVar2 * 4);
  local_20.left = *param_3;
  local_20.top = param_3[1];
  uVar1 = uVar1 | *(uint *)(&DAT_004959e0 + iVar2 * 4);
  param_3._0_1_ = (CWnd)0x1;
  local_20.right = piVar6[2];
  local_20.bottom = piVar6[3];
  (**(code **)(*(int *)param_1 + 0xc4))();
  this = param_1 + 0x40;
  pCVar7 = param_1 + 0x24c;
  *(undefined4 *)(param_1 + 0x50) = 0;
  *(undefined4 *)(param_1 + 0x4c) = 0;
  *(undefined4 *)(param_1 + 0x48) = 0;
  *(undefined4 *)(param_1 + 0x44) = 0;
  *(int *)this = 0;
  *(undefined4 *)(param_1 + 0x74) = 0;
  *(uint *)(param_1 + 0x6c) = *(uint *)(param_1 + 0xac) >> 7 & 1;
  *(undefined4 *)(param_1 + 0x70) = 0;
  *(undefined4 *)(param_1 + 600) = 0;
  param_1[0x3ee] = (CWnd)0x1;
  param_1[0x3ef] = (CWnd)0x1;
  *(undefined4 *)(param_1 + 0x254) = 0;
  param_1[0x69] = (CWnd)0x0;
  iVar2 = 0x13;
  do {
    *(undefined4 *)pCVar7 = 0;
    iVar2 = iVar2 + -1;
    pCVar7 = pCVar7 + -8;
  } while (iVar2 != 0);
  CString::operator=((CString *)(param_1 + 0xb8),param_4);
  dwStyle = uVar1;
  if (((*(int *)(param_1 + 0xb4) == 4) && ((*(uint *)(param_1 + 0xac) & 0x60) != 0)) &&
     (dwStyle = uVar1 & 0xfffffffe, (*(uint *)(param_1 + 0xac) & 0x4000000) == 0)) {
    dwStyle = uVar1 & 0xfffffffa;
  }
  if ((dwStyle & 0x80000000) != 0) {
    dwStyle = dwStyle & 0xbfffffff;
  }
  if (DAT_005015e8 == '\0') {
    AfxGetModuleState();
    lpIconName = (LPCSTR)0x80;
    hInstance = AfxFindResourceHandle((char *)0x80,(char *)0xe);
    pHVar3 = LoadIconA(hInstance,lpIconName);
    pHVar4 = GetStockObject(4);
    lpString2 = AfxRegisterWndClass(0xb,(HICON__ *)0x0,pHVar4,pHVar3);
    lstrcpyA(&DAT_005015e8,lpString2);
  }
  if (param_8 == -1) {
    if (param_2 == 0) {
      param_5 = 0xc0c0c0;
      puVar5 = &param_5;
    }
    else {
      puVar5 = (uint *)(param_2 + 0x60);
    }
  }
  else {
    puVar5 = (uint *)&param_8;
  }
  *(uint *)(param_1 + 0x60) = *puVar5;
  if (param_7 == -1) {
    if (param_2 == 0) {
      param_8 = 0;
      piVar6 = &param_8;
    }
    else {
      piVar6 = (int *)(param_2 + 0x5c);
    }
  }
  else {
    piVar6 = &param_7;
  }
  *(int *)(param_1 + 0x5c) = *piVar6;
  *(LONG *)(param_1 + 0x78) = local_20.left;
  *(LONG *)(param_1 + 0x7c) = local_20.top;
  *(LONG *)(param_1 + 0x80) = local_20.right;
  *(LONG *)(param_1 + 0x84) = local_20.bottom;
  AdjustWindowRectEx(&local_20,dwStyle,0,dwExStyle);
  DAT_00501d8c = 1;
  *(undefined4 *)(param_1 + 0xa8) = param_6;
  iVar2 = param_2;
  if (**(char **)(&DAT_00501fc8 + *(int *)(param_1 + 0xb4) * 4) != '\0') {
    for (; (iVar2 != 0 && (*(int *)(iVar2 + 0x20) == 0)); iVar2 = *(int *)(iVar2 + 0x40)) {
      FUN_0044f9d0(&local_20,(int *)(iVar2 + 0x78));
    }
    if (iVar2 == 0) {
      pHVar9 = (HWND__ *)0x0;
    }
    else {
      pHVar9 = *(HWND__ **)(iVar2 + 0x20);
    }
    iVar2 = CWnd::CreateEx(param_1,dwExStyle,
                           *(char **)(&DAT_00501fc8 + *(int *)(param_1 + 0xb4) * 4),param_4,dwStyle,
                           local_20.left,local_20.top,local_20.right - local_20.left,
                           local_20.bottom - local_20.top,pHVar9,*(HMENU__ **)(param_1 + 0xa8),
                           (void *)0x0);
    param_3._0_1_ = (CWnd)(iVar2 != 0);
  }
  pCVar7 = param_1 + 0x78;
  FUN_00404230(pCVar7,&iStack_10,(int *)pCVar7);
  *(int *)(param_1 + 0x88) = iStack_10;
  *(undefined4 *)(param_1 + 0x8c) = uStack_c;
  *(int *)(param_1 + 0x90) = iStack_8;
  *(undefined4 *)(param_1 + 0x94) = uStack_4;
  DAT_00501d8c = 0;
  if (param_3._0_1_ != (CWnd)0x0) {
    if (*(int *)(param_1 + 0x20) != 0) {
      CWnd::SetWindowPos(param_1,(CWnd *)wndTop_exref,0,0,0,0,0xb);
    }
    uVar1 = *(uint *)(param_1 + 0xac) & 1;
    if (uVar1 != 0) {
      *(int *)(param_1 + 0x90) = *(int *)(param_1 + 0x90) + -6;
      *(int *)(param_1 + 0x94) = *(int *)(param_1 + 0x94) + -6;
    }
    if ((*(uint *)(param_1 + 0xac) & 0x400) == 0) {
      *(undefined4 *)(param_1 + 0x9c) = 0x70000000;
      *(undefined4 *)(param_1 + 0x98) = 0x70000000;
      *(undefined4 *)(param_1 + 0xa4) = 0x90000000;
      *(undefined4 *)(param_1 + 0xa0) = 0x90000000;
    }
    else if (uVar1 == 0) {
      FUN_00404230(pCVar7,&iStack_10,(int *)pCVar7);
      *(int *)(param_1 + 0x98) = iStack_10;
      *(undefined4 *)(param_1 + 0x9c) = uStack_c;
      *(int *)(param_1 + 0xa0) = iStack_8;
      *(undefined4 *)(param_1 + 0xa4) = uStack_4;
    }
    else {
      FUN_00404230(pCVar7,&iStack_10,(int *)pCVar7);
      *(undefined4 *)(param_1 + 0x98) = 0;
      *(undefined4 *)(param_1 + 0x9c) = 0;
      *(int *)(param_1 + 0xa0) = (iStack_8 - iStack_10) + -6;
      *(undefined4 *)(param_1 + 0xa4) = 0x1c;
    }
    FUN_00453e80(this,param_2);
    this_00 = (undefined *)(*(int *)this + 0x40);
    if (*(int *)this == 0) {
      this_00 = &DAT_00501d00;
    }
    FUN_00453dd0(this_00,(int)param_1);
    if (param_2 != 0) {
      iVar2 = *(int *)this;
      pCVar7 = param_1 + 0x390;
      *(undefined4 *)(param_1 + 600) = *(undefined4 *)(iVar2 + 600);
      param_1[100] = *(CWnd *)(iVar2 + 100);
      param_1[0x65] = *(CWnd *)(iVar2 + 0x65);
      param_1[0x66] = *(CWnd *)(iVar2 + 0x66);
      param_1[0x67] = *(CWnd *)(iVar2 + 0x67);
      iVar2 = 4;
      do {
        iVar8 = iVar2;
        if (iVar2 < 0) {
          iVar8 = *(int *)(*(int *)this + 0x70);
        }
        *(undefined2 *)pCVar7 = *(undefined2 *)(*(int *)this + 0x388 + iVar8 * 2);
        pCVar7 = pCVar7 + -2;
        bVar10 = iVar2 != 0;
        iVar2 = iVar2 + -1;
      } while (bVar10);
      param_1[0x68] = *(CWnd *)(*(int *)this + 0x68);
      FUN_00456560(param_1,(LPCSTR)(*(int *)this + 0x3b4));
      iVar2 = 0x3b0;
      do {
        *(undefined4 *)(param_1 + iVar2) = *(undefined4 *)(iVar2 + *(int *)this);
        bVar10 = iVar2 != 0x394;
        iVar2 = iVar2 + -4;
      } while (bVar10);
      iVar2 = *(int *)this;
      if (((*(int *)(param_1 + 0x78) < 0) ||
          (*(int *)(iVar2 + 0x80) - *(int *)(iVar2 + 0x78) < *(int *)(param_1 + 0x80))) ||
         ((*(int *)(param_1 + 0x7c) < 0 ||
          (*(int *)(iVar2 + 0x84) - *(int *)(iVar2 + 0x7c) < *(int *)(param_1 + 0x84))))) {
        bVar10 = false;
      }
      else {
        bVar10 = true;
      }
      if (!bVar10) {
        param_1[0x3f0] = (CWnd)0x1;
        DAT_00501d7c = DAT_00501d7c + 1;
      }
    }
    param_1[0x3ec] = (CWnd)0x1;
    FUN_00456700(param_1,'\0');
    FUN_004597f0((int *)param_1);
  }
  param_1[0x3ec] = param_3._0_1_;
  return param_3._0_1_;
}


