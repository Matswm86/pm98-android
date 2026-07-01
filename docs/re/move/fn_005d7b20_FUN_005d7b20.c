// FUN_005d7b20  entry=005d7b20  size=66 bytes

void __fastcall FUN_005d7b20(int *param_1)

{
  int *piVar1;
  
  if ((*param_1 != 0) || (param_1[0x10] != 0)) {
    FUN_005cb320();
  }
  FUN_005d7ba0();
  piVar1 = (int *)param_1[0x5c];
  if (piVar1 != (int *)0x0) {
    (**(code **)(*piVar1 + 0x28))(piVar1);
  }
  FUN_005f6230(param_1);
  FUN_005d8350();
  return;
}


