// FUN_005a2140  entry=005a2140  size=235 bytes

void __fastcall FUN_005a2140(int param_1)

{
  int iVar1;
  int iVar2;
  undefined4 *puVar3;
  undefined4 *puVar4;
  
  FUN_005ed870();
  iVar1 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1a5c);
  *(undefined4 *)(param_1 + 0x3c0) = 0;
  *(uint *)(param_1 + 0x2dc) = iVar1 + ((*(int *)(param_1 + 0x3bc) != 1) + 5) * 0x100;
  *(undefined4 *)(param_1 + 0x3c4) = 0;
  if (DAT_006d31c4 != '\0') {
    if (param_1 != 0) {
      puVar3 = *(undefined4 **)(param_1 + 0x3b0);
      puVar4 = (undefined4 *)(param_1 + 0x40);
      for (iVar1 = 0x51; iVar1 != 0; iVar1 = iVar1 + -1) {
        *puVar4 = *puVar3;
        puVar3 = puVar3 + 1;
        puVar4 = puVar4 + 1;
      }
      return;
    }
    puVar3 = puRam000003b0;
    puVar4 = (undefined4 *)0x0;
    for (iVar1 = 0x51; iVar1 != 0; iVar1 = iVar1 + -1) {
      *puVar4 = *puVar3;
      puVar3 = puVar3 + 1;
      puVar4 = puVar4 + 1;
    }
    return;
  }
  FUN_005bbf10(param_1 + 0x3b0,0);
  *(undefined4 *)(param_1 + 0x3b4) = 0;
  *(undefined4 *)(param_1 + 4) = 0;
  *(undefined4 *)(param_1 + 8) = 0;
  *(undefined4 *)(param_1 + 0xc) = 0;
  FUN_005a5430(0x42);
  iVar1 = *(int *)(param_1 + 0x18c);
  if (*(int *)(param_1 + 0x3bc) == 1) {
    iVar2 = -0x10000 - *(int *)(iVar1 + 0x1824);
  }
  else {
    iVar2 = *(int *)(iVar1 + 0x1824) + 0x10000;
  }
  *(int *)(param_1 + 8) = iVar2;
  if (*(int *)(param_1 + 0x3bc) == 1) {
    *(int *)(param_1 + 4) = *(int *)(iVar1 + 0x1820) / 2;
    return;
  }
  *(int *)(param_1 + 4) = -(*(int *)(iVar1 + 0x1820) / 2);
  return;
}


