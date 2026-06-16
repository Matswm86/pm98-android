// FUN_0058dd00  entry=0058dd00  size=112 bytes
// callers/callees expanded one level from seeds

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

LPSTR FUN_0058dd00(LPSTR param_1,double param_2)

{
  LPCSTR lpString2;
  int iVar1;
  CHAR local_200 [256];
  undefined1 local_100;
  
  local_100 = 0;
  lstrcpyA(local_200,&DAT_00663c08);
  lpString2 = (LPCSTR)FUN_005e5ee0(param_2 * _DAT_00639040,0);
  iVar1 = lstrlenA(local_200);
  lstrcpyA(local_200 + iVar1,lpString2);
  lstrcpyA(param_1,local_200);
  return param_1;
}


