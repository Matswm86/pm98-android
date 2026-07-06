// FUN_0058c900  entry=0058c900  size=134 bytes

undefined4 __thiscall FUN_0058c900(int *param_1,undefined4 param_2,uint param_3)

{
  int local_8;
  int local_4;
  
  FUN_0058c7b0();
  if ((param_3 & 0x90) != 0) {
    FUN_005eaf80(&local_8,param_2,0,param_1 + 2,0,param_3 & 0x200);
    param_1[1] = local_8;
    *param_1 = local_8;
    param_1[5] = local_4;
    if (local_8 != 0) {
      param_1[3] = param_3 | 1;
      return 1;
    }
    param_1[2] = 0;
  }
  return 0;
}


