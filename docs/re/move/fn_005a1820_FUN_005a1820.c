// FUN_005a1820  entry=005a1820  size=79 bytes

undefined4 __thiscall FUN_005a1820(int *param_1,int *param_2,int param_3,int param_4,int param_5)

{
  uint uVar1;
  
  uVar1 = *param_1 - *param_2 >> 0x1f;
  if ((((int)((*param_1 - *param_2 ^ uVar1) - uVar1) < param_3) &&
      (uVar1 = param_1[1] - param_2[1] >> 0x1f,
      (int)((param_1[1] - param_2[1] ^ uVar1) - uVar1) < param_4)) &&
     (uVar1 = param_1[2] - param_2[2] >> 0x1f,
     (int)((param_1[2] - param_2[2] ^ uVar1) - uVar1) < param_5)) {
    return 1;
  }
  return 0;
}


