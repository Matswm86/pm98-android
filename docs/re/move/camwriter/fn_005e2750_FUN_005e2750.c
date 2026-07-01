// FUN_005e2750  entry=005e2750  size=378 bytes

bool __fastcall FUN_005e2750(int param_1)

{
  bool bVar1;
  int iVar2;
  int *piVar3;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  puStack_8 = &LAB_00621a28;
  local_c = ExceptionList;
  bVar1 = false;
  local_4 = 0;
  ExceptionList = &local_c;
  if (param_1 != -0x84) {
    ExceptionList = &local_c;
    iVar2 = FUN_005e1620(0xffffffff);
    while (iVar2 == 0) {
      iVar2 = FUN_005e1620(0xffffffff);
    }
    bVar1 = true;
  }
  if (*(int *)(param_1 + 0x7c) == 0) {
    if ((param_1 != -0x84) && (bVar1)) {
      FUN_005e1640();
      bVar1 = false;
    }
    iVar2 = FUN_005e2f60(11000,8,0);
    if (iVar2 == 0) {
      local_4 = 0xffffffff;
      if (bVar1) {
        FUN_005e1640();
      }
      ExceptionList = local_c;
      return false;
    }
    if (param_1 != -0x84) {
      iVar2 = FUN_005e1620(0xffffffff);
      while (iVar2 == 0) {
        iVar2 = FUN_005e1620(0xffffffff);
      }
      bVar1 = true;
    }
  }
  iVar2 = 0;
  if (0 < *(int *)(param_1 + 0xac)) {
    piVar3 = (int *)(*(int *)(param_1 + 0xa8) + 0x10);
    do {
      if (*piVar3 != 0) {
        if ((param_1 != -0x84) && (bVar1)) {
          FUN_005e1640();
          bVar1 = false;
        }
        local_4 = 0xffffffff;
        if (bVar1) {
          FUN_005e1640();
        }
        ExceptionList = local_c;
        return true;
      }
      iVar2 = iVar2 + 1;
      piVar3 = piVar3 + 6;
    } while (iVar2 < *(int *)(param_1 + 0xac));
  }
  iVar2 = FUN_005ed0c0();
  if ((param_1 != -0x84) && (bVar1)) {
    FUN_005e1640();
    bVar1 = false;
  }
  local_4 = 0xffffffff;
  if (bVar1) {
    FUN_005e1640();
  }
  ExceptionList = local_c;
  return 0 < iVar2;
}


