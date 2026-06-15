// FUN_004706d0  entry=004706d0  size=52 bytes

void __thiscall FUN_004706d0(CWnd *param_1,char *param_2,undefined4 param_3)

{
  CString::operator=((CString *)(param_1 + 0xb8),param_2);
  if (*(int *)(param_1 + 0x20) != 0) {
    CWnd::SetWindowTextA(param_1,param_2);
  }
  FUN_005bec80(param_3);
  return;
}


