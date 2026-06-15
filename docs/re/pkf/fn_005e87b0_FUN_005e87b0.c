// FUN_005e87b0  entry=005e87b0  size=56 bytes

undefined4 __fastcall FUN_005e87b0(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005f9a70(param_1,4);
  if (iVar1 != 0) {
    iVar1 = FUN_005f9a70(param_1 + 4,4);
    if (iVar1 != 0) {
      return 1;
    }
  }
  return 0;
}


