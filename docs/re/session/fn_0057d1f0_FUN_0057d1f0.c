// FUN_0057d1f0  entry=0057d1f0  size=32 bytes

int __fastcall FUN_0057d1f0(int param_1)

{
  if (*(int *)(param_1 + 0x5c) != 0xffff) {
    return DAT_0066c178 + *(int *)(param_1 + 0x5c) * 0x9c;
  }
  return *(int *)(param_1 + 0x2c);
}


