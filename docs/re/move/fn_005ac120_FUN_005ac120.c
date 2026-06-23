// FUN_005ac120  entry=005ac120  size=115 bytes

undefined4 __thiscall FUN_005ac120(int param_1,uint *param_2)

{
  uint uVar1;
  bool bVar2;
  uint uVar3;
  
  uVar1 = *param_2;
  if ((*(int *)(*(int *)(param_1 + 0x18c) + 0x1820) + -0x160000 <
       (int)((uVar1 ^ (int)uVar1 >> 0x1f) - ((int)uVar1 >> 0x1f))) &&
     (uVar3 = (int)param_2[1] >> 0x1f, 0x1428f5 < (int)((param_2[1] ^ uVar3) - uVar3))) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  if ((bVar2) &&
     (((-1 < (int)uVar1) - 1 & 0xfffffffe) + 1 !=
      ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
    return 1;
  }
  return 0;
}


