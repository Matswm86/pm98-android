// FUN_00581c80  entry=00581c80  size=233 bytes

int __thiscall FUN_00581c80(int param_1,undefined2 param_2)

{
  undefined1 *puVar1;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_0062005e;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_004484d0();
  *(undefined1 *)(param_1 + 0x68) = 0;
  *(undefined1 *)(param_1 + 0x69) = 0;
  *(undefined1 *)(param_1 + 0x6a) = 0;
  *(undefined1 *)(param_1 + 0x6b) = 0;
  FUN_00576ca0();
  *(undefined4 *)(param_1 + 0x8c) = 0;
  *(undefined4 *)(param_1 + 0x90) = 0;
  *(undefined2 *)(param_1 + 0x94) = 0;
  *(undefined1 *)(param_1 + 0x96) = 0;
  *(undefined1 *)(param_1 + 0xb5) = 0;
  *(undefined4 *)(param_1 + 0xf0) = 0;
  *(undefined4 *)(param_1 + 0xf4) = 0;
  *(undefined1 *)(param_1 + 0xfe) = 0;
  *(undefined1 *)(param_1 + 0xff) = 0;
  *(undefined2 *)(param_1 + 0xfc) = 0;
  *(undefined2 *)(param_1 + 0x14) = param_2;
  *(undefined2 *)(param_1 + 2) = param_2;
  *(undefined4 *)(param_1 + 0x100) = 0;
  *(undefined4 *)(param_1 + 0x10) = 0;
  *(undefined4 *)(param_1 + 0x1d) = 0x63636363;
  *(undefined2 *)(param_1 + 0x21) = 0x6363;
  *(undefined1 *)(param_1 + 0xa7) = 99;
  *(undefined1 *)(param_1 + 0xb4) = 99;
  *(undefined4 *)(param_1 + 0x88) = 0;
  *(undefined2 *)(param_1 + 0x9a) = 1000;
  *(undefined1 *)(param_1 + 0xa9) = 0;
  puVar1 = (undefined1 *)(param_1 + 0xc4);
  do {
    puVar1[-0xe] = 0;
    *puVar1 = 0;
    puVar1 = puVar1 + 1;
  } while (puVar1 + (-0xc4 - param_1) < (undefined1 *)0xe);
  ExceptionList = local_c;
  return param_1;
}


