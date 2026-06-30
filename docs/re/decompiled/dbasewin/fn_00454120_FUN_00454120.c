// FUN_00454120  entry=00454120  size=121 bytes

void __fastcall FUN_00454120(CWnd *param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_00482ace;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *(undefined ***)param_1 = &PTR_LAB_00489f88;
  local_4 = 2;
  FUN_00455060((int *)param_1);
  local_4._0_1_ = 1;
  FUN_0047e100(param_1 + 0x360,8,5,&LAB_00454060);
  local_4 = (uint)local_4._1_3_ << 8;
  CString::~CString((CString *)(param_1 + 0xb8));
  local_4 = 0xffffffff;
  CWnd::~CWnd(param_1);
  ExceptionList = local_c;
  return;
}


