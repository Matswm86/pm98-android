// FUN_005f9ae0  entry=005f9ae0  size=146 bytes

bool __thiscall FUN_005f9ae0(undefined4 *param_1,int param_2,int param_3)

{
  DWORD DVar1;
  
  if ((param_1[1] == 0) || (param_1[1] == -1)) {
    DVar1 = 0;
    if (param_3 != 0) {
      DVar1 = (param_3 != 1) + 1;
    }
    DVar1 = SetFilePointer((HANDLE)*param_1,param_2,(PLONG)0x0,DVar1);
    return DVar1 != 0xffffffff;
  }
  if (param_3 == 0) {
    param_1[4] = param_2;
    return true;
  }
  if (param_3 == 1) {
    param_1[4] = param_2 + param_1[4];
    return true;
  }
  DVar1 = GetFileSize((HANDLE)*param_1,(LPDWORD)0x0);
  param_1[4] = param_2 + DVar1;
  return true;
}


