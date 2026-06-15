// FUN_00484eb0  entry=00484eb0  size=735 bytes
// callers/callees expanded one level from seeds

undefined4 * __fastcall FUN_00484eb0(undefined4 *param_1)

{
  void *pvVar1;
  int iVar2;
  undefined1 local_210 [516];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_0060ddd2;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  *param_1 = &PTR_FUN_00627fa8;
  local_4 = 0;
  param_1[1] = 0;
  param_1[2] = 0;
  FUN_00605ee0(param_1 + 4,0x2860,4,FUN_0046b580,FUN_0046b680);
  local_4._0_1_ = 1;
  FUN_00605ee0(param_1 + 0x2864,0x1824,2,FUN_0046b750,FUN_0046b800);
  local_4._0_1_ = 2;
  FUN_0043e8c0();
  param_1[0x3476] = &PTR_LAB_00624d08;
  local_4._0_1_ = 3;
  FUN_0043e8c0();
  param_1[0x357c] = &PTR_LAB_00624d08;
  local_4._0_1_ = 4;
  FUN_005bc430();
  local_4._0_1_ = 5;
  FUN_005bc430();
  local_4._0_1_ = 6;
  FUN_005bc430();
  local_4._0_1_ = 7;
  FUN_005bc430();
  local_4._0_1_ = 8;
  FUN_005bc430();
  local_4._0_1_ = 9;
  FUN_0043e8c0();
  param_1[0x3b74] = &PTR_LAB_00624d08;
  local_4._0_1_ = 10;
  FUN_00435550();
  local_4._0_1_ = 0xb;
  FUN_00435550();
  local_4._0_1_ = 0xc;
  FUN_00435550();
  local_4._0_1_ = 0xd;
  FUN_005bc430();
  local_4._0_1_ = 0xe;
  FUN_005c9210();
  local_4._0_1_ = 0xf;
  FUN_0043e8c0();
  param_1[0x409c] = &PTR_LAB_00624d08;
  local_4._0_1_ = 0x10;
  FUN_005bc430();
  param_1[0x42a0] = 0;
  param_1[0x429f] = 1;
  param_1[0x42a1] = 0;
  param_1[0x41a2] = &PTR_LAB_00628540;
  local_4._0_1_ = 0x11;
  FUN_005bc430();
  param_1[0x43a9] = 1;
  param_1[0x43aa] = 1;
  param_1[0x42ac] = &PTR_LAB_00627d78;
  local_4._0_1_ = 0x12;
  FUN_0043e8c0();
  param_1[0x43ae] = &PTR_LAB_00624d08;
  local_4._0_1_ = 0x13;
  FUN_0043e8c0();
  param_1[0x44b4] = &PTR_LAB_00624d08;
  local_4._0_1_ = 0x14;
  FUN_0043e8c0();
  param_1[0x45ba] = &PTR_LAB_00624d08;
  local_4._0_1_ = 0x15;
  *param_1 = &PTR_LAB_00628da8;
  pvVar1 = operator_new(0x18d8);
  local_4._0_1_ = 0x16;
  if (pvVar1 == (void *)0x0) {
    iVar2 = 0;
  }
  else {
    iVar2 = FUN_00485190();
  }
  local_4 = CONCAT31(local_4._1_3_,0x15);
  if (iVar2 == 0) {
    FUN_00445c70(&DAT_00666f70,0xffff0002);
                    /* WARNING: Subroutine does not return */
    _CxxThrowException(local_210,(ThrowInfo *)&DAT_0063ac98);
  }
  param_1[3] = iVar2;
  param_1[0x46c1] = 0;
  ExceptionList = local_c;
  return param_1;
}


