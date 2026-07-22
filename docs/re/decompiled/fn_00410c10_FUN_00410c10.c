// FUN_00410c10  entry=00410c10  size=53 bytes

int FUN_00410c10(int param_1)

{
  if (0x3f < param_1) {
    return 4;
  }
  if ((0x3b < param_1) && (param_1 < 0x40)) {
    return 5;
  }
  return ((0x3b < param_1) - 1 & 7) - 1;
}


