// FUN_005e5050  entry=005e5050  size=173 bytes

undefined4
FUN_005e5050(undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
            undefined4 param_5,undefined4 param_6)

{
  undefined4 uVar1;
  void *pvStack_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_00621c9b;
  pvStack_c = ExceptionList;
  ExceptionList = &pvStack_c;
  (**(code **)(*DAT_00674ea0 + 0x110))();
  FUN_005c52b0();
  uStack_4 = 0;
  uVar1 = FUN_005f9070(param_1,param_2,param_3,param_4,param_5,param_6);
  uStack_4 = 0xffffffff;
  FUN_005c5410();
  ExceptionList = pvStack_c;
  return uVar1;
}


