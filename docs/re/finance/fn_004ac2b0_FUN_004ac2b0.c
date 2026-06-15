// FUN_004ac2b0  entry=004ac2b0  size=45 bytes

void __thiscall FUN_004ac2b0(int *param_1,int *param_2,int param_3)

{
  int iVar1;
  int iVar2;
  int iVar3;
  
  iVar1 = param_1[3];
  iVar2 = param_1[2];
  iVar3 = *param_1;
  param_2[1] = param_1[1] - param_3;
  param_2[2] = iVar2 + param_3;
  *param_2 = iVar3 - param_3;
  param_2[3] = iVar1 + param_3;
  return;
}


