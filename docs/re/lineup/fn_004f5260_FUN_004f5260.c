// FUN_004f5260  entry=004f5260  size=4469 bytes

void __thiscall FUN_004f5260(int param_1,int param_2)

{
  undefined1 uVar1;
  int iVar2;
  uint uVar3;
  undefined4 uVar4;
  undefined4 *puVar5;
  undefined4 uVar6;
  int iVar7;
  char *pcVar8;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  int iVar9;
  undefined4 extraout_ECX_02;
  undefined4 extraout_ECX_03;
  undefined4 extraout_ECX_04;
  undefined4 extraout_ECX_05;
  int iVar10;
  int iVar11;
  ulong *puVar12;
  undefined4 uVar13;
  undefined4 uVar14;
  undefined4 local_c0;
  int local_bc;
  undefined4 local_b8;
  int local_b4;
  undefined4 local_b0;
  int iStack_ac;
  undefined4 uStack_a8;
  int iStack_a4;
  ulong local_a0;
  int iStack_9c;
  ulong local_90;
  int local_8c;
  int local_84;
  int local_80;
  int local_7c;
  int local_78;
  undefined4 local_6c;
  undefined4 local_68;
  undefined1 *local_64;
  ulong local_60;
  undefined4 local_5c;
  undefined4 local_58;
  undefined4 local_54;
  undefined4 local_50 [2];
  int local_48 [2];
  undefined1 local_40 [4];
  int local_3c;
  int local_34;
  undefined1 local_30 [16];
  char local_20 [32];
  
  iVar2 = *(int *)(param_1 + 0x54);
  if (iVar2 == 0) {
    return;
  }
  FUN_00437be0(local_40,param_1 + 0x78);
  if ((*(byte *)(param_1 + 0x3f4) & 2) == 0) {
    uVar6 = 0x100;
    uVar13 = extraout_ECX;
    FUN_00436270(0xffffff);
    FUN_00468c90(local_40,uVar13,uVar6);
    uVar4 = 0x100;
    uVar6 = FUN_00468c50(0x100);
    uVar13 = extraout_ECX_00;
    FUN_004ac740(uVar6);
    uVar6 = FUN_00468be0(&local_90,1);
    FUN_00468c90(uVar6,uVar13,uVar4);
  }
  else {
    FUN_0043ca50(local_40,2,0);
  }
  if (*(int *)(param_1 + 0x418) == 0) {
    *(undefined4 *)(param_1 + 0x418) = 1;
    return;
  }
  local_80 = *(int *)(param_1 + 0x40);
  if (*(int *)(local_80 + 0x3f4) == param_1) {
    local_7c = 0xd28752;
    local_c0 = 0x2d9678;
    local_5c = 0;
    local_6c = 0xffffff;
    local_68 = 0xff;
    local_58 = 0xffffff;
    local_54 = 0xb4;
    local_50[0] = 0xb48c8c;
    local_b0 = 0xd28752;
    local_a0 = 0x2d9678;
    local_64 = (undefined1 *)0x0;
  }
  else {
    local_5c = *(undefined4 *)(param_1 + 0x60);
    local_c0 = 0x56e50;
    local_7c = 0x800000;
    local_6c = 0x800000;
    local_68 = 0xd2;
    local_58 = 0;
    local_54 = 0x96;
    local_50[0] = 0x8c6464;
    local_b0 = 0xaa5f2a;
    local_a0 = 0x56e50;
    local_64 = &LAB_0055bfd4;
  }
  local_48[0] = FUN_005836a0();
  iVar10 = local_34 - local_3c;
  iVar11 = iVar10 + -4;
  local_60 = FUN_00581e60();
  local_90 = FUN_00582db0();
  uVar13 = 0x100;
  if (local_48[0] == 0) {
    uVar6 = extraout_ECX_01;
    FUN_004ac740(&local_5c);
    uVar4 = FUN_00468be0(&local_c0,2);
    FUN_0043ce50(uVar4,uVar6,uVar13);
    puVar5 = (undefined4 *)FUN_00468c50();
    uVar13 = *puVar5;
    iVar7 = iVar11;
    uVar6 = FUN_00436fb0(0x141,2);
    FUN_0043cdb0(uVar6,iVar7,uVar13);
    iVar7 = FUN_00584d20();
    if (iVar7 != 0) {
      local_7c = 0x16;
      local_78 = 3;
      uVar13 = FUN_0058d270(*(undefined1 *)(iVar2 + 0x1a));
      puVar5 = &local_c0;
      uVar4 = 0x100;
      local_c0 = 0;
      local_bc = 0;
      uVar6 = FUN_004b7f40(local_48);
      uVar6 = FUN_00436fd0(&local_7c,uVar6);
      FUN_004f7f20(uVar6,uVar13,puVar5,uVar4);
    }
    if (DAT_00658a40 == 0) {
      local_bc = 0x70000000;
      local_c0 = 0x70000000;
      local_b4 = -0x70000000;
      local_b8 = 0x90000000;
      iVar11 = *(int *)(local_80 + 0x964) + 0x90;
      local_90 = 0xe;
      local_8c = 0;
      local_7c = 0x90;
      if (iVar11 < 0x91) {
        local_7c = iVar11;
      }
      iVar7 = 0x90;
      if (0x8f < iVar11) {
        iVar7 = iVar11;
      }
      iVar9 = *(int *)(local_80 + 0x968) + 3;
      iVar11 = 3;
      if (iVar9 < 4) {
        iVar11 = iVar9;
      }
      if (iVar9 < 3) {
        iVar9 = 3;
      }
      FUN_004f79b0(param_2,local_7c,iVar11,iVar7,iVar9,&local_90,local_80 + 0x950,local_80 + 0x9e8,
                   local_80 + 0x99c,local_80 + 0xa34,&local_c0,local_60);
      goto LAB_004f6199;
    }
    puVar5 = (undefined4 *)FUN_00468c50();
    uVar13 = *puVar5;
    iVar7 = iVar11;
    uVar6 = FUN_00436fb0(0x91,2);
    FUN_0043cdb0(uVar6,iVar7,uVar13);
    puVar5 = (undefined4 *)FUN_00468c50();
    uVar13 = *puVar5;
    iVar7 = iVar11;
    uVar6 = FUN_00436fb0(0xaa,2);
    FUN_0043cdb0(uVar6,iVar7,uVar13);
    puVar5 = (undefined4 *)FUN_00468c50();
    uVar13 = *puVar5;
    iVar7 = iVar11;
    uVar6 = FUN_00436fb0(0xc3,2);
    FUN_0043cdb0(uVar6,iVar7,uVar13);
    puVar5 = (undefined4 *)FUN_00468c50();
    uVar13 = *puVar5;
    iVar7 = iVar11;
    uVar6 = FUN_00436fb0(0xdc,2);
    FUN_0043cdb0(uVar6,iVar7,uVar13);
    puVar5 = (undefined4 *)FUN_00468c50();
    uVar13 = *puVar5;
    iVar7 = iVar11;
    uVar6 = FUN_00436fb0(0xf5,2);
    FUN_0043cdb0(uVar6,iVar7,uVar13);
    puVar5 = (undefined4 *)FUN_00468c50();
    uVar13 = *puVar5;
    iVar7 = iVar11;
    uVar6 = FUN_00436fb0(0x10e,2);
    FUN_0043cdb0(uVar6,iVar7,uVar13);
    puVar5 = (undefined4 *)FUN_00468c50();
    uVar13 = *puVar5;
    uVar6 = FUN_00436fb0(0x127,2);
    FUN_0043cdb0(uVar6,iVar11,uVar13);
    FUN_005d9d30(local_54);
    iVar11 = iVar10 + -2;
    local_b8 = 0xaa;
    local_bc = 2;
    if (iVar11 < 3) {
      local_bc = iVar11;
    }
    local_b4 = 2;
    if (1 < iVar11) {
      local_b4 = iVar11;
    }
    pcVar8 = _ultoa((uint)*(byte *)(iVar2 + 0xa8),local_20,10);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(pcVar8,0x92,local_bc,local_b8,local_b4,0x100);
    }
    else {
      FUN_005da180(pcVar8,0x92,local_bc,local_b8,local_b4,0x100,1);
    }
    FUN_005d9d30(local_50[0]);
    local_bc = 2;
    if (iVar11 < 3) {
      local_bc = iVar11;
    }
    iVar7 = 2;
    if (1 < iVar11) {
      iVar7 = iVar11;
    }
    pcVar8 = _ultoa((uint)*(byte *)(iVar2 + 0x9c),local_20,10);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(pcVar8,0xab,local_bc,0xc3,iVar7,0x100);
    }
    else {
      FUN_005da180(pcVar8,0xab,local_bc,0xc3,iVar7,0x100,1);
    }
    local_bc = 2;
    if (iVar11 < 3) {
      local_bc = iVar11;
    }
    iVar7 = 2;
    if (1 < iVar11) {
      iVar7 = iVar11;
    }
    pcVar8 = _ultoa((uint)*(byte *)(iVar2 + 0x9d),local_20,10);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(pcVar8,0xc4,local_bc,0xdc,iVar7,0x100);
    }
    else {
      FUN_005da180(pcVar8,0xc4,local_bc,0xdc,iVar7,0x100,1);
    }
    local_bc = 2;
    if (iVar11 < 3) {
      local_bc = iVar11;
    }
    iVar7 = 2;
    if (1 < iVar11) {
      iVar7 = iVar11;
    }
    pcVar8 = _ultoa((uint)*(byte *)(iVar2 + 0x9e),local_20,10);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(pcVar8,0xdd,local_bc,0xf5,iVar7,0x100);
    }
    else {
      FUN_005da180(pcVar8,0xdd,local_bc,0xf5,iVar7,0x100,1);
    }
    local_bc = 2;
    if (iVar11 < 3) {
      local_bc = iVar11;
    }
    iVar7 = 2;
    if (1 < iVar11) {
      iVar7 = iVar11;
    }
    pcVar8 = _ultoa((uint)*(byte *)(iVar2 + 0x9f),local_20,10);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(pcVar8,0xf6,local_bc,0x10e,iVar7,0x100);
    }
    else {
      FUN_005da180(pcVar8,0xf6,local_bc,0x10e,iVar7,0x100,1);
    }
    FUN_005d9d30(local_b0);
    local_bc = 2;
    if (iVar11 < 3) {
      local_bc = iVar11;
    }
    iVar7 = 2;
    if (1 < iVar11) {
      iVar7 = iVar11;
    }
    pcVar8 = _ultoa((uint)*(byte *)(iVar2 + 0xa7),local_20,10);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(pcVar8,0x10f,local_bc,0x127,iVar7,0x100);
    }
    else {
      FUN_005da180(pcVar8,0x10f,local_bc,0x127,iVar7,0x100,1);
    }
    FUN_005d9d30(local_a0);
    local_bc = 2;
    if (iVar11 < 3) {
      local_bc = iVar11;
    }
    if (iVar11 < 2) {
      iVar11 = 2;
    }
    pcVar8 = _ultoa(local_90,local_20,10);
    uVar3 = *(uint *)(param_2 + 0x144);
  }
  else {
    uVar6 = extraout_ECX_01;
    FUN_00436270(0);
    uVar4 = FUN_00468be0(local_30,1);
    FUN_00468c90(uVar4,uVar6,uVar13);
    uVar4 = 0x100;
    uVar13 = extraout_ECX_02;
    FUN_004ac740(&local_64);
    uVar6 = FUN_00468be0(local_30,2);
    FUN_0043ce50(uVar6,uVar13,uVar4);
    uVar1 = *(undefined1 *)(iVar2 + 0x1a);
    iVar7 = (**(code **)(*DAT_0066b1e0 + 0x8c))(uVar1);
    if (iVar7 != 0) {
      local_b0 = 0x16;
      iStack_ac = 3;
      uVar13 = FUN_0058d270(uVar1);
      puVar12 = &local_a0;
      uVar4 = 0x100;
      local_a0 = 0;
      iStack_9c = 0;
      uVar6 = FUN_004b7f40(local_50);
      uVar6 = FUN_00436fd0(&local_b0,uVar6);
      FUN_004f7f20(uVar6,uVar13,puVar12,uVar4);
    }
    uVar6 = 0;
    iVar7 = iVar11;
    uVar13 = FUN_00436fb0(0x141,2);
    FUN_0043cdb0(uVar13,iVar7,uVar6);
    uVar6 = 0;
    iVar7 = iVar11;
    uVar13 = FUN_00436fb0(0x91,2);
    FUN_0043cdb0(uVar13,iVar7,uVar6);
    iVar9 = local_48[0];
    uVar6 = 0x100;
    local_b0 = 0x92;
    iStack_ac = 2;
    local_a0 = 0;
    iStack_9c = 0;
    iVar7 = local_80 + 0xa34 + local_48[0] * 0x4c;
    puVar12 = &local_a0;
    uVar13 = FUN_004b7f40(local_50);
    uVar13 = FUN_00436fd0(&local_b0,uVar13);
    FUN_004f7f20(uVar13,iVar7,puVar12,uVar6);
    uVar6 = 0;
    iVar7 = iVar11;
    uVar13 = FUN_00436fb0(0x10e,2);
    FUN_0043cdb0(uVar13,iVar7,uVar6);
    uVar6 = 0;
    iVar7 = iVar11;
    uVar13 = FUN_00436fb0(0x127,2);
    FUN_0043cdb0(uVar13,iVar7,uVar6);
    uVar13 = 0;
    if (iVar9 == 6) {
      uVar6 = FUN_00436fb0(0xaa,2);
      FUN_0043cdb0(uVar6,iVar11,uVar13);
      uVar14 = 0x100;
      uVar13 = extraout_ECX_03;
      FUN_00437020(0xaa,0x7f,0);
      uVar6 = FUN_00436fb0(99,0xc);
      uVar4 = FUN_00436fb0(0xab,2);
      uVar6 = FUN_00436fd0(uVar4,uVar6);
      FUN_0043ce50(uVar6,uVar13,uVar14);
      FUN_005d9d30(0xffff);
      iVar11 = iVar10 + -2;
      iStack_9c = 2;
      if (iVar11 < 3) {
        iStack_9c = iVar11;
      }
      iVar7 = 2;
      if (1 < iVar11) {
        iVar7 = iVar11;
      }
      if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
        pcVar8 = s_YELLOW_CARD_00658a30;
        uVar13 = 0xab;
        iVar11 = iStack_9c;
LAB_004f6037:
        FUN_005d9d80(pcVar8,uVar13,iVar11,0x10e,iVar7,0x100);
      }
      else {
        FUN_005da180(s_YELLOW_CARD_00658a30,0xab,iStack_9c,0x10e,iVar7,0x100,1);
      }
    }
    else {
      iVar7 = iVar11;
      uVar6 = FUN_00436fb0(0xaa,2);
      FUN_0043cdb0(uVar6,iVar7,uVar13);
      uVar14 = 0x100;
      uVar13 = extraout_ECX_04;
      FUN_00437020(0x55,0x3f,0);
      uVar6 = FUN_00436fb0(0x18,0xc);
      uVar4 = FUN_00436fb0(0xab,2);
      uVar6 = FUN_00436fd0(uVar4,uVar6);
      FUN_0043ce50(uVar6,uVar13,uVar14);
      uVar6 = 0;
      uVar13 = FUN_00436fb0(0xc3,2);
      FUN_0043cdb0(uVar13,iVar11,uVar6);
      uVar14 = 0x100;
      uVar13 = extraout_ECX_05;
      FUN_00437020(0xaa,0x7f,0);
      uVar6 = FUN_00436fb0(0x4a,0xc);
      uVar4 = FUN_00436fb0(0xc4,2);
      uVar6 = FUN_00436fd0(uVar4,uVar6);
      FUN_0043ce50(uVar6,uVar13,uVar14);
      local_a0 = FUN_005836c0();
      FUN_005d9d30(0xffff);
      iVar11 = iVar10 + -2;
      local_b0 = 0xab;
      uStack_a8 = 0xc3;
      iStack_ac = 2;
      if (iVar11 < 3) {
        iStack_ac = iVar11;
      }
      iStack_a4 = 2;
      if (1 < iVar11) {
        iStack_a4 = iVar11;
      }
      pcVar8 = _ultoa(local_a0,local_20,10);
      if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
        FUN_005d9d80(pcVar8,local_b0,iStack_ac,uStack_a8,iStack_a4,0x100);
      }
      else {
        FUN_005da180(pcVar8,local_b0,iStack_ac,uStack_a8,iStack_a4,0x100,1);
      }
      FUN_005d9d30(0);
      iStack_ac = 2;
      if (iVar11 < 3) {
        iStack_ac = iVar11;
      }
      iVar7 = 2;
      if (1 < iVar11) {
        iVar7 = iVar11;
      }
      pcVar8 = (char *)FUN_005836e0(local_48[0],local_a0);
      if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
        uVar13 = 0xc4;
        iVar11 = iStack_ac;
        goto LAB_004f6037;
      }
      FUN_005da180(pcVar8,0xc4,iStack_ac,0x10e,iVar7,0x100,1);
    }
    iVar11 = iVar10 + -2;
    FUN_005d9d30(local_7c);
    local_78 = 2;
    if (iVar11 < 3) {
      local_78 = iVar11;
    }
    iVar7 = 2;
    if (1 < iVar11) {
      iVar7 = iVar11;
    }
    pcVar8 = _ultoa((uint)*(byte *)(iVar2 + 0xa7),local_20,10);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(pcVar8,0x10f,local_78,0x127,iVar7,0x100);
    }
    else {
      FUN_005da180(pcVar8,0x10f,local_78,0x127,iVar7,0x100,1);
    }
    FUN_005d9d30(local_c0);
    local_bc = 2;
    if (iVar11 < 3) {
      local_bc = iVar11;
    }
    if (iVar11 < 2) {
      iVar11 = 2;
    }
    pcVar8 = _ultoa(local_90,local_20,10);
    uVar3 = *(uint *)(param_2 + 0x144);
  }
  if ((uVar3 >> 3 & 1) == 0) {
    FUN_005d9d80(pcVar8,0x128,local_bc,0x140,iVar11,0x100);
  }
  else {
    FUN_005da180(pcVar8,0x128,local_bc,0x140,iVar11,0x100,1);
  }
