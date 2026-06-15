// FUN_005c5410  entry=005c5410  size=407 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_005c5410(undefined4 *param_1)

{
  short sVar1;
  short sVar2;
  undefined4 *puVar3;
  int *piVar4;
  bool bVar5;
  void *pvStack_c;
  undefined1 *puStack_8;
  int local_4;
  
  puStack_8 = &LAB_0062128a;
  pvStack_c = ExceptionList;
  ExceptionList = &pvStack_c;
  *param_1 = &PTR_LAB_00639888;
  puVar3 = (undefined4 *)param_1[0xfd];
  local_4 = 2;
  if ((puVar3 != &DAT_006749a8) && (puVar3 != &DAT_00674810)) {
    if (puVar3 != (undefined4 *)0x0) {
      local_4._0_1_ = 4;
      local_4._1_3_ = 0;
      if (puVar3[99] != 0) {
        FUN_005bbed0(puVar3[99]);
        puVar3[99] = 0;
      }
      puVar3[100] = 0;
      local_4._0_1_ = 3;
      FUN_005a20b0(puVar3 + 0x54);
      puVar3[0x55] = 0;
      local_4 = CONCAT31(local_4._1_3_,2);
      thunk_FUN_005cb040();
      operator_delete(puVar3);
    }
    param_1[0xfd] = 0;
  }
  if ((DAT_00674804 < 1) || (*(int *)(DAT_00674800 + 0x18 + DAT_00674c2c * 0x134) == 0)) {
    bVar5 = false;
  }
  else {
    bVar5 = true;
  }
  if (bVar5) {
    piVar4 = (int *)param_1[0xfe];
    if (piVar4 != (int *)0x0) {
      (**(code **)(*piVar4 + 8))(piVar4);
    }
    param_1[0xfe] = 0;
  }
  local_4._0_1_ = 1;
  if (param_1[0x109] != 0) {
    FUN_005bbed0(param_1[0x109]);
    param_1[0x109] = 0;
  }
  param_1[0x10a] = 0;
  sVar2 = *(short *)(param_1 + 0x108);
  local_4 = (uint)local_4._1_3_ << 8;
  sVar1 = sVar2 + -1;
  *(short *)(param_1 + 0x108) = sVar1;
  while (sVar2 != 0) {
    if (param_1[0x107] + sVar1 * 8 != 0) {
      FUN_005c7cc0();
    }
    sVar2 = *(short *)(param_1 + 0x108);
    sVar1 = sVar2 + -1;
    *(short *)(param_1 + 0x108) = sVar1;
  }
  if (param_1[0x107] != 0) {
    FUN_005bbed0(param_1[0x107]);
    param_1[0x107] = 0;
  }
  *(undefined2 *)(param_1 + 0x108) = 0;
  local_4 = 0xffffffff;
  FUN_005bc6a0();
  ExceptionList = pvStack_c;
  return;
}


