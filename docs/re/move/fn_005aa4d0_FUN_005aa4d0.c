// FUN_005aa4d0  entry=005aa4d0  size=429 bytes

void __fastcall FUN_005aa4d0(int param_1)

{
  short sVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  short sVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  int iVar13;
  
  if (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40)) {
    if ((*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 2) &&
       (*(char *)(*(int *)(param_1 + 0x18c) + 0x180a) != '\0')) {
      FUN_00590f00();
    }
    *(undefined4 *)(param_1 + 0x48) = 0;
    if ((*(int *)(param_1 + 0x40) != 0x13) && (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) != 4)) {
      iVar10 = *(int *)(param_1 + 0xb4);
      if ((iVar10 == 0) && (iVar10 = FUN_005aa680(), iVar10 == 0)) {
        return;
      }
      iVar13 = *(int *)(param_1 + 0x20) * 6;
      iVar12 = *(int *)(param_1 + 0x24) * 6;
      sVar1 = *(short *)(param_1 + 0xb8 +
                        (*(int *)(iVar10 + 0x2b8) * 0xb + *(int *)(iVar10 + 0x2c4)) * 2);
      iVar2 = *(int *)(param_1 + 4);
      iVar3 = *(int *)(param_1 + 8);
      iVar11 = *(int *)(param_1 + 0x28) * 6;
      iVar4 = *(int *)(param_1 + 0xc);
      iVar5 = *(int *)(param_1 + 400);
      iVar6 = *(int *)(iVar5 + 4);
      iVar7 = *(int *)(iVar5 + 8);
      iVar8 = *(int *)(iVar5 + 0xc);
      *(int *)(iVar5 + 0x4c) = iVar10;
      *(undefined4 *)(param_1 + 0xa0) = *(undefined4 *)(iVar10 + 4);
      *(undefined4 *)(param_1 + 0xa4) = *(undefined4 *)(iVar10 + 8);
      *(undefined4 *)(param_1 + 0xa8) = *(undefined4 *)(iVar10 + 0xc);
      FUN_005a5430((-(*(int *)(param_1 + 700) == 0) & 0x21U) + 4);
      sVar9 = *(short *)(param_1 + 0x34);
      if (*(int *)(param_1 + 0xb4) != 0) {
        sVar9 = sVar9 + sVar1;
      }
      *(short *)(param_1 + 0x66) = sVar9;
      iVar10 = *(int *)(param_1 + 400);
      *(int *)(param_1 + 0x94) = iVar13 + iVar2;
      *(undefined4 *)(param_1 + 0x80) = 1;
      *(undefined4 *)(param_1 + 0x84) = 8;
      *(int *)(param_1 + 0x98) = iVar12 + iVar3;
      *(int *)(param_1 + 0x9c) = iVar11 + iVar4;
      *(undefined4 *)(iVar10 + 0x68) = 1;
      *(undefined4 *)(iVar10 + 0x6c) = 8;
      *(int *)(iVar10 + 0x9c) = iVar13 + iVar6;
      *(int *)(iVar10 + 0xa0) = iVar12 + iVar7;
      *(int *)(iVar10 + 0xa4) = iVar11 + iVar8;
      *(undefined4 *)(param_1 + 0xb4) = 0;
    }
  }
  return;
}


