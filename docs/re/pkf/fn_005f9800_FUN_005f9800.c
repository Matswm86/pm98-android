// FUN_005f9800  entry=005f9800  size=200 bytes

undefined4 __thiscall
FUN_005f9800(int *param_1,LPCSTR param_2,uint param_3,int param_4,uint param_5)

{
  HANDLE pvVar1;
  DWORD dwCreationDisposition;
  DWORD dwShareMode;
  
  if ((param_3 & 0x20) == 0) {
    dwShareMode = param_3 & 3;
  }
  else {
    dwShareMode = 0;
  }
  if ((param_3 & 0x10) == 0) {
    dwCreationDisposition = ((param_3 & 8) != 0) + 3;
  }
  else {
    dwCreationDisposition = 2;
  }
  pvVar1 = CreateFileA(param_2,(param_3 * 4 | param_3 & 2) << 0x1d,dwShareMode,
                       (LPSECURITY_ATTRIBUTES)0x0,dwCreationDisposition,param_5 | 0x80,(HANDLE)0x0);
  *param_1 = (int)pvVar1;
  if (((pvVar1 == (HANDLE)0x0) || (pvVar1 == (HANDLE)0xffffffff)) && ((param_3 & 4) != 0)) {
    param_3 = param_3 & 0xfffffffd;
    pvVar1 = CreateFileA(param_2,0x80000000,1,(LPSECURITY_ATTRIBUTES)0x0,3,param_5 | 0x80,
                         (HANDLE)0x0);
    *param_1 = (int)pvVar1;
  }
  if (((param_4 != 0) && ((param_3 & 1) != 0)) && ((param_3 & 2) == 0)) {
    FUN_005f9950();
  }
  param_1[5] = param_3;
  if ((*param_1 != 0) && (*param_1 != -1)) {
    return 1;
  }
  return 0;
}


