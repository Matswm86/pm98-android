// FUN_005a4560  entry=005a4560  size=148 bytes

void __fastcall FUN_005a4560(int param_1)

{
  int iVar1;
  int iVar2;
  undefined4 *puVar3;
  undefined4 *puVar4;
  
  FUN_005ed8e0();
  if (DAT_006d31bc == 0) {
    if (DAT_006d31c4 != '\0') {
      if (param_1 == 0) {
        puVar4 = (undefined4 *)0x0;
      }
      else {
        puVar4 = (undefined4 *)(param_1 + 0x40);
      }
      puVar3 = (undefined4 *)(*(int *)(param_1 + 0x3b0) + DAT_006d31c0 * 0x144);
      for (iVar1 = 0x51; iVar1 != 0; iVar1 = iVar1 + -1) {
        *puVar4 = *puVar3;
        puVar3 = puVar3 + 1;
        puVar4 = puVar4 + 1;
      }
      return;
    }
    if (DAT_00665d8c != '\0') {
      if (param_1 == 0) {
        puVar4 = (undefined4 *)0x0;
      }
      else {
        puVar4 = (undefined4 *)(param_1 + 0x40);
      }
      iVar1 = *(int *)(param_1 + 0x3b4) + 1;
      iVar2 = iVar1 * 0x144;
      FUN_005bbf10((int *)(param_1 + 0x3b0),iVar2);
      *(int *)(param_1 + 0x3b4) = iVar1;
      puVar3 = (undefined4 *)(*(int *)(param_1 + 0x3b0) + -0x144 + iVar2);
      for (iVar1 = 0x51; iVar1 != 0; iVar1 = iVar1 + -1) {
        *puVar3 = *puVar4;
        puVar4 = puVar4 + 1;
        puVar3 = puVar3 + 1;
      }
    }
  }
  return;
}


