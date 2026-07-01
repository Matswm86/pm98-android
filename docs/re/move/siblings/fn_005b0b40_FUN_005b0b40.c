// FUN_005b0b40  entry=005b0b40  size=110 bytes

int __thiscall FUN_005b0b40(int param_1,int param_2)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  int iVar6;
  int iVar7;
  
  if (param_1 == 0) {
    iVar2 = 0xc80000;
  }
  else {
    uVar1 = *(int *)(param_1 + 4) + *(int *)(param_1 + 0x3a4);
    uVar5 = (int)uVar1 >> 0x1f;
    iVar2 = (uVar1 ^ uVar5) - uVar5;
  }
  iVar6 = 0;
  iVar7 = (*(int **)(param_1 + 0x188))[1];
  iVar4 = **(int **)(param_1 + 0x188);
  while (iVar7 != 0) {
    iVar7 = iVar7 + -1;
    if (iVar4 == 0) {
      iVar3 = 0xc80000;
    }
    else {
      uVar1 = *(int *)(iVar4 + 4) - *(int *)(iVar4 + 0x3a4);
      uVar5 = (int)uVar1 >> 0x1f;
      iVar3 = (uVar1 ^ uVar5) - uVar5;
    }
    if (iVar3 < param_2 + iVar2) {
      iVar6 = iVar6 + 1;
    }
    iVar4 = iVar4 + 0x3bc;
  }
  return iVar6;
}


