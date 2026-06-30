// FUN_00452b90  entry=00452b90  size=1014 bytes

void __thiscall
FUN_00452b90(void *this,byte *param_1,uint param_2,uint param_3,uint param_4,uint param_5,
            uint param_6)

{
  int *piVar1;
  int *this_00;
  int iVar2;
  bool bVar3;
  byte bVar4;
  uint uVar5;
  void *this_01;
  int *piVar6;
  undefined4 uVar7;
  uint uVar8;
  uint uVar9;
  uint uVar10;
  uint uVar11;
  undefined4 uVar12;
  int iVar13;
  int iVar14;
  CRect *pCVar15;
  int iVar16;
  int iVar17;
  uint local_30;
  uint local_2c;
  uint local_28;
  uint local_24;
  uint local_20;
  uint local_1c;
  uint local_18;
  uint local_14;
  CRect local_10 [16];
  
  if (((int)param_2 < (int)param_4) && ((int)param_3 < (int)param_5)) {
    bVar3 = true;
  }
  else {
    bVar3 = false;
  }
  uVar10 = param_2;
  uVar8 = param_5;
  uVar5 = param_4;
  if (!bVar3) {
    uVar5 = -*(int *)((int)this + 0x38);
    uVar11 = *(int *)((int)this + 0x14) + uVar5;
    uVar8 = -*(int *)((int)this + 0x3c);
    uVar10 = uVar5;
    if ((int)uVar11 <= (int)uVar5) {
      uVar10 = uVar11;
    }
    if (-uVar11 == *(int *)((int)this + 0x38) || (int)uVar5 < (int)uVar11) {
      uVar5 = uVar11;
    }
    uVar11 = *(int *)((int)this + 0x18) + uVar8;
    param_3 = uVar8;
    if ((int)uVar11 <= (int)uVar8) {
      param_3 = uVar11;
    }
    if (-uVar11 == *(int *)((int)this + 0x3c) || (int)uVar8 < (int)uVar11) {
      uVar8 = uVar11;
    }
  }
  piVar1 = (int *)((int)this + 0x38);
  this_00 = (int *)((int)this + 0x28);
  FUN_00404230(this_00,(int *)&local_30,piVar1);
  uVar11 = param_3;
  if ((int)local_30 <= (int)uVar10) {
    local_30 = uVar10;
  }
  if ((int)uVar5 <= (int)local_28) {
    local_28 = uVar5;
  }
  if ((int)local_30 < (int)local_28) {
    uVar9 = param_3;
    if ((int)param_3 < (int)local_2c) {
      uVar9 = local_2c;
    }
    if ((int)uVar8 <= (int)local_24) {
      local_24 = uVar8;
    }
    if ((int)local_24 <= (int)uVar9) goto LAB_00452c4c;
    bVar3 = true;
  }
  else {
LAB_00452c4c:
    bVar3 = false;
  }
  if (!bVar3) {
    return;
  }
  if (((((short)param_6 != 0x100) || (*(char *)((int)this + 0x22d) != '\0')) ||
      (*(char *)((int)this + 0x230) != '\0')) || (*(int *)((int)this + 0x20) != 8)) {
    FUN_00452f90(this,param_1,uVar10,param_3,uVar5,uVar8,param_6,'\0');
    return;
  }
  local_2c = param_3;
  local_30 = uVar10;
  local_28 = uVar5;
  local_24 = uVar8;
  FUN_00404230(this_00,(int *)&local_20,piVar1);
  if ((int)local_14 < (int)uVar8) {
    uVar8 = local_14;
  }
  if ((int)local_18 < (int)uVar5) {
    uVar5 = local_18;
  }
  uVar9 = local_1c;
  if ((int)local_1c <= (int)uVar11) {
    uVar9 = uVar11;
  }
  uVar11 = local_20;
  if ((int)local_20 <= (int)uVar10) {
    uVar11 = uVar10;
  }
  CRect::CRect(local_10,uVar11,uVar9,uVar5,uVar8);
  FUN_00462910(*(void **)((int)this + 0x224),(int *)&param_2,param_1);
  uVar5 = *(uint *)((int)this + 0x228);
  if ((uVar5 & 0x200) == 0) {
    if ((uVar5 & 0x100) == 0) {
      local_2c = (int)(local_2c + local_24) / 2 - (int)param_3 / 2;
    }
  }
  else {
    local_2c = local_24 - param_3;
  }
  if ((uVar5 & 0x40) == 0) {
    if ((uVar5 & 0x20) == 0) {
      local_30 = local_30 + (int)((local_28 - local_30) - param_2) / 2;
    }
  }
  else {
    local_30 = local_28 - param_2;
  }
  local_28 = param_2 + local_30;
  local_24 = param_3 + local_2c;
  piVar6 = this_00;
  this_01 = (void *)FUN_0044f9d0(local_10,piVar1);
  piVar6 = (int *)FUN_0044f980(this_01,piVar6);
  uVar7 = FUN_0044f960(piVar6);
  if ((char)uVar7 == '\0') {
    return;
  }
  FUN_00404230(this_00,(int *)&local_20,piVar1);
  uVar5 = local_30;
  if ((int)local_30 <= (int)local_20) {
    uVar5 = local_20;
  }
  if ((int)local_28 < (int)local_18) {
    local_18 = local_28;
  }
  if ((int)uVar5 < (int)local_18) {
    uVar5 = local_2c;
    if ((int)local_2c <= (int)local_1c) {
      uVar5 = local_1c;
    }
    if ((int)local_24 < (int)local_14) {
      local_14 = local_24;
    }
    if ((int)uVar5 < (int)local_14) {
      bVar3 = true;
      goto LAB_00452e07;
    }
  }
  bVar3 = false;
LAB_00452e07:
  if (bVar3) {
    if ((*(int *)this != 0) || (bVar3 = FUN_0044e840(this), bVar3)) {
      bVar3 = true;
    }
    else {
      bVar3 = false;
    }
    if (bVar3) {
      local_24 = local_24 + *(int *)((int)this + 0x3c);
      local_2c = local_2c + *(int *)((int)this + 0x3c);
      iVar2 = *(int *)((int)this + 0x224);
      local_30 = local_30 + *piVar1;
      local_28 = local_28 + *piVar1;
      if (param_3 == *(byte *)(iVar2 + 0x20)) {
        while( true ) {
          if (((int)local_30 < (int)local_28) && ((int)local_2c < (int)local_24)) {
            bVar3 = true;
          }
          else {
            bVar3 = false;
          }
          if (!bVar3) break;
          bVar4 = *param_1;
          if ((bVar4 == 0) || (-1 < (int)(*(byte *)(bVar4 + 0x22 + iVar2) + local_30))) break;
          param_1 = param_1 + 1;
          local_30 = local_30 + *(byte *)(bVar4 + 0x22 + iVar2);
        }
      }
      if (((int)local_30 < (int)local_28) && ((int)local_2c < (int)local_24)) {
        bVar3 = true;
      }
      else {
        bVar3 = false;
      }
      if ((bVar3) && (*param_1 != 0)) {
        iVar17 = *(int *)((int)this + 0x1c);
        iVar16 = *(int *)this;
        pCVar15 = local_10;
        iVar14 = *(int *)(iVar2 + 0x328);
        iVar13 = iVar2 + 0x126;
        uVar7 = CONCAT22((short)((uint)iVar14 >> 0x10),(ushort)*(byte *)(iVar2 + 0x21));
        uVar8 = (uint)*(byte *)(iVar2 + 0x20);
        uVar10 = iVar2 + 0x22;
        uVar12 = 0;
        uVar5 = uVar10;
        FUN_004042e0(&stack0xffffff8c,(undefined4 *)((int)this + 0x1fc));
        bVar4 = FUN_0044fa10(uVar10);
        FUN_00470cc0(param_1,(int *)&local_30,bVar4,uVar12,uVar5,uVar8,uVar7,iVar13,iVar14,
                     (int *)pCVar15,iVar16,iVar17);
        return;
      }
    }
  }
  return;
}


