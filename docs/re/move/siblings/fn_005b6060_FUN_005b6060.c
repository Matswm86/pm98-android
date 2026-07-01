// FUN_005b6060  entry=005b6060  size=70 bytes

void __fastcall FUN_005b6060(int param_1)

{
  int iVar1;
  
  *(undefined2 *)(param_1 + 0x34) = 0xc000;
  iVar1 = *(int *)(param_1 + 0x3cc) + 1;
  *(int *)(param_1 + 0x3cc) = iVar1;
  if ((100 < iVar1) && (iVar1 < 200)) {
    FUN_005a5430(0x41);
    FUN_005a50c0();
    return;
  }
  FUN_005a5430(0x38);
  FUN_005a50c0();
  return;
}


