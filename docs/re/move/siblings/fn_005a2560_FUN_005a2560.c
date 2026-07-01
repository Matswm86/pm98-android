// FUN_005a2560  entry=005a2560  size=103 bytes

void __fastcall FUN_005a2560(int param_1)

{
  int iVar1;
  undefined4 uVar2;
  
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
  iVar1 = *(int *)(param_1 + 0x3c4);
  if (iVar1 == 0) {
    uVar2 = 0x44;
  }
  else {
    if (iVar1 != 1) {
      if (iVar1 != 2) {
        return;
      }
      FUN_005a50c0();
      return;
    }
    FUN_005a50c0();
    if (*(int *)(param_1 + 0x40) != 0x42) {
      return;
    }
    uVar2 = 0x47;
  }
  FUN_005a5430(uVar2);
  *(int *)(param_1 + 0x3c4) = *(int *)(param_1 + 0x3c4) + 1;
  return;
}


