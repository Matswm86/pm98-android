// FUN_005942e0  entry=005942e0  size=33 bytes

void __thiscall FUN_005942e0(int param_1,int param_2)

{
  if (*(int *)(param_1 + 0x448) != 8) {
    *(int *)(param_1 + 0x448) = param_2;
    if (param_2 != 1) {
      *(int *)(param_1 + 0x44c) = param_2;
    }
  }
  return;
}


