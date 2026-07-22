// FUN_0057a5a0  entry=0057a5a0  size=360 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __fastcall FUN_0057a5a0(int param_1)

{
  byte bVar1;
  byte bVar2;
  byte bVar3;
  byte bVar4;
  byte bVar5;
  float fVar6;
  undefined4 uVar7;
  int iVar8;
  int iVar9;
  
  FUN_0057a180();
  for (iVar8 = *(int *)(param_1 + 0x24); iVar8 != 0; iVar8 = *(int *)(iVar8 + 0x100)) {
    bVar1 = *(byte *)(iVar8 + 0x1b);
    if (bVar1 < 0xc) {
      *(char *)(bVar1 + 0x297 + param_1) = *(char *)(iVar8 + 0x18) + '\x01';
    }
    bVar2 = *(byte *)(iVar8 + 0x9f);
    bVar3 = *(byte *)(iVar8 + 0x9e);
    bVar4 = *(byte *)(iVar8 + 0x9d);
    bVar5 = *(byte *)(iVar8 + 0x9c);
    iVar9 = *(byte *)(iVar8 + 0x18) + 1;
    uVar7 = FUN_00584b50(iVar9);
    FUN_00576cd0(*(undefined4 *)(param_1 + 0x10),*(undefined4 *)(param_1 + 0x58),
                 (uint)bVar2 + (uint)bVar3 + (uint)bVar4 + (uint)bVar5 >> 2,uVar7,iVar9);
    if (*(int *)(param_1 + 0x50) != 0) {
      *(byte *)(iVar8 + 0xf8) = bVar1;
    }
  }
  if (*(uint *)(param_1 + 0x50) < 4) {
    if (*(float *)(param_1 + 0x1e8) < (float)_DAT_00638d58) {
      iVar8 = FUN_0058df90(10);
      fVar6 = (float)(iVar8 + 100) * _DAT_00638d60;
      *(float *)(param_1 + 0x1e8) = fVar6;
      *(float *)(param_1 + 0x1ec) = fVar6;
      return;
    }
  }
  else {
    fVar6 = _DAT_00638d88;
    switch(*(undefined4 *)(param_1 + 0x58)) {
    case 0:
      fVar6 = _DAT_00638d64;
      break;
    case 1:
      fVar6 = _DAT_00638d68;
      break;
    case 2:
      fVar6 = _DAT_00638d6c;
      break;
    case 3:
      fVar6 = _DAT_00638d70;
      break;
    case 4:
      fVar6 = _DAT_00638d74;
      break;
    case 5:
      fVar6 = _DAT_00638d78;
      break;
    case 6:
      fVar6 = _DAT_00638d7c;
      break;
    case 7:
      fVar6 = _DAT_00638d80;
      break;
    case 8:
      fVar6 = _DAT_00638d84;
    }
    if (*(float *)(param_1 + 0x1e8) < fVar6) {
      *(float *)(param_1 + 0x1e8) = fVar6;
      *(float *)(param_1 + 0x1ec) = fVar6;
      return;
    }
  }
  return;
}


