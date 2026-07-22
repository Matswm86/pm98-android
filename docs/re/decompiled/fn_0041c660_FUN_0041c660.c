// FUN_0041c660  entry=0041c660  size=68 bytes

int FUN_0041c660(int param_1)

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
  return ((0x47 < param_1) - 1 & 4) - 1;
}


