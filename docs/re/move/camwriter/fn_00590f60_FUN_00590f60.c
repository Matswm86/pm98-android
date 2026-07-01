// FUN_00590f60  entry=00590f60  size=93 bytes

void __thiscall FUN_00590f60(int param_1,uint param_2)

{
  if (*(int *)(param_1 + 0x10) != 0) {
    if (DAT_00674e78 == 1) {
      param_2 = ((param_2 & 0xff) * 0x4b) / 100 & 0xff;
    }
    if (*(char *)(param_1 + 8) != '\0') {
      FUN_005e0970(param_2);
      return;
    }
    FUN_005e0bf0(param_2);
  }
  return;
}


