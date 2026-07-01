// FUN_00590f40  entry=00590f40  size=27 bytes

void __fastcall FUN_00590f40(int param_1)

{
  if (*(int *)(param_1 + 0x10) == 0) {
    return;
  }
  if (*(char *)(param_1 + 8) != '\0') {
    FUN_005e0920();
    return;
  }
  FUN_005e0be0();
  return;
}


