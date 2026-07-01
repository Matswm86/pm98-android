// FUN_00590b30  entry=00590b30  size=109 bytes

undefined4 __thiscall FUN_00590b30(int *param_1,int *param_2)

{
  int iVar1;
  int iVar2;
  
  iVar2 = *param_1;
  if (*param_1 <= *param_2) {
    iVar2 = *param_2;
  }
  iVar1 = param_1[3];
  if (param_2[3] <= param_1[3]) {
    iVar1 = param_2[3];
  }
  if (iVar2 < iVar1) {
    iVar2 = param_1[1];
    if (param_1[1] <= param_2[1]) {
      iVar2 = param_2[1];
    }
    iVar1 = param_1[4];
    if (param_2[4] <= param_1[4]) {
      iVar1 = param_2[4];
    }
    if (iVar2 < iVar1) {
      iVar2 = param_1[2];
      if (param_1[2] <= param_2[2]) {
        iVar2 = param_2[2];
      }
      iVar1 = param_2[5];
      if (param_1[5] < param_2[5]) {
        iVar1 = param_1[5];
      }
      if (iVar2 < iVar1) {
        return 1;
      }
    }
  }
  return 0;
}


