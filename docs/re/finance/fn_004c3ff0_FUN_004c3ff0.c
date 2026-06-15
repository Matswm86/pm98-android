// FUN_004c3ff0  entry=004c3ff0  size=24 bytes

undefined4 __thiscall FUN_004c3ff0(uint *param_1,uint param_2)

{
  if (param_2 < *param_1) {
    return *(undefined4 *)(param_1[2] + param_2 * 4);
  }
  return 0;
}


