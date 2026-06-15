// FUN_0050c1f0  entry=0050c1f0  size=123 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __fastcall FUN_0050c1f0(int param_1)

{
  float fVar1;
  char *pcVar2;
  undefined1 auStack_100 [256];
  
  if ((float)_DAT_0062e010 < *(float *)(param_1 + 0x430)) {
    fVar1 = *(float *)(param_1 + 0x430) - (float)_DAT_0062e010;
    *(float *)(param_1 + 0x430) = fVar1;
    pcVar2 = (char *)FUN_0058dd00(auStack_100,(double)fVar1,0);
    CString::operator=((CString *)(param_1 + 0x1d98),pcVar2);
    if (*(int *)(param_1 + 0x1d00) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0x1ce0),pcVar2);
    }
    FUN_005bec80(1);
  }
  return;
}


