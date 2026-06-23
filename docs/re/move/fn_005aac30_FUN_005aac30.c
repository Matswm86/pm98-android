// FUN_005aac30  entry=005aac30  size=247 bytes

void __fastcall FUN_005aac30(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  int *piVar7;
  
  *(undefined4 *)(param_1 + 0x48) = 0;
  if (((*(int *)(param_1 + 0x40) != 0x13) && (*(int *)(param_1 + 0x40) != 0x1d)) &&
     (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40))) {
    iVar1 = *(int *)(param_1 + 0x20);
    iVar2 = *(int *)(param_1 + 0x28);
    iVar3 = *(int *)(param_1 + 0x24);
    piVar7 = (int *)FUN_005ee0f0(0x360000,*(undefined2 *)(param_1 + 0x34));
    iVar4 = piVar7[1];
    iVar5 = piVar7[2];
    *(int *)(param_1 + 0xa0) = *piVar7 + *(int *)(param_1 + 4);
    *(int *)(param_1 + 0xa4) = iVar4 + *(int *)(param_1 + 8);
    *(int *)(param_1 + 0xa8) = *(int *)(param_1 + 0xc) + iVar5;
    iVar4 = *(int *)(param_1 + 4);
    iVar5 = *(int *)(param_1 + 8);
    iVar6 = *(int *)(param_1 + 0xc);
    FUN_005a5430((-(*(int *)(param_1 + 700) == 0) & 0x1fU) + 5);
    *(undefined4 *)(param_1 + 0x80) = 1;
    *(undefined4 *)(param_1 + 0x84) = 0xc;
    *(int *)(param_1 + 0x94) = iVar1 * 0xc + iVar4;
    *(undefined2 *)(param_1 + 0x66) = *(undefined2 *)(param_1 + 0x34);
    *(int *)(param_1 + 0x98) = iVar3 * 0xc + iVar5;
    *(int *)(param_1 + 0x9c) = iVar2 * 0xc + iVar6;
  }
  return;
}


