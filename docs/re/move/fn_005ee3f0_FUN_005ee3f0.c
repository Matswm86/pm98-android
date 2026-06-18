// FUN_005ee3f0  entry=005ee3f0  size=270 bytes

int * __thiscall FUN_005ee3f0(int *param_1,int *param_2,int param_3,int *param_4)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  bool bVar7;
  int iVar8;
  uint uVar9;
  uint uVar10;
  
  iVar1 = *param_2;
  uVar10 = *param_1 - iVar1;
  if ((((int)((uVar10 ^ (int)uVar10 >> 0x1f) - ((int)uVar10 >> 0x1f)) < param_3) &&
      (uVar9 = param_1[1] - param_2[1] >> 0x1f,
      (int)((param_1[1] - param_2[1] ^ uVar9) - uVar9) < param_3)) &&
     (uVar9 = param_1[2] - param_2[2] >> 0x1f,
     (int)((param_1[2] - param_2[2] ^ uVar9) - uVar9) < param_3)) {
    bVar7 = true;
  }
  else {
    bVar7 = false;
  }
  if (bVar7) {
    iVar2 = param_2[1];
    iVar3 = param_2[2];
    iVar4 = param_1[2];
    iVar5 = param_1[1];
    iVar8 = ftol();
    if (iVar8 < param_3) {
      iVar8 = param_4[1];
      iVar6 = param_4[2];
      *param_1 = *param_4 + (int)uVar10 / 2 + iVar1;
      param_1[1] = iVar8 + (iVar5 - iVar2) / 2 + iVar2;
      param_1[2] = iVar6 + (iVar4 - iVar3) / 2 + iVar3;
    }
  }
  return param_1;
}


