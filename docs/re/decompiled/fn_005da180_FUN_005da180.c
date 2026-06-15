// FUN_005da180  entry=005da180  size=2139 bytes
// callers/callees expanded one level from seeds

void __thiscall
FUN_005da180(undefined1 *param_1,byte *param_2,uint param_3,uint param_4,uint param_5,uint param_6,
            uint param_7,char param_8)

{
  byte bVar1;
  int iVar2;
  bool bVar3;
  uint uVar4;
  char cVar5;
  uint uVar6;
  undefined4 *puVar7;
  int iVar8;
  int *piVar9;
  uint uVar10;
  uint uVar11;
  uint uVar12;
  int local_148;
  int local_144;
  int local_140;
  int local_13c;
  uint local_138;
  uint local_134;
  uint local_130;
  undefined1 *local_12c;
  uint local_128;
  uint local_124;
  uint local_120;
  uint local_11c;
  uint local_118;
  uint local_114;
  uint local_110;
  uint local_10c;
  uint local_108;
  uint local_104;
  int local_100;
  int local_fc;
  uint local_f8;
  uint local_f4;
  int local_f0 [10];
  int local_c8;
  int local_c4;
  int local_c0;
  int local_bc;
  int local_b8;
  int local_b4;
  int local_a4 [19];
  undefined1 local_58 [76];
  void *local_c;
  undefined1 *puStack_8;
  uint local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_006215be;
  local_c = ExceptionList;
  if (((int)param_3 < (int)param_5) && ((int)param_4 < (int)param_6)) {
    bVar3 = true;
  }
  else {
    bVar3 = false;
  }
  ExceptionList = &local_c;
  local_12c = param_1;
  if (!bVar3) {
    iVar8 = *(int *)((int)param_1 + 0x14);
    iVar2 = *(int *)((int)param_1 + 0x18);
    ExceptionList = &local_c;
    FUN_00436fb0(-*(int *)((int)param_1 + 0x38));
    param_5 = iVar8 + local_134;
    param_3 = local_134;
    if ((int)param_5 <= (int)local_134) {
      param_3 = param_5;
    }
    if ((int)param_5 < (int)local_134) {
      param_5 = local_134;
    }
    uVar6 = iVar2 + local_130;
    param_4 = local_130;
    if ((int)uVar6 <= (int)local_130) {
      param_4 = uVar6;
    }
    param_6 = local_130;
    if ((int)local_130 <= (int)uVar6) {
      param_6 = uVar6;
    }
  }
  FUN_00437be0(&local_118);
  uVar6 = param_3;
  if ((int)param_3 < (int)local_118) {
    uVar6 = local_118;
  }
  uVar11 = param_5;
  if ((int)local_110 < (int)param_5) {
    uVar11 = local_110;
  }
  if ((int)uVar6 < (int)uVar11) {
    if ((int)local_114 <= (int)param_4) {
      local_114 = param_4;
    }
    if ((int)param_6 <= (int)local_10c) {
      local_10c = param_6;
    }
    if ((int)local_10c <= (int)local_114) goto LAB_005da28a;
    bVar3 = true;
  }
  else {
LAB_005da28a:
    bVar3 = false;
  }
  if (!bVar3) {
    ExceptionList = local_c;
    return;
  }
  FUN_005c9210();
  local_4 = 0;
  FUN_005c9210();
  local_4 = CONCAT31(local_4._1_3_,1);
  FUN_005e3c30(&local_134);
  uVar6 = local_130;
  local_108 = local_134;
  local_140 = local_134 + 4;
  iVar8 = 0;
  local_104 = local_130;
  local_148 = 4;
  if (local_140 < 5) {
    local_148 = local_140;
  }
  if (local_140 < 4) {
    local_140 = 4;
  }
  local_13c = local_130 + 4;
  local_144 = 4;
  if (local_13c < 5) {
    local_144 = local_13c;
  }
  if (local_13c < 4) {
    local_13c = 4;
  }
  local_128 = local_134 + 8;
  uVar12 = 0;
  local_124 = local_130 + 8;
  uVar10 = 0;
  uVar11 = 0;
  local_138 = 0;
  if (*(byte *)((int)param_1 + 0x149) != 0) {
    iVar8 = (int)((ulonglong)*(byte *)((int)param_1 + 0x14b) /
                 (ulonglong)(longlong)(int)(uint)*(byte *)((int)param_1 + 0x149));
    local_128 = local_128 + iVar8;
    local_124 = local_124 + iVar8;
    param_1 = local_12c;
  }
  uVar4 = local_128;
  local_f8 = local_128;
  local_f4 = local_124;
  bVar1 = *(byte *)((int)param_1 + 0x14c);
  local_12c = (undefined1 *)CONCAT31(local_12c._1_3_,bVar1);
  switch(bVar1) {
  case 0:
    local_138 = *(uint *)((int)param_1 + 0x144);
    uVar12 = local_138 & 0x20;
    uVar10 = local_138 & 0x40;
    goto LAB_005da456;
  case 1:
    uVar11 = *(uint *)((int)param_1 + 0x144);
    local_138 = uVar11 & 0x20;
    uVar12 = uVar11 & 0x100;
    uVar10 = uVar11 & 0x200;
    uVar11 = uVar11 & 0x40;
    local_148 = local_148 + iVar8;
    local_140 = local_140 + iVar8;
    break;
  case 2:
    uVar11 = *(uint *)((int)param_1 + 0x144);
    uVar12 = uVar11 & 0x40;
    uVar10 = uVar11 & 0x20;
    goto LAB_005da4b7;
  case 3:
    uVar10 = *(uint *)((int)param_1 + 0x144);
    uVar11 = uVar10 & 0x20;
    local_138 = uVar10 & 0x40;
    goto LAB_005da511;
  case 4:
    local_138 = *(uint *)((int)param_1 + 0x144);
    uVar12 = local_138 & 0x40;
    uVar10 = local_138 & 0x20;
LAB_005da456:
    uVar11 = local_138 & 0x100;
    local_138 = local_138 & 0x200;
    break;
  case 5:
    uVar11 = *(uint *)((int)param_1 + 0x144);
    local_138 = uVar11 & 0x40;
    uVar12 = uVar11 & 0x100;
    uVar10 = uVar11 & 0x200;
    uVar11 = uVar11 & 0x20;
    local_148 = local_148 + iVar8;
    local_140 = local_140 + iVar8;
    break;
  case 6:
    uVar11 = *(uint *)((int)param_1 + 0x144);
    uVar12 = uVar11 & 0x20;
    uVar10 = uVar11 & 0x40;
LAB_005da4b7:
    local_138 = uVar11 & 0x100;
    local_148 = local_148 + iVar8;
    uVar11 = uVar11 & 0x200;
    local_144 = local_144 + iVar8;
    local_140 = local_140 + iVar8;
    local_13c = local_13c + iVar8;
    break;
  case 7:
    uVar10 = *(uint *)((int)param_1 + 0x144);
    uVar11 = uVar10 & 0x40;
    local_138 = uVar10 & 0x20;
LAB_005da511:
    uVar12 = uVar10 & 0x200;
    uVar10 = uVar10 & 0x100;
    local_148 = local_148 + iVar8;
    local_140 = local_140 + iVar8;
    local_144 = local_144 + iVar8;
    local_13c = local_13c + iVar8;
  }
  if ((bVar1 & 1) != 0) {
    local_130 = local_134;
    local_134 = uVar6;
    local_128 = local_124;
    local_124 = uVar4;
  }
  if (uVar11 == 0) {
    uVar6 = local_130;
    if (local_138 == 0) {
      param_6 = (int)(param_4 + param_6) / 2;
      uVar6 = (int)local_130 / 2;
    }
    param_4 = param_6 - uVar6;
  }
  if (uVar12 == 0) {
    uVar6 = local_134;
    if (uVar10 == 0) {
      param_5 = (int)(param_5 + param_3) / 2;
      uVar6 = (int)local_134 / 2;
    }
    param_3 = param_5 - uVar6;
  }
  param_3 = param_3 - 4;
  uVar11 = local_128 + param_3;
  param_4 = param_4 - 4;
  uVar6 = uVar11;
  if ((int)param_3 < (int)uVar11) {
    uVar6 = param_3;
  }
  if ((int)param_3 <= (int)uVar11) {
    param_3 = uVar11;
  }
  uVar11 = local_124 + param_4;
  local_114 = param_4;
  if ((int)uVar11 <= (int)param_4) {
    local_114 = uVar11;
  }
  if ((int)param_4 <= (int)uVar11) {
    param_4 = uVar11;
  }
  local_118 = uVar6;
  local_110 = param_3;
  local_10c = param_4;
  CRect::CRect((CRect *)&local_128,*(int *)((int)param_1 + 0x28) - *(int *)((int)param_1 + 0x38),
               *(int *)((int)param_1 + 0x2c) - *(int *)((int)param_1 + 0x3c),
               *(int *)((int)param_1 + 0x30) - *(int *)((int)param_1 + 0x38),
               *(int *)((int)param_1 + 0x34) - *(int *)((int)param_1 + 0x3c));
  uVar11 = local_128;
  if ((int)local_128 < (int)uVar6) {
    uVar11 = uVar6;
  }
  uVar6 = local_120;
  if ((int)param_3 < (int)local_120) {
    uVar6 = param_3;
  }
  if ((int)uVar11 < (int)uVar6) {
    uVar6 = local_114;
    if ((int)local_114 <= (int)local_124) {
      uVar6 = local_124;
    }
    uVar11 = local_11c;
    if ((int)param_4 < (int)local_11c) {
      uVar11 = param_4;
    }
    if ((int)uVar6 < (int)uVar11) {
      bVar3 = true;
      goto LAB_005da694;
    }
  }
  bVar3 = false;
LAB_005da694:
  if ((bVar3) && (cVar5 = FUN_005c9a30(local_f8,local_f4,8,0), cVar5 != '\0')) {
    if ((local_f0[0] == 0) && (cVar5 = FUN_005cb2b0(), cVar5 == '\0')) {
      bVar3 = false;
    }
    else {
      bVar3 = true;
    }
    if (bVar3) {
      iVar8 = *(int *)((int)param_1 + 0x140);
      if (local_104 == *(byte *)(iVar8 + 0x20)) {
        while( true ) {
          if ((local_148 < local_140) && (local_144 < local_13c)) {
            bVar3 = true;
          }
          else {
            bVar3 = false;
          }
          if (((!bVar3) || (bVar1 = *param_2, bVar1 == 0)) ||
             (-1 < (int)((uint)*(byte *)(bVar1 + 0x22 + iVar8) + local_148))) break;
          local_12c = (undefined1 *)CONCAT31(local_12c._1_3_,bVar1);
          param_2 = param_2 + 1;
          local_148 = local_148 + (uint)*(byte *)(bVar1 + 0x22 + iVar8);
        }
      }
      if ((local_148 < local_140) && (local_144 < local_13c)) {
        bVar3 = true;
      }
      else {
        bVar3 = false;
      }
      if ((bVar3) && (*param_2 != 0)) {
        local_108 = local_c8 - local_b8;
        local_104 = local_c4 - local_b4;
        local_100 = local_c0 - local_b8;
        local_fc = local_bc - local_b4;
        FUN_005f8d50(param_2,&local_148,0xff,0,iVar8 + 0x22,*(undefined1 *)(iVar8 + 0x20),
                     CONCAT22((short)((uint)&local_108 >> 0x10),(ushort)*(byte *)(iVar8 + 0x21)),
                     iVar8 + 0x126,*(undefined4 *)(iVar8 + 0x328),&local_108,local_f0[0]);
      }
    }
    if (param_8 == '\0') {
      FUN_005d6230();
    }
    else {
      FUN_005d5f00();
    }
    if (*(char *)((int)param_1 + 0x14c) != '\0') {
      FUN_005d6820(local_f0);
      FUN_005cb040();
    }
    if (*(char *)((int)param_1 + 0x149) != '\0') {
      FUN_005c9210();
      local_4._0_1_ = 2;
      piVar9 = local_a4;
      if (*(char *)((int)param_1 + 0x14c) == '\0') {
        piVar9 = local_f0;
      }
      FUN_005d6590(piVar9,(int)((param_7 & 0xffff) * (uint)*(byte *)((int)param_1 + 0x149)) >> 8,
                   (int)((uint)*(byte *)((int)param_1 + 0x14b) * (param_7 & 0xffff)) >> 8);
      local_12c = &stack0xfffffea4;
      puVar7 = (undefined4 *)FUN_00436fb0(0,0);
      FUN_004690b0(local_118,local_114,local_110,local_10c,local_58,*puVar7,puVar7[1]);
      local_4 = CONCAT31(local_4._1_3_,1);
      thunk_FUN_005cb040();
    }
    piVar9 = local_a4;
    if (*(char *)((int)param_1 + 0x14c) == '\0') {
      piVar9 = local_f0;
    }
    local_104 = 0;
    local_108 = 0;
    local_128 = local_118;
    local_124 = local_114;
    local_120 = local_110;
    local_11c = local_10c;
    FUN_005d5750(&local_128,piVar9,&local_108);
  }
  local_4 = local_4 & 0xffffff00;
  thunk_FUN_005cb040();
  local_4 = 0xffffffff;
  thunk_FUN_005cb040();
  ExceptionList = local_c;
  return;
}


