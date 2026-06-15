// FUN_005a1ce0  entry=005a1ce0  size=39 bytes
// callers/callees expanded one level from seeds

int __fastcall FUN_005a1ce0(int *param_1)

{
  int iVar1;
  int iVar2;
  
  iVar2 = param_1[1];
  iVar1 = (iVar2 + 1) * 4;
  FUN_005bbf10(param_1,iVar1);
  param_1[1] = iVar2 + 1;
  return *param_1 + -4 + iVar1;
}


