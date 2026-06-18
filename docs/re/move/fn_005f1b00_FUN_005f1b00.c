// FUN_005f1b00  entry=005f1b00  size=37 bytes

void __thiscall FUN_005f1b00(int param_1,int param_2)

{
  if (*(int *)(param_1 + 0x130) != param_2) {
    *(int *)(param_1 + 0x130) = param_2;
    *(undefined1 *)(param_1 + 0x138) = 0;
    *(undefined1 *)(param_1 + 0x139) = 0;
  }
  return;
}


