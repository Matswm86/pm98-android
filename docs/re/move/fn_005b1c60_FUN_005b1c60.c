// FUN_005b1c60  entry=005b1c60  size=27 bytes

int __fastcall FUN_005b1c60(int param_1)

{
  uint uVar1;
  uint uVar2;
  
  if (param_1 != 0) {
    uVar1 = *(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 4);
    uVar2 = (int)uVar1 >> 0x1f;
    return (uVar1 ^ uVar2) - uVar2;
  }
  return 0xc80000;
}


