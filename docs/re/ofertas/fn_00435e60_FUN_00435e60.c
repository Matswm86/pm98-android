// FUN_00435e60  entry=00435e60  size=32 bytes

void __thiscall FUN_00435e60(int *param_1,int *param_2,int *param_3)

{
  int iVar1;
  int iVar2;
  
  iVar1 = param_1[1];
  iVar2 = param_3[1];
  *param_2 = *param_1 + *param_3;
  param_2[1] = iVar1 + iVar2;
  return;
}


