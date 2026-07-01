// FUN_005e5ce0  entry=005e5ce0  size=63 bytes

LPCSTR __thiscall FUN_005e5ce0(LPCSTR param_1,int param_2)

{
  int iVar1;
  
  iVar1 = lstrlenA(param_1);
  if (-1 < param_2) {
    if (param_2 < iVar1) {
      iVar1 = param_2;
    }
    param_1[iVar1] = '\0';
    return param_1;
  }
  lstrcpyA(param_1,param_1 + (iVar1 + param_2 & (iVar1 + param_2 < 1) - 1));
  return param_1;
}