LAB_004f6199:
  FUN_005d9d30(local_6c);
  iVar10 = iVar10 + -2;
  local_8c = 2;
  if (iVar10 < 3) {
    local_8c = iVar10;
  }
  local_84 = 2;
  if (1 < iVar10) {
    local_84 = iVar10;
  }
  pcVar8 = _ultoa((uint)*(byte *)(iVar2 + 0xf8),local_20,10);
  if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(pcVar8,3,local_8c,0x18,local_84,0x100);
  }
  else {
    FUN_005da180(pcVar8,3,local_8c,0x18,local_84,0x100,1);
  }
  FUN_005d9d30(local_68);
  local_8c = 2;
  if (iVar10 < 3) {
    local_8c = iVar10;
  }
  iVar11 = 2;
  if (1 < iVar10) {
    iVar11 = iVar10;
  }
  pcVar8 = _ultoa(local_60,local_20,10);
  if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(pcVar8,0x142,local_8c,0x15a,iVar11,0x100);
  }
  else {
    FUN_005da180(pcVar8,0x142,local_8c,0x15a,iVar11,0x100,1);
  }
  FUN_005d9d30(local_58);
  uVar3 = *(uint *)(param_2 + 0x144);
  *(uint *)(param_2 + 0x144) = uVar3 | 0x20;
  iVar11 = 2;
  if (iVar10 < 3) {
    iVar11 = iVar10;
  }
  if (iVar10 < 2) {
    iVar10 = 2;
  }
  if ((uVar3 & 8) == 0) {
    FUN_005d9d80(*(undefined4 *)(iVar2 + 4),0x27,iVar11,0x8e,iVar10,0x100);
    *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffffdf;
    return;
  }
  FUN_005da180(*(undefined4 *)(iVar2 + 4),0x27,iVar11,0x8e,iVar10,0x100,1);
  *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffffdf;
  return;
}


