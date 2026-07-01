// FUN_005b8bf0  entry=005b8bf0  size=37 bytes

void __fastcall FUN_005b8bf0(undefined4 *param_1)

{
  int *piVar1;
  int iVar2;
  
  piVar1 = (int *)*param_1;
  for (iVar2 = param_1[1]; iVar2 != 0; iVar2 = iVar2 + -1) {
    (**(code **)(*piVar1 + 8))();
    piVar1 = piVar1 + 0xef;
  }
  return;
}


