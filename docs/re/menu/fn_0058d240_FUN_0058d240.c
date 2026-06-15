// FUN_0058d240  entry=0058d240  size=44 bytes

undefined4 __thiscall FUN_0058d240(int *param_1,int param_2)

{
  FUN_0058cf60(param_2);
  if ((-1 < param_2) && (param_2 < param_1[1])) {
    return *(undefined4 *)(*param_1 + param_2 * 8);
  }
  return uRam00000000;
}


