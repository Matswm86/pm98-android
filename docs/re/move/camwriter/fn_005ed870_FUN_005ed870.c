// FUN_005ed870  entry=005ed870  size=103 bytes

void __fastcall FUN_005ed870(int param_1)

{
  undefined4 *puVar1;
  
  if (DAT_006d31c4 != '\0') {
    puVar1 = *(undefined4 **)(param_1 + 0x38);
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
  FUN_005bbf10(param_1 + 0x38,0);
  *(undefined4 *)(param_1 + 0x3c) = 0;
  return;
}


