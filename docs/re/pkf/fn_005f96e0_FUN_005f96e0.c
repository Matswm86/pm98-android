// FUN_005f96e0  entry=005f96e0  size=48 bytes

undefined4 FUN_005f96e0(uint param_1,uint param_2,uint param_3,undefined4 param_4)

{
  undefined4 uVar1;
  
  if (param_1 <= param_3) {
    if (param_3 - param_1 < param_2) {
      uVar1 = FUN_005f9660(param_3,param_2 - (param_3 - param_1),param_4);
      return uVar1;
    }
  }
  return 0;
}


