// FUN_005bc430  entry=005bc430  size=401 bytes

CWnd * __fastcall FUN_005bc430(CWnd *param_1)

{
  int iVar1;
  CWnd *pCVar2;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00620e36;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  CWnd::CWnd(param_1);
  *(undefined4 *)(param_1 + 0x50) = 0;
  *(undefined4 *)(param_1 + 0x4c) = 0;
  *(undefined4 *)(param_1 + 0x48) = 0;
  *(undefined4 *)(param_1 + 0x44) = 0;
  *(undefined4 *)(param_1 + 0x40) = 0;
  *(undefined4 *)(param_1 + 0x7c) = 0x70000000;
  *(undefined4 *)(param_1 + 0x78) = 0x70000000;
  *(undefined4 *)(param_1 + 0x84) = 0x90000000;
  *(undefined4 *)(param_1 + 0x80) = 0x90000000;
  *(undefined4 *)(param_1 + 0x8c) = 0x70000000;
  *(undefined4 *)(param_1 + 0x88) = 0x70000000;
  *(undefined4 *)(param_1 + 0x94) = 0x90000000;
  *(undefined4 *)(param_1 + 0x90) = 0x90000000;
  *(undefined4 *)(param_1 + 0x9c) = 0x70000000;
  *(undefined4 *)(param_1 + 0x98) = 0x70000000;
  local_4 = 0;
  *(undefined4 *)(param_1 + 0xa4) = 0x90000000;
  *(undefined4 *)(param_1 + 0xa0) = 0x90000000;
  CString::CString((CString *)(param_1 + 0xb8));
  param_1[0xbc] = (CWnd)0x0;
  param_1[0x25c] = (CWnd)0x0;
  local_4 = CONCAT31(local_4._1_3_,1);
  param_1[0x2dc] = (CWnd)0x0;
  FUN_00605ee0(param_1 + 0x360,8,5,&LAB_005bc5d0,&LAB_005bc5e0);
  param_1[0x3b4] = (CWnd)0x0;
  param_1[0x66] = (CWnd)0xff;
  param_1[0x67] = (CWnd)0xff;
  *(undefined ***)param_1 = &PTR_LAB_00639530;
  *(undefined4 *)(param_1 + 0xb4) = 2;
  *(undefined4 *)(param_1 + 0x35c) = 0;
  param_1[0x3ec] = (CWnd)0x0;
  param_1[0x3ee] = (CWnd)0x1;
  param_1[0x3ef] = (CWnd)0x1;
  *(undefined4 *)(param_1 + 0x254) = 0;
  *(undefined4 *)(param_1 + 0x54) = 0;
  param_1[0x69] = (CWnd)0x0;
  param_1[0x3ed] = (CWnd)0x0;
  *(undefined4 *)(param_1 + 600) = 0;
  *(undefined4 *)(param_1 + 0x74) = 0;
  *(undefined4 *)(param_1 + 0x70) = 0;
  *(undefined4 *)(param_1 + 0xb0) = 0xffffffff;
  *(undefined4 *)(param_1 + 0x3d4) = 0;
  *(undefined4 *)(param_1 + 0x3d8) = 0;
  *(undefined4 *)(param_1 + 0x3dc) = 0;
  *(undefined4 *)(param_1 + 0x3e0) = 0;
  param_1[100] = (CWnd)0x0;
  param_1[0x65] = (CWnd)0x0;
  *(undefined4 *)(param_1 + 0x6c) = 0;
  iVar1 = 5;
  pCVar2 = param_1 + 0x390;
  do {
    *(undefined2 *)pCVar2 = 0x100;
    iVar1 = iVar1 + -1;
    pCVar2 = pCVar2 + -2;
  } while (iVar1 != 0);
  *(undefined2 *)(param_1 + 0x390) = 0x80;
  pCVar2 = param_1 + 0x3b0;
  iVar1 = 8;
  do {
    *(undefined4 *)pCVar2 = 0;
    iVar1 = iVar1 + -1;
    pCVar2 = pCVar2 + -4;
  } while (iVar1 != 0);
  param_1[0x68] = (CWnd)0x0;
  param_1[0x3f0] = (CWnd)0x0;
  ExceptionList = local_c;
  return param_1;
}


