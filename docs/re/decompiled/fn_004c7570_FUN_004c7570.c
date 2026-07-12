// FUN_004c7570  entry=004c7570  size=523 bytes

void __thiscall FUN_004c7570(int param_1,int param_2)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  
  if (*(int *)(param_1 + 0x204c0) < 4) {
    if ((*(int *)(param_1 + 0x204c0) == 0) && ((*(uint *)(param_1 + 0x1ecdc) >> 7 & 1) != 0)) {
      FUN_005bf8c0(1,1);
    }
    *(undefined4 *)(*(int *)(param_1 + 0x204c0) * 0x400 + param_1 + 0x2189c) = 0;
    FUN_005bec80(0);
    *(undefined2 *)(*(int *)(param_1 + 0x204c0) * 0x400 + param_1 + 0x218a0) =
         *(undefined2 *)(param_2 + 0x54);
    FUN_005bec80(0);
    if ((*(uint *)(*(int *)(param_1 + 0x204c0) * 0x400 + 0x21550 + param_1) >> 7 & 1) != 0) {
      FUN_005bf8c0(1,1);
    }
    FUN_00585ee0(*(undefined4 *)(DAT_0066c178 + 0x24 + *(int *)(param_1 + 0x224b4) * 0x9c));
    FUN_005793d0();
    FUN_00585ee0(*(undefined2 *)(*(int *)(param_1 + 0x204c0) * 0x400 + 0x218a0 + param_1));
    FUN_005793d0();
    uVar1 = FUN_0057a340();
    uVar2 = FUN_0057a340();
    if (uVar1 < uVar2) {
      *(short *)(*(int *)(param_1 + 0x204c0) * 0x400 + param_1 + 0x218a2) =
           (short)*(undefined4 *)(DAT_0066c178 + 0x24 + *(int *)(param_1 + 0x224b4) * 0x9c);
    }
    else {
      iVar3 = *(int *)(param_1 + 0x204c0) * 0x400;
      *(undefined2 *)(iVar3 + param_1 + 0x218a2) = *(undefined2 *)(iVar3 + 0x218a0 + param_1);
    }
    FUN_005bec80(0);
    iVar3 = *(int *)(param_1 + 0x204c0) + 1;
    *(int *)(param_1 + 0x204c0) = iVar3;
    if (iVar3 < 4) {
      *(undefined4 *)(iVar3 * 0x400 + param_1 + 0x2189c) = 1;
      FUN_005bec80(0);
      if ((*(uint *)(*(int *)(param_1 + 0x204c0) * 0x400 + 0x21550 + param_1) >> 7 & 1) != 0) {
        FUN_005bf8c0(1,1);
      }
    }
    if (*(int *)(param_1 + 0x204c0) == 4) {
      if ((~(byte)(*(uint *)(param_1 + 0x1f0f4) >> 7) & 1) != 0) {
        FUN_005bf8c0(0,1);
      }
      if ((*(uint *)(param_1 + 0x1e8c4) >> 7 & 1) != 0) {
        FUN_005bf8c0(1,1);
      }
    }
    FUN_0055e4a0();
  }
  return;
}


