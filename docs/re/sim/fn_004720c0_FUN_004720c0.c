// FUN_004720c0  entry=004720c0  size=1061 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_004720c0(int param_1,int param_2)

{
  int iVar1;
  int unaff_EBX;
  bool bVar2;
  
  if ((*(uint *)(param_1 + 0x1154) >> 7 & 1) != 0) {
    FUN_005bf8c0(1,1);
  }
  if ((*(uint *)(param_1 + 0x156c) >> 7 & 1) != 0) {
    FUN_005bf8c0(1,1);
  }
  iVar1 = *(int *)(*(int *)(*(int *)(param_1 + 0x434) + 4) + 8);
  if (param_2 == 8) {
    param_2 = 7;
  }
  *(int *)(param_1 + 0x430) = param_2;
  switch(param_2) {
  case 0:
    CString::operator=((CString *)(param_1 + 0xd48),s_ROUND_1_00653e28);
    if (*(int *)(param_1 + 0xcb0) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0xc90),s_ROUND_1_00653e28);
    }
    FUN_005bec80(0);
    FUN_00472f80(*(undefined4 *)(param_1 + 0x430));
    if ((~(byte)(*(uint *)(param_1 + 0x1154) >> 7) & 1) != 0) {
      FUN_005bf8c0(0,1);
    }
    if (iVar1 != 0) {
      return;
    }
    if ((~(byte)(*(uint *)(unaff_EBX + 0xac) >> 7) & 1) == 0) {
      return;
    }
    FUN_005bf8c0(0,1);
    return;
  case 1:
    CString::operator=((CString *)(param_1 + 0xd48),s_ROUND_2_00653e20);
    if (*(int *)(param_1 + 0xcb0) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0xc90),s_ROUND_2_00653e20);
    }
    FUN_005bec80(0);
    FUN_00472f80(*(undefined4 *)(param_1 + 0x430));
    if (iVar1 == 0) goto LAB_0047241b;
    bVar2 = iVar1 == 1;
    break;
  case 2:
    CString::operator=((CString *)(param_1 + 0xd48),s_ROUND_3_00653e18);
    if (*(int *)(param_1 + 0xcb0) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0xc90),s_ROUND_3_00653e18);
    }
    FUN_005bec80(0);
    FUN_00472f80(*(undefined4 *)(param_1 + 0x430));
    if ((iVar1 == 0) || (iVar1 == 1)) goto LAB_0047241b;
    bVar2 = iVar1 == 2;
    break;
  case 3:
    CString::operator=((CString *)(param_1 + 0xd48),s_ROUND_4_00653e10);
    if (*(int *)(param_1 + 0xcb0) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0xc90),s_ROUND_4_00653e10);
    }
    FUN_005bec80(0);
    FUN_00472f80(*(undefined4 *)(param_1 + 0x430));
    if (((iVar1 == 0) || (iVar1 == 1)) || (iVar1 == 2)) goto LAB_0047241b;
    bVar2 = iVar1 == 3;
    break;
  case 4:
    CString::operator=((CString *)(param_1 + 0xd48),s_ROUND_5_00654014);
    if (*(int *)(param_1 + 0xcb0) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0xc90),s_ROUND_5_00654014);
    }
    FUN_005bec80(0);
    FUN_00472f80(*(undefined4 *)(param_1 + 0x430));
    if ((((iVar1 == 0) || (iVar1 == 1)) || (iVar1 == 2)) || (iVar1 == 3)) goto LAB_0047241b;
    bVar2 = iVar1 == 4;
    break;
  case 5:
    CString::operator=((CString *)(param_1 + 0xd48),s_QTR_FINALS_00653e04);
    if (*(int *)(param_1 + 0xcb0) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0xc90),s_QTR_FINALS_00653e04);
    }
    FUN_005bec80(0);
    FUN_00472f80(*(undefined4 *)(param_1 + 0x430));
    if (((iVar1 == 0) || (iVar1 == 1)) || ((iVar1 == 2 || ((iVar1 == 3 || (iVar1 == 4))))))
    goto LAB_0047241b;
    bVar2 = iVar1 == 5;
    break;
  case 6:
    CString::operator=((CString *)(param_1 + 0xd48),s_SEMIFINALS_006538b0);
    if (*(int *)(param_1 + 0xcb0) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0xc90),s_SEMIFINALS_006538b0);
    }
    FUN_005bec80(0);
    FUN_00472f80(*(undefined4 *)(param_1 + 0x430));
    if (((((iVar1 == 0) || (iVar1 == 1)) || (iVar1 == 2)) || ((iVar1 == 3 || (iVar1 == 4)))) ||
       (iVar1 == 5)) goto LAB_0047241b;
    bVar2 = iVar1 == 6;
    break;
  case 7:
  case 8:
    CString::operator=((CString *)(param_1 + 0xd48),s_FINAL_00653dfc);
    if (*(int *)(param_1 + 0xcb0) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0xc90),s_FINAL_00653dfc);
    }
    FUN_005bec80(0);
    FUN_00472f80(*(undefined4 *)(param_1 + 0x430));
    if ((~(byte)(*(uint *)(param_1 + 0x156c) >> 7) & 1) == 0) {
      return;
    }
    FUN_005bf8c0(0,1);
    return;
  default:
    CString::operator=((CString *)(param_1 + 0xd48),s_ERROR_00653df4);
    if (*(int *)(param_1 + 0xcb0) != 0) {
      CWnd::SetWindowTextA((CWnd *)(param_1 + 0xc90),s_ERROR_00653df4);
    }
    FUN_005bec80(0);
    return;
  }
  if (!bVar2) {
    return;
  }
LAB_0047241b:
  if ((~(byte)(*(uint *)(unaff_EBX + 0xac) >> 7) & 1) == 0) {
    return;
  }
  FUN_005bf8c0(0,1);
  return;
}


