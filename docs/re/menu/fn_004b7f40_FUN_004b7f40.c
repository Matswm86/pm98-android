// FUN_004b7f40  entry=004b7f40  size=18 bytes

void __thiscall FUN_004b7f40(int param_1,undefined4 *param_2)

{
  undefined4 uVar1;
  
  uVar1 = *(undefined4 *)(param_1 + 0x18);
  *param_2 = *(undefined4 *)(param_1 + 0x14);
  param_2[1] = uVar1;
  return;
}


