// FUN_0057a180  entry=0057a180  size=199 bytes

void __fastcall FUN_0057a180(int param_1)

{
  int iVar1;
  undefined4 uVar2;
  uint uVar3;
  undefined4 *puVar4;
  uint uVar5;
  undefined8 uVar6;
  
  iVar1 = *(int *)(param_1 + 0x10);
  if ((iVar1 == 0x26e4) || (iVar1 == 0x26de)) {
    uVar5 = 0xd;
    uVar3 = 0xc;
  }
  else {
    if (iVar1 == 0x26ae) {
      *(undefined4 *)(param_1 + 0x50) = 0xd;
      *(undefined4 *)(param_1 + 0x58) = 0;
      return;
    }
    uVar5 = 0;
    puVar4 = &DAT_0066b190;
    do {
      uVar6 = (**(code **)(*(int *)*puVar4 + 0x48))(*(undefined2 *)(param_1 + 0x10));
      uVar2 = (undefined4)((ulonglong)uVar6 >> 0x20);
      if ((int)uVar6 != 0) break;
      puVar4 = puVar4 + 1;
      uVar5 = uVar5 + 1;
    } while (puVar4 < &DAT_0066b1a0);
    if (3 < uVar5) {
      uVar5 = 7;
      puVar4 = &DAT_0066b1ac;
      do {
        uVar6 = (**(code **)(*(int *)*puVar4 + 0x48))
                          (CONCAT22((short)((uint)uVar2 >> 0x10),*(undefined2 *)(param_1 + 0x10)));
        uVar2 = (undefined4)((ulonglong)uVar6 >> 0x20);
        if ((int)uVar6 != 0) break;
        puVar4 = puVar4 + 1;
        uVar5 = uVar5 + 1;
      } while (puVar4 < &DAT_0066b1c4);
    }
    iVar1 = *(int *)(&DAT_0066b190)[uVar5];
    uVar2 = FUN_0057a340();
    uVar3 = (**(code **)(iVar1 + 0x78))(uVar2);
    if (0xc < uVar3) {
      *(uint *)(param_1 + 0x50) = uVar5;
      *(undefined4 *)(param_1 + 0x58) = 0xc;
      return;
    }
  }
  *(uint *)(param_1 + 0x50) = uVar5;
  *(uint *)(param_1 + 0x58) = uVar3;
  return;
}


