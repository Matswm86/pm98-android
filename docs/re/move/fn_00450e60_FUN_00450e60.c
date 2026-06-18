// FUN_00450e60  entry=00450e60  size=586 bytes

byte __fastcall FUN_00450e60(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  bool bVar5;
  
  iVar1 = *(int *)(param_1 + 0x34);
  iVar2 = *(int *)(param_1 + 0x2c);
  iVar4 = *(int *)(param_1 + 0x30);
  if ((((iVar1 != 0xff) && (*(int *)(param_1 + 0x38) != 0xff)) && (*(int *)(param_1 + 0x44) != 0))
     && (*(int *)(param_1 + 0x20) != 0)) {
    iVar4 = *(int *)(param_1 + 0x38);
    iVar2 = iVar1;
  }
  if (*(int *)(param_1 + 0x48) == 0) goto LAB_0045106a;
  if ((iVar2 == 0xff) && (iVar4 == 0xff)) {
    iVar1 = FUN_00450d60();
    iVar2 = FUN_00450db0();
    if (iVar1 != iVar2) {
      iVar1 = FUN_00450d60();
      iVar2 = FUN_00450db0();
      return (iVar1 <= iVar2) + 1;
    }
    if (*(int *)(param_1 + 0x24) == 0) {
      return 0;
    }
    iVar1 = FUN_00450e00();
    iVar2 = FUN_00450e30();
    if (iVar2 < iVar1) {
      return 1;
    }
    iVar1 = FUN_00450e00();
    iVar2 = FUN_00450e30();
    if (iVar2 <= iVar1) {
      return 0;
    }
    return 2;
  }
  if ((*(int *)(param_1 + 0x28) != 0) &&
     (((*(int *)(param_1 + 0x44) == 0 || (*(int *)(param_1 + 0x20) == 0)) || (iVar1 == 0xff)))) {
    iVar1 = FUN_00450d60();
    iVar3 = FUN_00450db0();
    if (iVar3 + iVar4 < iVar1 + iVar2) {
      return 1;
    }
    iVar1 = FUN_00450d60();
    iVar3 = FUN_00450db0();
    bVar5 = SBORROW4(iVar1 + iVar2,iVar3 + iVar4);
    iVar2 = (iVar1 + iVar2) - (iVar3 + iVar4);
    goto LAB_00450fd0;
  }
  if (iVar2 == iVar4) {
    iVar1 = FUN_00450d60();
    iVar3 = FUN_00450db0();
    if (iVar1 != iVar3) goto LAB_00450f9a;
  }
  else {
LAB_00450f9a:
    iVar1 = FUN_00450d60();
    iVar3 = FUN_00450db0();
    if (iVar1 + iVar2 != iVar3 + iVar4) {
      iVar1 = FUN_00450d60();
      iVar3 = FUN_00450db0();
      if (iVar3 + iVar4 < iVar1 + iVar2) {
        return 1;
      }
      iVar1 = FUN_00450d60();
      iVar3 = FUN_00450db0();
      if (iVar1 + iVar2 < iVar3 + iVar4) {
        return 2;
      }
LAB_0045106a:
      iVar1 = FUN_00450d60();
      iVar2 = FUN_00450db0();
      if (iVar1 <= iVar2) {
        iVar1 = FUN_00450d60();
        iVar2 = FUN_00450db0();
        return (iVar2 <= iVar1) - 1U & 2;
      }
      return 1;
    }
  }
  iVar1 = FUN_00450db0();
  if (iVar1 < iVar2) {
    return 1;
  }
  iVar1 = FUN_00450db0();
  bVar5 = SBORROW4(iVar2,iVar1);
  iVar2 = iVar2 - iVar1;
LAB_00450fd0:
  if (bVar5 != iVar2 < 0) {
    return 2;
  }
  if (*(int *)(param_1 + 0x24) != 0) {
    iVar1 = FUN_00450e00();
    iVar2 = FUN_00450e30();
    if (iVar2 < iVar1) {
      return 1;
    }
    iVar1 = FUN_00450e00();
    iVar2 = FUN_00450e30();
    if (iVar1 < iVar2) {
      return 2;
    }
  }
  return 0;
}


