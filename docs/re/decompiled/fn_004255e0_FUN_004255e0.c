// FUN_004255e0  entry=004255e0  size=53 bytes

int FUN_004255e0(int param_1)

{
  if (0x35 < param_1) {
    return 7;
  }
  if ((0x33 < param_1) && (param_1 < 0x36)) {
    return 8;
  }
  return ((0x33 < param_1) - 1 & 10) - 1;
}


