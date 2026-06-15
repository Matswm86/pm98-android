// FUN_0059a260  entry=0059a260  size=38 bytes
// callers/callees expanded one level from seeds

LPCSTR __thiscall FUN_0059a260(LPCSTR param_1,undefined4 param_2)

{
  int iVar1;
  char *_Format;
  
  _Format = &DAT_00652f00;
  iVar1 = lstrlenA(param_1);
  sprintf(param_1 + iVar1,_Format,param_2);
  return param_1;
}


