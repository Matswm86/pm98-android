// FUN_005b12c0  entry=005b12c0  size=100 bytes

void __thiscall FUN_005b12c0(int *param_1,int *param_2,int *param_3)

{
  int *piVar1;
  int iVar2;
  
  *param_1 = *param_2;
  param_1[1] = param_2[1];
  param_1[2] = param_2[2];
  piVar1 = param_1 + 3;
  *piVar1 = *param_3;
  param_1[4] = param_3[1];
  param_1[5] = param_3[2];
  iVar2 = *param_1;
  if (*piVar1 < iVar2) {
    *param_1 = *piVar1;
    *piVar1 = iVar2;
  }
  iVar2 = param_1[1];
  if (param_1[4] < iVar2) {
    param_1[1] = param_1[4];
    param_1[4] = iVar2;
  }
  iVar2 = param_1[2];
  if (param_1[5] < iVar2) {
    param_1[2] = param_1[5];
    param_1[5] = iVar2;
  }
  return;
}


