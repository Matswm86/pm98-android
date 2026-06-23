// FUN_005ac0e0  entry=005ac0e0  size=64 bytes

undefined4 __thiscall FUN_005ac0e0(int param_1,uint *param_2)

{
  uint uVar1;
  
  uVar1 = (int)*param_2 >> 0x1f;
  if ((*(int *)(*(int *)(param_1 + 0x18c) + 0x1820) + -0x160000 < (int)((*param_2 ^ uVar1) - uVar1))
     && (uVar1 = (int)param_2[1] >> 0x1f, 0x1428f5 < (int)((param_2[1] ^ uVar1) - uVar1))) {
    return 1;
  }
  return 0;
}


