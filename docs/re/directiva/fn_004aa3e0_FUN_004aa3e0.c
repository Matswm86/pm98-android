// FUN_004aa3e0  entry=004aa3e0  size=78 bytes

void __thiscall FUN_004aa3e0(int *param_1,int *param_2,int *param_3)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  
  iVar3 = param_1[3];
  if (param_3[3] <= param_1[3]) {
    iVar3 = param_3[3];
  }
  iVar4 = param_1[2];
  if (param_3[2] <= param_1[2]) {
    iVar4 = param_3[2];
  }
  iVar2 = param_3[1];
  if (param_3[1] < param_1[1]) {
    iVar2 = param_1[1];
  }
  iVar1 = *param_1;
  if (*param_1 <= *param_3) {
    iVar1 = *param_3;
  }
  param_2[2] = iVar4;
  param_2[3] = iVar3;
  *param_2 = iVar1;
  param_2[1] = iVar2;
  return;
}


