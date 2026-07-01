// FUN_0058e220  entry=0058e220  size=158 bytes

void __fastcall FUN_0058e220(int param_1)

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
      puVar3 = (undefined4 *)(*(int *)(param_1 + 0x1dc) + DAT_006d31c0 * 0x194);
      for (iVar1 = 0x65; iVar1 != 0; iVar1 = iVar1 + -1) {
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
      iVar1 = *(int *)(param_1 + 0x1e0) + 1;
      iVar2 = iVar1 * 0x194;
      FUN_005bbf10((int *)(param_1 + 0x1dc),iVar2);
      *(int *)(param_1 + 0x1e0) = iVar1;
      puVar3 = (undefined4 *)(*(int *)(param_1 + 0x1dc) + -0x194 + iVar2);
      for (iVar1 = 0x65; iVar1 != 0; iVar1 = iVar1 + -1) {
        *puVar3 = *puVar4;
        puVar4 = puVar4 + 1;
        puVar3 = puVar3 + 1;
      }
    }
  }
  return;
}


