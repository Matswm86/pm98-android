// FUN_00469f60  entry=00469f60  size=422 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_00469f60(undefined4 *param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_0060adce;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = &PTR_LAB_00627c50;
  local_4 = 2;
  FUN_00491900();
  local_4._0_1_ = 7;
  FUN_005bc6a0();
  local_4._0_1_ = 6;
  FUN_005bc6a0();
  local_4._0_1_ = 5;
  FUN_005bc6a0();
  local_4._0_1_ = 4;
  FUN_005bc6a0();
  local_4._0_1_ = 3;
  FUN_005bc6a0();
  local_4._0_1_ = 1;
  FUN_005bc6a0();
  local_4._0_1_ = 10;
  operator_delete((void *)param_1[299]);
  param_1[299] = 0;
  iVar1 = param_1[0x13d];
  local_4._0_1_ = 9;
  iVar3 = iVar1 + -1;
  param_1[0x13d] = iVar3;
  while (iVar2 = iVar3, iVar1 != 0) {
    iVar3 = iVar2 + -1;
    param_1[0x13d] = iVar3;
    iVar1 = iVar2;
  }
  if (param_1[0x13c] != 0) {
    FUN_005bbed0(param_1[0x13c]);
    param_1[0x13c] = 0;
  }
  param_1[0x13d] = 0;
  iVar1 = param_1[0x13b];
  local_4._0_1_ = 8;
  iVar3 = iVar1 + -1;
  param_1[0x13b] = iVar3;
  while (iVar2 = iVar3, iVar1 != 0) {
    iVar3 = iVar2 + -1;
    param_1[0x13b] = iVar3;
    iVar1 = iVar2;
  }
  if (param_1[0x13a] != 0) {
    FUN_005bbed0(param_1[0x13a]);
    param_1[0x13a] = 0;
  }
  param_1[0x13b] = 0;
  iVar1 = param_1[0x139];
  local_4 = (uint)local_4._1_3_ << 8;
  iVar3 = iVar1 + -1;
  param_1[0x139] = iVar3;
  while (iVar2 = iVar3, iVar1 != 0) {
    iVar3 = iVar2 + -1;
    param_1[0x139] = iVar3;
    iVar1 = iVar2;
  }
  if (param_1[0x138] != 0) {
    FUN_005bbed0(param_1[0x138]);
    param_1[0x138] = 0;
  }
  param_1[0x139] = 0;
  local_4 = 0xffffffff;
  FUN_005c5410();
  ExceptionList = local_c;
  return;
}


