// FUN_005b1260  entry=005b1260  size=81 bytes

void __fastcall FUN_005b1260(undefined4 *param_1)

{
  short sVar1;
  
  sVar1 = FUN_005ee080(*param_1,param_1[1]);
  FUN_005edfb0(*param_1,*(undefined4 *)(&DAT_006d31c8 + (sVar1 + 8 >> 4 & 0xfffU) * 4),param_1[1],
               *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar1 >> 4 & 0xfffU) * 4));
  return;
}


