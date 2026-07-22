// FUN_004457a0  entry=004457a0  size=176 bytes

int FUN_004457a0(int param_1)

{
  if (0x4f < param_1) {
    return 0;
  }
  if ((0x4b < param_1) && (param_1 < 0x50)) {
    return 1;
  }
  if ((0x47 < param_1) && (param_1 < 0x4c)) {
    return 2;
  }
  if ((0x43 < param_1) && (param_1 < 0x48)) {
    return 3;
  }
  if ((0x3f < param_1) && (param_1 < 0x44)) {
    return 4;
  }
  if ((0x3b < param_1) && (param_1 < 0x40)) {
    return 5;
  }
  if ((0x37 < param_1) && (param_1 < 0x3c)) {
    return 6;
  }
  if ((0x35 < param_1) && (param_1 < 0x38)) {
    return 7;
  }
  if ((0x33 < param_1) && (param_1 < 0x36)) {
    return 8;
  }
  return ((0x33 < param_1) - 1 & 10) - 1;
}


