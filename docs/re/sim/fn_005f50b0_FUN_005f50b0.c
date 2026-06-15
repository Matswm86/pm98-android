// FUN_005f50b0  entry=005f50b0  size=173 bytes
// callers/callees expanded one level from seeds

undefined4 * __thiscall
FUN_005f50b0(undefined4 *param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4)

{
  int iVar1;
  undefined4 *puVar2;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_00622673;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  param_1[0x16] = 0;
  param_1[0x17] = 0;
  param_1[1] = param_2;
  param_1[3] = param_4;
  param_1[2] = param_3;
  *param_1 = 0;
  param_1[4] = 0;
  local_4 = 1;
  param_1[5] = 0;
  param_1[6] = 0;
  *(undefined2 *)(param_1 + 7) = 0;
  puVar2 = param_1 + 8;
  for (iVar1 = 7; iVar1 != 0; iVar1 = iVar1 + -1) {
    *puVar2 = 0;
    puVar2 = puVar2 + 1;
  }
  puVar2 = param_1 + 0xf;
  for (iVar1 = 7; iVar1 != 0; iVar1 = iVar1 + -1) {
    *puVar2 = 0;
    puVar2 = puVar2 + 1;
  }
  iVar1 = param_1[3];
  param_1[0x18] = 0;
  param_1[0x19] = 0;
  FUN_005bbf10(param_1 + 0x16,iVar1 * 8);
  param_1[0x17] = iVar1;
  FUN_005f5600(param_1[2]);
  ExceptionList = local_c;
  return param_1;
}


