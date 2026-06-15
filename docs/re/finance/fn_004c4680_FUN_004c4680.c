// FUN_004c4680  entry=004c4680  size=36 bytes

void __thiscall FUN_004c4680(int param_1,char param_2)

{
  if (param_2 != '\0') {
    *(uint *)(param_1 + 0xac) = *(uint *)(param_1 + 0xac) | 8;
    return;
  }
  *(uint *)(param_1 + 0xac) = *(uint *)(param_1 + 0xac) & 0xfffffff7;
  return;
}


