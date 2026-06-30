// FUN_00456bc0  entry=00456bc0  size=184 bytes

undefined4 __thiscall FUN_00456bc0(void *this,uint param_1,uint param_2)

{
  int iVar1;
  bool bVar2;
  DWORD DVar3;
  uint uVar4;
  void *pvVar5;
  void *pvVar6;
  uint *puVar7;
  int iVar8;
  bool bVar9;
  
  bVar2 = false;
  pvVar6 = (void *)(DAT_00501cac + -1);
  if (DAT_00501cac != 0) {
    puVar7 = (uint *)(DAT_00501ca8 + 4);
    pvVar5 = pvVar6;
    bVar2 = false;
    do {
      if (((void *)puVar7[2] == this) && (puVar7[-1] == param_1)) {
        uVar4 = *puVar7;
        puVar7[1] = param_2;
        DVar3 = timeGetTime();
        if (DVar3 + param_2 < uVar4) {
          DVar3 = timeGetTime();
          uVar4 = DVar3 + param_2;
        }
        *puVar7 = uVar4;
        pvVar5 = (void *)0x0;
        bVar2 = true;
      }
      puVar7 = puVar7 + 4;
      pvVar6 = (void *)((int)pvVar5 + -1);
      bVar9 = pvVar5 != (void *)0x0;
      pvVar5 = pvVar6;
    } while (bVar9);
  }
  if (!bVar2) {
    DVar3 = timeGetTime();
    iVar1 = DAT_00501cac + 1;
    iVar8 = iVar1 * 0x10;
    FUN_0044fb30(&DAT_00501ca8,iVar8);
    puVar7 = (uint *)(DAT_00501ca8 + -0x10 + iVar8);
    DAT_00501cac = iVar1;
    *puVar7 = param_1;
    puVar7[1] = DVar3 + param_2;
    puVar7[2] = param_2;
    puVar7[3] = (uint)this;
    pvVar6 = this;
  }
  return CONCAT31((int3)((uint)pvVar6 >> 8),1);
}


