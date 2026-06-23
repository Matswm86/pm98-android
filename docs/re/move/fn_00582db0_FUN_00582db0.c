// FUN_00582db0  entry=00582db0  size=219 bytes

int __fastcall FUN_00582db0(int param_1)

{
  int iVar1;
  byte bVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  
  bVar2 = *(byte *)(param_1 + 0xa6);
  iVar3 = FUN_00582e90();
  iVar3 = (uint)bVar2 + iVar3;
  FUN_00585ee0(*(undefined2 *)(param_1 + 0x14));
  iVar4 = FUN_005793d0();
  bVar2 = *(byte *)(param_1 + 0x19);
  if (bVar2 < 0xc) {
    if (bVar2 - 1 < 0xb) {
      iVar5 = (bVar2 + 2) * 0x20 + iVar4;
    }
    else {
      iVar5 = 0;
    }
    iVar1 = (uint)*(byte *)(param_1 + 0x18) * 0x14;
    if (*(int *)(&DAT_00638e40 + (uint)*(byte *)(param_1 + 0x18) * 0x14) == 0) {
      if ((((*(uint *)(&DAT_00638e34 + iVar1) <= *(uint *)(iVar5 + 0x10)) &&
           (*(uint *)(iVar5 + 0x10) < *(uint *)(&DAT_00638e38 + iVar1))) &&
          (*(uint *)(&DAT_00638e34 + iVar1) <= *(uint *)(iVar5 + 0x14))) &&
         (*(uint *)(iVar5 + 0x14) < *(uint *)(&DAT_00638e3c + iVar1))) goto LAB_00582e58;
    }
    else if (((*(uint *)(&DAT_00638e34 + iVar1) <= *(uint *)(iVar5 + 0x18)) &&
             (*(uint *)(iVar5 + 0x18) < *(uint *)(&DAT_00638e38 + iVar1))) &&
            ((*(uint *)(&DAT_00638e34 + iVar1) <= *(uint *)(iVar5 + 0x1c) &&
             (*(uint *)(iVar5 + 0x1c) < *(uint *)(&DAT_00638e3c + iVar1))))) goto LAB_00582e58;
    iVar3 = iVar3 + -0xf;
  }
LAB_00582e58:
  if (*(int *)(iVar4 + 0x5c) != 0xffff) {
    iVar4 = FUN_0057b710(param_1);
    iVar3 = iVar3 + iVar4;
  }
  if (0x27 < iVar3) {
    if (99 < iVar3) {
      iVar3 = 99;
    }
    return iVar3;
  }
  return 0x28;
}


