// FUN_0058e120  entry=0058e120  size=244 bytes

void __fastcall FUN_0058e120(int param_1)

{
  undefined1 uVar1;
  int iVar2;
  undefined4 *puVar3;
  undefined4 *puVar4;
  
  FUN_005ed870();
  if (DAT_006d31c4 == '\0') {
    FUN_005bbf10(param_1 + 0x1dc,0);
    *(undefined4 *)(param_1 + 0x1e0) = 0;
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined1 *)(param_1 + 99) = 0;
    *(undefined1 *)(param_1 + 100) = 0;
    if ((DAT_00674e7c == 8) || (*(int *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x468) + 0x14) == 0))
    {
      uVar1 = 0;
    }
    else {
      uVar1 = 1;
    }
    *(undefined1 *)(param_1 + 0x1d8) = uVar1;
    *(undefined1 *)(param_1 + 0x61) = 0;
    FUN_0058ed70();
    *(undefined4 *)(param_1 + 0x44) = 0;
    *(undefined4 *)(param_1 + 0x48) = 0;
    if (*(int *)(*(int *)(param_1 + 0x1d4) + 0x448) == 2) {
      *(undefined4 *)(param_1 + 0x90) = 0;
      *(undefined4 *)(param_1 + 0x94) = 0;
      *(undefined4 *)(param_1 + 0x98) = 0;
    }
    *(undefined4 *)(param_1 + 0x20) = 0;
    *(undefined4 *)(param_1 + 0x24) = 0;
    *(undefined4 *)(param_1 + 0x28) = 0;
    *(undefined4 *)(param_1 + 0x4c) = 0;
    *(undefined4 *)(param_1 + 0x50) = 0;
    *(undefined4 *)(param_1 + 4) = *(undefined4 *)(param_1 + 0x90);
    *(undefined1 *)(param_1 + 99) = 0;
    *(undefined4 *)(param_1 + 0x58) = 0xfffffffe;
    *(undefined4 *)(param_1 + 8) = *(undefined4 *)(param_1 + 0x94);
    *(undefined4 *)(param_1 + 0xc) = *(undefined4 *)(param_1 + 0x98);
    return;
  }
  if (param_1 != 0) {
    puVar3 = *(undefined4 **)(param_1 + 0x1dc);
    puVar4 = (undefined4 *)(param_1 + 0x40);
    for (iVar2 = 0x65; iVar2 != 0; iVar2 = iVar2 + -1) {
      *puVar4 = *puVar3;
      puVar3 = puVar3 + 1;
      puVar4 = puVar4 + 1;
    }
    return;
  }
  puVar3 = puRam000001dc;
  puVar4 = (undefined4 *)0x0;
  for (iVar2 = 0x65; iVar2 != 0; iVar2 = iVar2 + -1) {
    *puVar4 = *puVar3;
    puVar3 = puVar3 + 1;
    puVar4 = puVar4 + 1;
  }
  return;
}


