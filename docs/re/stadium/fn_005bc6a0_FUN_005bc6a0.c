// FUN_005bc6a0  entry=005bc6a0  size=121 bytes

void __fastcall FUN_005bc6a0(CWnd *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_00620e8e;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *(undefined ***)param_1 = &PTR_LAB_00639530;
  local_4 = 2;
  FUN_005bd5e0();
  local_4._0_1_ = 1;
  FUN_00605da0(param_1 + 0x360,8,5,&LAB_005bc5e0);
  local_4 = (uint)local_4._1_3_ << 8;
  CString::~CString((CString *)(param_1 + 0xb8));
  local_4 = 0xffffffff;
  CWnd::~CWnd(param_1);
  ExceptionList = local_c;
  return;
}


