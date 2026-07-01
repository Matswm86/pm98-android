// FUN_005a7220  entry=005a7220  size=61 bytes

void __thiscall
FUN_005a7220(int param_1,int param_2,undefined4 param_3,undefined4 *param_4,undefined2 param_5)

{
  *(undefined4 *)(param_1 + 0x84) = param_3;
  *(int *)(param_1 + 0x80) = param_2 + 1;
  *(undefined4 *)(param_1 + 0x94) = *param_4;
  *(undefined4 *)(param_1 + 0x98) = param_4[1];
  *(undefined4 *)(param_1 + 0x9c) = param_4[2];
  *(undefined2 *)(param_1 + 0x66) = param_5;
  return;
}


