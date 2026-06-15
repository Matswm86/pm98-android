// FUN_005f99d0  entry=005f99d0  size=47 bytes

void __fastcall FUN_005f99d0(int *param_1)

{
  FUN_005f9910();
  if ((*param_1 != 0) && (*param_1 != -1)) {
    FUN_005f9ae0(0,2);
    CloseHandle((HANDLE)*param_1);
    *param_1 = 0;
  }
  return;
}


