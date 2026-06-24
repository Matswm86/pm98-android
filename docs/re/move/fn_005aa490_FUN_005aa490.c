// FUN_005aa490  entry=005aa490  size=50 bytes

void __thiscall FUN_005aa490(int param_1,undefined4 param_2,undefined1 param_3,undefined1 param_4)

{
  if (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40)) {
    *(undefined4 *)(param_1 + 0xb4) = param_2;
    *(undefined1 *)(param_1 + 0x5e) = param_3;
    *(undefined1 *)(param_1 + 0x5f) = param_4;
    FUN_005aa4d0();
  }
  return;
}


