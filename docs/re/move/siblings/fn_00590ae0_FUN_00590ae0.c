// FUN_00590ae0  entry=00590ae0  size=45 bytes

void __thiscall FUN_00590ae0(int *param_1,int *param_2,int *param_3)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  
  iVar1 = param_1[2];
  iVar2 = param_3[2];
  iVar3 = *param_1;
  iVar4 = *param_3;
  param_2[1] = param_1[1] - param_3[1];
  *param_2 = iVar3 - iVar4;
  param_2[2] = iVar1 - iVar2;
  return;
}


