// FUN_00544c9f  entry=00544c9f  size=147 bytes

void __thiscall FUN_00544c9f(undefined4 param_1)

{
  int in_EAX;
  undefined4 uVar1;
  undefined4 *puVar2;
  undefined4 in_stack_0000001c;
  
  FUN_004ca3c0(PTR_DAT_00662d08,param_1,*(undefined4 *)(in_EAX + 4),*(undefined4 *)(in_EAX + 8),
               *(undefined4 *)(in_EAX + 0xc));
  puVar2 = &stack0x0000001c;
  uVar1 = FUN_00436fb0(5,DAT_0066bd8c);
  puVar2 = (undefined4 *)FUN_00436fd0(uVar1,puVar2);
  FUN_004ca3c0(PTR_PTR_00662d0c,*puVar2,puVar2[1],puVar2[2],puVar2[3]);
  return;
}


