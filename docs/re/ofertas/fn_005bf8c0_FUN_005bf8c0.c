// FUN_005bf8c0  entry=005bf8c0  size=202 bytes

void __thiscall FUN_005bf8c0(CWnd *param_1,uint param_2,char param_3)

{
  uint uVar1;
  CWnd *pCVar2;
  int iVar3;
  char cVar4;
  bool bVar5;
  
  cVar4 = (char)param_2;
  while( true ) {
    iVar3 = *(int *)(param_1 + 0x6c) + (-(uint)(cVar4 != '\0') & 0xfffffffe) + 1;
    *(int *)(param_1 + 0x6c) = iVar3;
    if (cVar4 == '\0') {
      bVar5 = iVar3 == 1;
    }
    else {
      bVar5 = iVar3 == 0;
    }
    if (bVar5) {
      if (*(int *)(param_1 + 0x20) != 0) {
        CWnd::EnableWindow(param_1,param_2 & 0xff);
      }
      if (cVar4 == '\0') {
        uVar1 = *(uint *)(param_1 + 0xac) | 0x80;
      }
      else {
        uVar1 = *(uint *)(param_1 + 0xac) & 0xffffff7f;
      }
      *(uint *)(param_1 + 0xac) = uVar1;
      for (iVar3 = *(int *)(param_1 + 0x44); iVar3 != 0; iVar3 = *(int *)(iVar3 + 0x50)) {
        FUN_005bf8c0((CWnd *)param_2,0);
      }
      if (param_3 != '\0') {
        FUN_005bec80(0);
      }
    }
    param_1 = *(CWnd **)(param_1 + 0x50);
    if ((param_1 == (CWnd *)0x0) || (pCVar2 = param_1, ((byte)param_1[0xac] & 0x10) == 0)) {
      pCVar2 = (CWnd *)0x0;
    }
    if (pCVar2 == (CWnd *)0x0) break;
    if ((param_1 == (CWnd *)0x0) || (((byte)param_1[0xac] & 0x10) == 0)) {
      param_1 = (CWnd *)0x0;
    }
  }
  return;
}


