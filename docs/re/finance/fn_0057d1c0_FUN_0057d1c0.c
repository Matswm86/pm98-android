// FUN_0057d1c0  entry=0057d1c0  size=34 bytes

undefined4 __fastcall FUN_0057d1c0(int param_1)

{
  undefined4 uVar1;
  
  if (*(uint *)(param_1 + 0x50) < 4) {
    uVar1 = (**(code **)(*(int *)(&DAT_0066b190)[*(uint *)(param_1 + 0x50)] + 0x84))
                      (*(undefined2 *)(param_1 + 0x10));
    return uVar1;
  }
  return 0;
}


