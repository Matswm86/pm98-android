// FUN_004c4200  entry=004c4200  size=30 bytes

LPCSTR __thiscall FUN_004c4200(LPCSTR param_1,LPCSTR param_2)

{
  int iVar1;
  
  iVar1 = lstrlenA(param_1);
  lstrcpyA(param_1 + iVar1,param_2);
  return param_1;
}


