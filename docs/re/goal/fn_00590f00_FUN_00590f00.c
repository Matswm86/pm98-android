// FUN_00590f00  entry=00590f00  size=55 bytes

void __fastcall FUN_00590f00(int param_1)

{
  if (*(int *)(param_1 + 0x10) != 0) {
    if (*(char *)(param_1 + 8) != '\0') {
      FUN_005e08e0(*(int *)(param_1 + 0xc) == 0);
      return;
    }
    FUN_005e0ba0(*(int *)(param_1 + 0xc) == 0,0);
  }
  return;
}


