// FUN_00588580  entry=00588580  size=157 bytes

void __thiscall FUN_00588580(int param_1,uint param_2,int param_3)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  
  iVar4 = *(int *)(param_1 + 0x24);
  iVar2 = 0;
  while ((iVar4 != 0 && (iVar2 == 0))) {
    iVar3 = iVar2;
    if ((*(byte *)(iVar4 + 0x1c) == param_2) &&
       (((uint)*(ushort *)(iVar4 + 0x6c) == *(uint *)(param_1 + 0x10) &&
        (iVar3 = iVar4, param_3 != 0)))) {
      param_3 = param_3 + -1;
      iVar3 = iVar2;
    }
    iVar4 = *(int *)(iVar4 + 0x100);
    iVar2 = iVar3;
  }
  uVar5 = 0;
  if (*(uint *)(param_1 + 0x48) != 0) {
    do {
      if (iVar2 != 0) {
        return;
      }
      uVar1 = *(uint *)(*(int *)(param_1 + 0x44) + uVar5 * 4);
      if (uVar1 < DAT_0066c150) {
        iVar4 = *(int *)(DAT_0066c158 + uVar1 * 4);
      }
      else {
        iVar4 = 0;
      }
      iVar3 = iVar2;
      if (((iVar4 != 0) && (*(byte *)(iVar4 + 0x1c) == param_2)) && (iVar3 = iVar4, param_3 != 0)) {
        param_3 = param_3 + -1;
        iVar3 = iVar2;
      }
      uVar5 = uVar5 + 1;
      iVar2 = iVar3;
    } while (uVar5 < *(uint *)(param_1 + 0x48));
  }
  return;
}


