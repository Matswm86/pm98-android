// FUN_005b1330  entry=005b1330  size=137 bytes

void __thiscall FUN_005b1330(int *param_1,int *param_2,int *param_3)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  
  iVar1 = param_1[2];
  iVar2 = param_3[2];
  iVar5 = iVar2;
  if (iVar2 <= iVar1) {
    iVar5 = iVar1;
  }
  iVar4 = param_3[5];
  if ((iVar5 <= iVar4) && (iVar4 = iVar2, iVar2 <= iVar1)) {
    iVar4 = iVar1;
  }
  iVar1 = param_3[1];
  iVar2 = param_1[1];
  iVar5 = iVar1;
  if (iVar1 <= iVar2) {
    iVar5 = iVar2;
  }
  iVar3 = param_3[4];
  if ((iVar5 <= iVar3) && (iVar3 = iVar2, iVar2 < iVar1)) {
    iVar3 = iVar1;
  }
  iVar1 = *param_3;
  iVar2 = *param_1;
  iVar5 = iVar1;
  if (iVar1 <= iVar2) {
    iVar5 = iVar2;
  }
  if (iVar5 <= param_3[3]) {
    if (iVar2 < iVar1) {
      iVar2 = iVar1;
    }
    param_2[2] = iVar4;
    *param_2 = iVar2;
    param_2[1] = iVar3;
    return;
  }
  *param_2 = param_3[3];
  param_2[1] = iVar3;
  param_2[2] = iVar4;
  return;
}


