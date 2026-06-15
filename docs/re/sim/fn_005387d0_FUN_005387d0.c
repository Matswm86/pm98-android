// FUN_005387d0  entry=005387d0  size=123 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_005387d0(int param_1,undefined4 param_2)

{
  char *pcVar1;
  
  pcVar1 = (char *)0x0;
  switch(*(undefined4 *)(param_1 + 0x1940)) {
  case 0:
    pcVar1 = s_KICK_OFF_0065cc54;
    break;
  case 1:
    pcVar1 = s_FIRST_HALF_0065cc48;
    break;
  case 2:
    pcVar1 = s_SECOND_HALF_0065cc3c;
    break;
  case 3:
    pcVar1 = s_FIRST_HALF_EXTRA_TIME_0065cc24;
    break;
  case 4:
    pcVar1 = s_SECOND_HALF_EXTRA_TIME_0065cc0c;
    break;
  case 5:
    pcVar1 = s_PENALTIES_0065cc00;
    break;
  case 6:
    pcVar1 = s_FULL_TIME_00656364;
  }
  if (pcVar1 != (char *)0x0) {
    CString::operator=((CString *)(param_1 + 0x4b28),pcVar1);
    if (*(int *)(param_1 + 0x4a90) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0x4a70),pcVar1);
    }
    FUN_005bec80(param_2);
  }
  return;
}


