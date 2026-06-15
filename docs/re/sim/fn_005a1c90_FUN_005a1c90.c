// FUN_005a1c90  entry=005a1c90  size=76 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_005a1c90(int *param_1)

{
  int iVar1;
  int iVar2;
  
  iVar2 = param_1[1];
  iVar1 = iVar2 + -1;
  param_1[1] = iVar1;
  while (iVar2 != 0) {
    if (*param_1 + iVar1 * 0xc != 0) {
      FUN_005a1d40();
    }
    iVar2 = param_1[1];
    iVar1 = iVar2 + -1;
    param_1[1] = iVar1;
  }
  if (*param_1 != 0) {
    FUN_005bbed0(*param_1);
    *param_1 = 0;
  }
  param_1[1] = 0;
  return;
}


