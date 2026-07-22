// FUN_00451b30  entry=00451b30  size=277 bytes

undefined4 * __thiscall FUN_00451b30(undefined4 *param_1,undefined4 param_2)

{
  undefined4 *puVar1;
  int iVar2;
  void *local_c;
  undefined1 *puStack_8;
  undefined1 local_4;
  undefined3 uStack_3;
  
  puStack_8 = &LAB_00609e0b;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = &PTR_LAB_006234d8;
  param_1[5] = 0;
  param_1[6] = 0;
  param_1[7] = 0;
  param_1[8] = 0;
  param_1[9] = 0;
  param_1[10] = 0;
  param_1[0xb] = 0;
  param_1[0xc] = 0;
  param_1[0xd] = 0;
  param_1[0xe] = 0;
  param_1[0xf] = 0;
  param_1[0x11] = 0;
  param_1[0x12] = 0;
  param_1[0x13] = 0;
  local_4 = 10;
  uStack_3 = 0;
  FUN_00605ee0(param_1 + 0x15,8,6,&LAB_00442d50,FUN_004ec5c0);
  param_1[0x2d] = 0;
  param_1[0x2e] = 0;
  local_4 = 0xd;
  FUN_00605ee0(param_1 + 0x2f,8,6,&LAB_00442810,FUN_00410a50);
  _local_4 = CONCAT31(uStack_3,0xe);
  puVar1 = param_1 + 0x3b;
  iVar2 = 6;
  do {
    *(undefined1 *)((int)puVar1 + 2) = 0;
    *(undefined1 *)((int)puVar1 + 3) = 0;
    *(undefined2 *)puVar1 = 0;
    puVar1 = puVar1 + 1;
    iVar2 = iVar2 + -1;
  } while (iVar2 != 0);
  puVar1 = param_1 + 0x41;
  iVar2 = 6;
  do {
    *(undefined1 *)((int)puVar1 + 2) = 0;
    *(undefined1 *)((int)puVar1 + 3) = 0;
    *(undefined2 *)puVar1 = 0;
    puVar1 = puVar1 + 1;
    iVar2 = iVar2 + -1;
  } while (iVar2 != 0);
  puVar1 = param_1 + 0x47;
  iVar2 = 6;
  do {
    *(undefined1 *)((int)puVar1 + 2) = 0;
    *(undefined1 *)((int)puVar1 + 3) = 0;
    *(undefined2 *)puVar1 = 0;
    puVar1 = puVar1 + 1;
    iVar2 = iVar2 + -1;
  } while (iVar2 != 0);
  *param_1 = &PTR_LAB_00627300;
  FUN_004519f0(param_2);
  ExceptionList = local_c;
  return param_1;
}


