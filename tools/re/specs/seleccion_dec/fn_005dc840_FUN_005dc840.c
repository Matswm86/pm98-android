// FUN_005dc840  entry=005dc840  size=126 bytes

void __thiscall FUN_005dc840(int param_1,int param_2)

{
  CString *pCVar1;
  void *unaff_ESI;
  void *pvStack_c;
  undefined1 *local_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  local_8 = &LAB_00621688;
  pvStack_c = ExceptionList;
  ExceptionList = &pvStack_c;
  *(int *)(param_1 + 0x41c) = param_2;
  if (param_2 < *(int *)(*(int *)(param_1 + 0xb8) + -8)) {
    pCVar1 = (CString *)CString::Left((CString *)(param_1 + 0xb8),(int)&param_2);
    local_8 = (undefined1 *)0x0;
    CString::operator=((CString *)(param_1 + 0xb8),pCVar1);
    local_8 = (undefined1 *)0xffffffff;
    CString::~CString((CString *)&stack0x00000000);
    FUN_005bec80(0);
  }
  ExceptionList = unaff_ESI;
  return;
}


