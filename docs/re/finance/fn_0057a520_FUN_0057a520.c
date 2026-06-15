// FUN_0057a520  entry=0057a520  size=34 bytes

undefined4 __fastcall FUN_0057a520(int param_1)

{
  undefined4 uVar1;
  
  if (*(uint *)(param_1 + 0x50) < 4) {
    uVar1 = (**(code **)(*(int *)(&DAT_0066b190)[*(uint *)(param_1 + 0x50)] + 0xc4))
                      (*(undefined4 *)(param_1 + 0x10));
    return uVar1;
  }
  return 1;
}


