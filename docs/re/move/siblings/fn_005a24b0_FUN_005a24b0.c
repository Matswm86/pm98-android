// FUN_005a24b0  entry=005a24b0  size=165 bytes

void __fastcall FUN_005a24b0(int param_1)

{
  int iVar1;
  int iVar2;
  
  if (*(int *)(param_1 + 0x3c0) != 0) {
    FUN_005a22d0();
    return;
  }
  if (*(int *)(param_1 + 0x3bc) == 1) {
    *(undefined2 *)(param_1 + 0x34) = 0x4000;
  }
  else {
    *(undefined2 *)(param_1 + 0x34) = 0xc000;
  }
  iVar2 = *(int *)(param_1 + 0x3c4);
  if (iVar2 == 0) {
    iVar2 = 0x44;
  }
  else {
    if (iVar2 != 1) {
      if (iVar2 != 2) {
        return;
      }
      FUN_005a50c0();
      return;
    }
    FUN_005a50c0();
    if (*(int *)(param_1 + 0x40) != 0x42) {
      return;
    }
    iVar2 = *(int *)(param_1 + 0x18c);
    iVar1 = *(int *)(iVar2 + 0x1820);
    if ((*(uint *)(iVar2 + 0x19a0) & 1) == *(uint *)(iVar2 + 0x45c)) {
      iVar1 = -iVar1;
    }
    iVar2 = 0x46 - (uint)((*(int *)(param_1 + 0x3bc) == 1) != iVar1 < 0);
  }
  FUN_005a5430(iVar2);
  *(int *)(param_1 + 0x3c4) = *(int *)(param_1 + 0x3c4) + 1;
  return;
}


