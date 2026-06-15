// FUN_005f2cf0  entry=005f2cf0  size=95 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_005f2cf0(int *param_1,undefined4 param_2)

{
  int iVar1;
  int iVar2;
  
  iVar2 = param_1[1];
  iVar1 = iVar2 + -1;
  param_1[1] = iVar1;
  while (iVar2 != 0) {
    if (*param_1 + iVar1 * 0x13c != 0) {
      FUN_005a1e30();
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
  FUN_005f2d50(param_2);
  return;
}


