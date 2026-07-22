// FUN_0042ed60  entry=0042ed60  size=53 bytes

int FUN_0042ed60(int param_1)

{
  if (0x31 < param_1) {
    return 10;
  }
  if ((0x2f < param_1) && (param_1 < 0x32)) {
    return 0xb;
  }
  return ((0x2f < param_1) - 1 & 0xd) - 1;
}


