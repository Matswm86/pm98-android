// FUN_005b1230  entry=005b1230  size=38 bytes

void __thiscall FUN_005b1230(int *param_1,int *param_2,int param_3)

{
  int iVar1;
  int iVar2;
  
  iVar1 = param_1[2];
  iVar2 = *param_1;
  param_2[1] = param_1[1] * param_3;
  *param_2 = iVar2 * param_3;
  param_2[2] = iVar1 * param_3;
  return;
}


