// FUN_0043c920  entry=0043c920  size=75 bytes

void __thiscall FUN_0043c920(int param_1,undefined4 param_2)

{
  undefined4 in_stack_00000018;
  undefined4 in_stack_0000001c;
  undefined4 uVar1;
  undefined4 uVar2;
  
  *(undefined4 *)(param_1 + 0x3f8) = in_stack_0000001c;
  *(undefined4 *)(param_1 + 0x3f4) = in_stack_00000018;
  uVar2 = 0xffffffff;
  uVar1 = in_stack_00000018;
  FUN_00436270(0xffffffff);
  FUN_005bc780(param_2,&stack0x00000008,&DAT_00666f70,0x800,0,uVar1,uVar2);
  return;
}


