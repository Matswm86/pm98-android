// FUN_0055e380  entry=0055e380  size=84 bytes

int __fastcall FUN_0055e380(int param_1)

{
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0061ded6;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_0044bdc0();
  *(undefined4 *)(param_1 + 0x94) = 0;
  *(undefined4 *)(param_1 + 0x98) = 0;
  local_4 = 1;
  FUN_0058b2b0();
  ExceptionList = local_c;
  return param_1;
}


