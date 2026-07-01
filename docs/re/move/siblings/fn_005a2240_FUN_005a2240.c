// FUN_005a2240  entry=005a2240  size=104 bytes

void __fastcall FUN_005a2240(int param_1)

{
  int iVar1;
  
  FUN_00606220();
  iVar1 = *(int *)(param_1 + 0x18c);
  if (*(int *)(iVar1 + 0x19a0) != 4) {
    switch(*(undefined4 *)(iVar1 + 0x1a38)) {
    case 2:
      FUN_005a24b0();
      return;
    case 3:
    case 8:
      FUN_005a25d0();
      return;
    case 4:
      FUN_005a2560();
      return;
    case 5:
      if (*(char *)(iVar1 + 0x460) != '\0') {
        FUN_005a25d0();
        return;
      }
      goto LAB_005a22a1;
    }
  }
LAB_005a22a1:
  FUN_005a22d0();
  return;
}


