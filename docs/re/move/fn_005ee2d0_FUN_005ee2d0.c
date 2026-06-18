// FUN_005ee2d0  entry=005ee2d0  size=285 bytes

int * __thiscall FUN_005ee2d0(int *param_1,int *param_2,int param_3)

{
  int iVar1;
  int iVar2;
  int iVar3;
  bool bVar4;
  int iVar5;
  int *piVar6;
  uint uVar7;
  
  uVar7 = *param_1 - *param_2 >> 0x1f;
  if ((((int)((*param_1 - *param_2 ^ uVar7) - uVar7) < param_3) &&
      (uVar7 = param_1[1] - param_2[1] >> 0x1f,
      (int)((param_1[1] - param_2[1] ^ uVar7) - uVar7) < param_3)) &&
     (uVar7 = param_1[2] - param_2[2] >> 0x1f,
     (int)((param_1[2] - param_2[2] ^ uVar7) - uVar7) < param_3)) {
    bVar4 = true;
  }
  else {
    bVar4 = false;
  }
  if (bVar4) {
    iVar5 = ftol();
    if (iVar5 < param_3) {
      if (iVar5 != 0) {
        piVar6 = (int *)FUN_005ee290(param_3,iVar5);
        iVar5 = param_2[1];
        iVar1 = param_2[2];
        iVar2 = piVar6[1];
        iVar3 = piVar6[2];
        *param_1 = *piVar6 + *param_2;
        param_1[1] = iVar2 + iVar5;
        param_1[2] = iVar3 + iVar1;
        return param_1;
      }
      piVar6 = (int *)FUN_005ee0f0(param_3,0);
      *param_1 = *param_1 + *piVar6;
      param_1[1] = param_1[1] + piVar6[1];
      param_1[2] = param_1[2] + piVar6[2];
    }
  }
  return param_1;
}


