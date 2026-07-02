// FUN_005d9d80  entry=005d9d80  size=1014 bytes

void __thiscall
FUN_005d9d80(int *param_1,byte *param_2,int param_3,uint param_4,int param_5,uint param_6,
            undefined4 param_7)

{
  int *piVar1;
  byte bVar2;
  bool bVar3;
  char cVar4;
  int iVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  uint uVar8;
  uint uVar9;
  int iVar10;
  int iVar11;
  uint uVar12;
  undefined4 uVar13;
  int iVar14;
  CRect *pCVar15;
  int iVar16;
  int *piVar17;
  int local_30;
  uint local_2c;
  int local_28;
  uint local_24;
  int local_20;
  uint local_1c;
  int local_18;
  uint local_14;
  CRect local_10 [16];
  
  if ((param_3 < param_5) && ((int)param_4 < (int)param_6)) {
    bVar3 = true;
  }
  else {
    bVar3 = false;
  }
  iVar11 = param_3;
  uVar8 = param_6;
  iVar5 = param_5;
  if (!bVar3) {
    iVar5 = -param_1[0xe];
    iVar10 = param_1[5] + iVar5;
    uVar8 = -param_1[0xf];
    iVar11 = iVar5;
    if (iVar10 <= iVar5) {
      iVar11 = iVar10;
    }
    if (-iVar10 == param_1[0xe] || iVar5 < iVar10) {
      iVar5 = iVar10;
    }
    uVar12 = param_1[6] + uVar8;
    param_4 = uVar8;
    if ((int)uVar12 <= (int)uVar8) {
      param_4 = uVar12;
    }
    if (-uVar12 == param_1[0xf] || (int)uVar8 < (int)uVar12) {
      uVar8 = uVar12;
    }
  }
  piVar1 = param_1 + 0xe;
  piVar17 = param_1 + 10;
  FUN_00437be0(&local_30,piVar1);
  uVar12 = param_4;
  if (local_30 <= iVar11) {
    local_30 = iVar11;
  }
  if (iVar5 <= local_28) {
    local_28 = iVar5;
  }
  if (local_30 < local_28) {
    uVar9 = param_4;
    if ((int)param_4 < (int)local_2c) {
      uVar9 = local_2c;
    }
    if ((int)uVar8 <= (int)local_24) {
      local_24 = uVar8;
    }
    if ((int)local_24 <= (int)uVar9) goto LAB_005d9e3c;
    bVar3 = true;
  }
  else {
LAB_005d9e3c:
    bVar3 = false;
  }
  if (!bVar3) {
    return;
  }
  if (((((short)param_7 != 0x100) || (*(char *)((int)param_1 + 0x149) != '\0')) ||
      ((char)param_1[0x53] != '\0')) || (param_1[8] != 8)) {
    FUN_005da180(param_2,iVar11,param_4,iVar5,uVar8,param_7,0);
    return;
  }
  local_2c = param_4;
  local_30 = iVar11;
  local_28 = iVar5;
  local_24 = uVar8;
  FUN_00437be0(&local_20,piVar1);
  if ((int)local_14 < (int)uVar8) {
    uVar8 = local_14;
  }
  if (local_18 < iVar5) {
    iVar5 = local_18;
  }
  uVar9 = local_1c;
  if ((int)local_1c <= (int)uVar12) {
    uVar9 = uVar12;
  }
  iVar10 = local_20;
  if (local_20 <= iVar11) {
    iVar10 = iVar11;
  }
  CRect::CRect(local_10,iVar10,uVar9,iVar5,uVar8);
  FUN_005e3c30(&param_3,param_2);
  uVar8 = param_1[0x51];
  if ((uVar8 & 0x200) == 0) {
    if ((uVar8 & 0x100) == 0) {
      local_2c = (int)(local_2c + local_24) / 2 - (int)param_4 / 2;
    }
  }
  else {
    local_2c = local_24 - param_4;
  }
  if ((uVar8 & 0x40) == 0) {
    if ((uVar8 & 0x20) == 0) {
      local_30 = local_30 + ((local_28 - local_30) - param_3) / 2;
    }
  }
  else {
    local_30 = local_28 - param_3;
  }
  local_28 = param_3 + local_30;
  local_24 = param_4 + local_2c;
  FUN_00495f20(piVar1);
  FUN_005c3410(piVar17);
  cVar4 = FUN_005d4240();
  if (cVar4 == '\0') {
    return;
  }
  FUN_00437be0(&local_20,piVar1);
  iVar5 = local_30;
  if (local_30 <= local_20) {
    iVar5 = local_20;
  }
  if (local_28 < local_18) {
    local_18 = local_28;
  }
  if (iVar5 < local_18) {
    uVar8 = local_2c;
    if ((int)local_2c <= (int)local_1c) {
      uVar8 = local_1c;
    }
    if ((int)local_24 < (int)local_14) {
      local_14 = local_24;
    }
    if ((int)uVar8 < (int)local_14) {
      bVar3 = true;
      goto LAB_005d9ff7;
    }
  }
  bVar3 = false;
LAB_005d9ff7:
  if (bVar3) {
    if ((*param_1 == 0) && (cVar4 = FUN_005cb2b0(), cVar4 == '\0')) {
      bVar3 = false;
    }
    else {
      bVar3 = true;
    }
    if (bVar3) {
      local_24 = local_24 + param_1[0xf];
      local_2c = local_2c + param_1[0xf];
      iVar5 = param_1[0x50];
      local_30 = local_30 + *piVar1;
      local_28 = local_28 + *piVar1;
      if (param_4 == *(byte *)(iVar5 + 0x20)) {
        while( true ) {
          if ((local_30 < local_28) && ((int)local_2c < (int)local_24)) {
            bVar3 = true;
          }
          else {
            bVar3 = false;
          }
          if (!bVar3) break;
          bVar2 = *param_2;
          if ((bVar2 == 0) || (-1 < (int)((uint)*(byte *)(bVar2 + 0x22 + iVar5) + local_30))) break;
          param_2 = param_2 + 1;
          local_30 = local_30 + (uint)*(byte *)(bVar2 + 0x22 + iVar5);
        }
      }
      if ((local_30 < local_28) && ((int)local_2c < (int)local_24)) {
        bVar3 = true;
      }
      else {
        bVar3 = false;
      }
      if ((bVar3) && (*param_2 != 0)) {
        iVar10 = param_1[7];
        iVar16 = *param_1;
        pCVar15 = local_10;
        uVar7 = *(undefined4 *)(iVar5 + 0x328);
        iVar11 = iVar5 + 0x126;
        uVar6 = CONCAT22((short)((uint)uVar7 >> 0x10),(ushort)*(byte *)(iVar5 + 0x21));
        uVar8 = (uint)*(byte *)(iVar5 + 0x20);
        iVar5 = iVar5 + 0x22;
        uVar13 = 0;
        iVar14 = iVar5;
        FUN_004ac740(param_1 + 0x46);
        uVar7 = FUN_005a1c00(iVar5,uVar13,iVar14,uVar8,uVar6,iVar11,uVar7,pCVar15,iVar16,iVar10);
        FUN_005f8d50(param_2,&local_30,uVar7);
        return;
      }
    }
  }
  return;
}


