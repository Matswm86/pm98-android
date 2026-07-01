// FUN_005c8490  entry=005c8490  size=230 bytes

void __thiscall FUN_005c8490(int param_1,undefined4 param_2)

{
  int iVar1;
  int iVar2;
  
  if (((char)param_2 == '\0') || ((*(uint *)(param_1 + 0xac) & 0x20000) == 0)) {
    FUN_005d45b0(param_2);
    return;
  }
  iVar1 = param_1;
  if ((*(uint *)(param_1 + 0x3f4) >> 4 & 1) != 0) {
    FUN_005d47e0();
    return;
  }
  while (((iVar2 = param_1, iVar2 != 0 && ((*(uint *)(iVar2 + 0xac) & 0x20000) != 0)) &&
         ((*(uint *)(iVar2 + 0xac) & 0x10000) == 0))) {
    param_1 = *(int *)(iVar2 + 0x4c);
    iVar1 = iVar2;
    if (param_1 == 0) goto LAB_005c850a;
    if (*(int *)(param_1 + 0xb4) != 3) {
      param_1 = 0;
    }
  }
  if ((iVar2 == 0) || ((*(uint *)(iVar2 + 0xac) & 0x20000) == 0)) {
LAB_005c850a:
    iVar2 = iVar1;
  }
  while( true ) {
    if ((*(uint *)(iVar2 + 0x3f4) >> 4 & 1) != 0) {
      FUN_005d45b0(0);
    }
    iVar2 = *(int *)(iVar2 + 0x50);
    if (iVar2 == 0) break;
    if (*(int *)(iVar2 + 0xb4) != 3) {
      iVar2 = 0;
    }
    if (((iVar2 == 0) || ((*(uint *)(iVar2 + 0xac) & 0x20000) == 0)) ||
       ((*(uint *)(iVar2 + 0xac) & 0x10000) != 0)) break;
  }
  FUN_005d45b0(1);
  return;
}


