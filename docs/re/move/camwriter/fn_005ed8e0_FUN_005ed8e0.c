// FUN_005ed8e0  entry=005ed8e0  size=184 bytes

void __fastcall FUN_005ed8e0(int param_1)

{
  undefined4 *puVar1;
  int iVar2;
  int iVar3;
  undefined4 *puVar4;
  
  if (DAT_006d31bc == 0) {
    if (DAT_006d31c4 != '\0') {
      puVar1 = (undefined4 *)(*(int *)(param_1 + 0x38) + DAT_006d31c0 * 0x24);
      *(undefined4 *)(param_1 + 4) = *puVar1;
      *(undefined4 *)(param_1 + 8) = puVar1[1];
      *(undefined4 *)(param_1 + 0xc) = puVar1[2];
      *(undefined4 *)(param_1 + 0x20) = puVar1[3];
      *(undefined4 *)(param_1 + 0x24) = puVar1[4];
      *(undefined4 *)(param_1 + 0x28) = puVar1[5];
      *(undefined4 *)(param_1 + 0x2c) = puVar1[6];
      *(undefined4 *)(param_1 + 0x30) = puVar1[7];
      *(undefined2 *)(param_1 + 0x34) = *(undefined2 *)(puVar1 + 8);
      return;
    }
    if (DAT_00665d8c != '\0') {
      puVar1 = (undefined4 *)FUN_005ed820(param_1);
      iVar3 = *(int *)(param_1 + 0x3c) + 1;
      iVar2 = iVar3 * 0x24;
      FUN_005bbf10((int *)(param_1 + 0x38),iVar2);
      *(int *)(param_1 + 0x3c) = iVar3;
      puVar4 = (undefined4 *)(*(int *)(param_1 + 0x38) + -0x24 + iVar2);
      for (iVar3 = 9; iVar3 != 0; iVar3 = iVar3 + -1) {
        *puVar4 = *puVar1;
        puVar1 = puVar1 + 1;
        puVar4 = puVar4 + 1;
      }
    }
  }
  return;
}


