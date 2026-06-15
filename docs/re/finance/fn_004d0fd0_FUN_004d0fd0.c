// FUN_004d0fd0  entry=004d0fd0  size=8764 bytes

void FUN_004d0fd0(ushort **param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  ushort *puVar4;
  ushort *puVar5;
  ushort *puVar6;
  ushort *extraout_ECX;
  ushort *extraout_ECX_00;
  ushort *extraout_ECX_01;
  ushort *extraout_ECX_02;
  ushort *extraout_ECX_03;
  ushort *extraout_ECX_04;
  ushort *extraout_ECX_05;
  ushort *extraout_ECX_06;
  ushort *extraout_ECX_07;
  ushort *extraout_ECX_08;
  ushort *extraout_ECX_09;
  ushort *extraout_ECX_10;
  ushort *extraout_ECX_11;
  ushort *extraout_ECX_12;
  ushort *extraout_ECX_13;
  ushort *extraout_ECX_14;
  ushort *extraout_ECX_15;
  ushort *extraout_ECX_16;
  ushort *extraout_ECX_17;
  ushort *extraout_ECX_18;
  ushort *extraout_ECX_19;
  ushort *extraout_ECX_20;
  int iVar7;
  ushort *puVar8;
  int iVar9;
  ushort **ppuVar10;
  undefined1 *puVar11;
  ushort *local_13c;
  ushort **local_138;
  ushort *local_124;
  int local_120;
  undefined1 *local_11c;
  ushort *local_118;
  ushort *local_114;
  ushort *local_110;
  int local_10c;
  ushort *local_108;
  int local_104;
  undefined1 *local_100;
  ushort *local_fc;
  int local_f8;
  undefined1 local_ec [8];
  undefined1 local_e4 [8];
  ushort *local_dc;
  int local_d8;
  undefined1 local_bc [24];
  undefined1 local_a4 [76];
  undefined1 local_58 [76];
  void *local_c;
  undefined1 *puStack_8;
  uint local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00614ac3;
  local_c = ExceptionList;
  local_138 = param_1;
  local_13c = (ushort *)0x4d1000;
  ExceptionList = &local_c;
  FUN_004fb0b0();
  local_138 = (ushort **)0x4d100c;
  FUN_005c9210();
  local_4 = 0;
  local_138 = (ushort **)0x4d1023;
  FUN_005c9210();
  local_124 = (ushort *)&local_138;
  local_13c = (ushort *)0x2;
  local_4 = CONCAT31(local_4._1_3_,1);
  local_138 = (ushort **)0x0;
  uVar1 = FUN_00436fb0(0x1f2,0x68);
  uVar2 = FUN_00436fb0(0,10);
  ppuVar10 = &local_dc;
  FUN_00436fb0(0xb,0x4a);
  uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ca50(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0);
  uVar1 = FUN_00436fb0(0x1ee,0x14);
  uVar2 = FUN_00436fb0(0,10);
  ppuVar10 = &local_dc;
  FUN_00436fb0(0xd,0x4c);
  uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0xffffff);
  uVar1 = FUN_00436fb0(0x1ee,0x50);
  uVar2 = FUN_00436fb0(0,10);
  ppuVar10 = &local_dc;
  FUN_00436fb0(0xd,0x60);
  uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_138 = (ushort **)s_Proman12_00652eb0;
  local_13c = (ushort *)0x4d114d;
  FUN_005d9d50();
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  local_138 = (ushort **)0xffffff;
  local_13c = (ushort *)0x4d116f;
  FUN_005d9d30();
  local_138 = (ushort **)0x42;
  local_13c = (ushort *)0xd;
  FUN_00436fb0();
  puVar4 = local_124 + 0xf7;
  puVar8 = local_124;
  if ((int)puVar4 <= (int)local_124) {
    puVar8 = puVar4;
  }
  puVar6 = local_124;
  if ((int)local_124 <= (int)puVar4) {
    puVar6 = puVar4;
  }
  iVar9 = local_120 + 0x14;
  iVar7 = local_120;
  if (iVar9 <= local_120) {
    iVar7 = iVar9;
  }
  if (iVar9 < local_120) {
    iVar9 = local_120;
  }
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_PREMIER_LEAGUE_00652e34,puVar8,iVar7,puVar6,iVar9);
  local_138 = (ushort **)s_Proman10_00652e9c;
  local_13c = (ushort *)0x4d11d8;
  FUN_005d9d50();
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffffbf | 0x20);
  local_138 = (ushort **)0x0;
  local_13c = (ushort *)0x4d11fe;
  FUN_005d9d30();
  local_138 = (ushort **)0x56;
  local_13c = (ushort *)0x31;
  FUN_00436fb0();
  puVar4 = (ushort *)((int)local_124 + 0x7d);
  puVar8 = local_124;
  if ((int)puVar4 <= (int)local_124) {
    puVar8 = puVar4;
  }
  puVar6 = local_124;
  if ((int)local_124 <= (int)puVar4) {
    puVar6 = puVar4;
  }
  iVar9 = local_120 + 0xd;
  iVar7 = local_120;
  if (iVar9 <= local_120) {
    iVar7 = iVar9;
  }
  iVar3 = local_120;
  if (local_120 <= iVar9) {
    iVar3 = iVar9;
  }
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_CHAMPION_00656e60,puVar8,iVar7,puVar6,iVar3);
  local_138 = (ushort **)0x7a;
  local_13c = (ushort *)0x31;
  FUN_00436fb0();
  puVar4 = (ushort *)((int)local_124 + 0x7d);
  puVar8 = local_124;
  if ((int)puVar4 <= (int)local_124) {
    puVar8 = puVar4;
  }
  puVar6 = local_124;
  if ((int)local_124 <= (int)puVar4) {
    puVar6 = puVar4;
  }
  iVar9 = local_120 + 0xe;
  iVar7 = local_120;
  if (iVar9 <= local_120) {
    iVar7 = iVar9;
  }
  if (iVar9 < local_120) {
    iVar9 = local_120;
  }
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_RUNNER_UP_00654cec,puVar8,iVar7,puVar6,iVar9);
  local_138 = (ushort **)0x56;
  local_13c = (ushort *)0xb9;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  FUN_00436fb0();
  puVar4 = local_124 + 0x4a;
  puVar8 = local_124;
  if ((int)puVar4 <= (int)local_124) {
    puVar8 = puVar4;
  }
  puVar6 = local_124;
  if ((int)local_124 <= (int)puVar4) {
    puVar6 = puVar4;
  }
  iVar9 = local_120 + 0xc;
  iVar7 = local_120;
  if (iVar9 <= local_120) {
    iVar7 = iVar9;
  }
  iVar3 = local_120;
  if (local_120 <= iVar9) {
    iVar3 = iVar9;
  }
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_U_E_F_A__CUP_006538d4,puVar8,iVar7,puVar6,iVar3);
  local_138 = (ushort **)0x56;
  local_13c = (ushort *)0x159;
  FUN_00436fb0();
  puVar4 = local_124 + 0x4a;
  puVar8 = local_124;
  if ((int)puVar4 <= (int)local_124) {
    puVar8 = puVar4;
  }
  if ((int)puVar4 < (int)local_124) {
    puVar4 = local_124;
  }
  iVar9 = local_120 + 0xc;
  iVar7 = local_120;
  if (iVar9 <= local_120) {
    iVar7 = iVar9;
  }
  iVar3 = local_120;
  if (local_120 <= iVar9) {
    iVar3 = iVar9;
  }
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_RELEGATED_00656e54,puVar8,iVar7,puVar4,iVar3);
  local_138 = (ushort **)s_Proman8_00652ea8;
  local_13c = (ushort *)0x4d138d;
  FUN_005d9d50();
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0);
  uVar1 = FUN_00436fb0(0x9e,0x17);
  uVar2 = FUN_00436fb0(0,10);
  ppuVar10 = &local_dc;
  FUN_00436fb0(0x10,0x6d);
  uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_00468c90(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00437020(0,0,0x80);
  uVar1 = FUN_00436fb0(0x9c,0x15);
  uVar2 = FUN_00436fb0(0,10);
  ppuVar10 = &local_dc;
  FUN_00436fb0(0x11,0x6e);
  uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  puVar11 = local_100;
  if (*(ushort *)((int)local_100 + 0x2570) != 0) {
    local_138 = (ushort **)(uint)*(ushort *)((int)local_100 + 0x2570);
    local_13c = (ushort *)0x4d1472;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d1479;
    puVar4 = (ushort *)FUN_00579730();
    local_138 = (ushort **)(uint)*(ushort *)((int)puVar11 + 0x2570);
    local_13c = (ushort *)0x4d148f;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d1496;
    local_11c = (undefined1 *)FUN_00579390();
    if ((puVar4 != (ushort *)0x0) && (local_11c != (undefined1 *)0x0)) {
      local_138 = (ushort **)0x100;
      local_13c = puVar4;
      FUN_005d66f0();
      local_138 = (ushort **)0x100;
      local_13c = (ushort *)0x80;
      FUN_005d6590(local_58,0x40);
      iVar9 = *(int *)(puVar4 + 0xc);
      local_fc = (ushort *)0x0;
      local_f8 = 0;
      local_118 = (ushort *)0x0;
      local_114 = (ushort *)0x0;
      iVar7 = *(int *)(puVar4 + 10);
      local_138 = (ushort **)(0x77 - iVar9 / 2);
      local_13c = (ushort *)(0x1a - iVar7 / 2);
      FUN_00436fb0();
      local_138 = (ushort **)(local_120 + -10);
      local_13c = local_124;
      FUN_00436fb0();
      puVar8 = (ushort *)(iVar7 + (int)local_dc);
      local_110 = local_dc;
      if ((int)puVar8 <= (int)local_dc) {
        local_110 = puVar8;
      }
      local_108 = local_dc;
      if ((int)local_dc <= (int)puVar8) {
        local_108 = puVar8;
      }
      local_10c = local_d8;
      iVar9 = local_d8 + iVar9;
      if (iVar9 <= local_d8) {
        local_10c = iVar9;
      }
      local_104 = local_d8;
      if (local_d8 <= iVar9) {
        local_104 = iVar9;
      }
      local_138 = &local_fc;
      local_13c = puVar4;
      FUN_005d5220(&local_110,local_a4,&local_118);
      local_124 = (ushort *)&local_138;
      param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffffbf | 0x20);
      local_138 = (ushort **)0xffffff;
      local_13c = (ushort *)0x4d15b1;
      FUN_005d9d30();
      local_138 = (ushort **)0x64;
      local_13c = (ushort *)0x32;
      FUN_00436fb0();
      puVar4 = (ushort *)((int)local_118 + 0x7b);
      puVar8 = local_118;
      if ((int)puVar4 <= (int)local_118) {
        puVar8 = puVar4;
      }
      puVar6 = local_118;
      if ((int)local_118 <= (int)puVar4) {
        puVar6 = puVar4;
      }
      puVar4 = (ushort *)((int)local_114 + 0x15);
      puVar5 = local_114;
      if ((int)puVar4 <= (int)local_114) {
        puVar5 = puVar4;
      }
      local_13c = local_114;
      if ((int)local_114 <= (int)puVar4) {
        local_13c = puVar4;
      }
      local_138 = (ushort **)0x100;
      FUN_005d9d80(local_11c,puVar8,puVar5,puVar6);
    }
  }
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0);
  uVar1 = FUN_00436fb0(0x9e,0x17);
  uVar2 = FUN_00436fb0(0,10);
  ppuVar10 = &local_dc;
  FUN_00436fb0(0x10,0x92);
  uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_00468c90(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00437020(0,0,0x80);
  uVar1 = FUN_00436fb0(0x9c,0x15);
  uVar2 = FUN_00436fb0(0,10);
  ppuVar10 = &local_dc;
  FUN_00436fb0(0x11,0x93);
  uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  puVar11 = local_100;
  if (*(ushort *)((int)local_100 + 0x2572) != 0) {
    local_138 = (ushort **)(uint)*(ushort *)((int)local_100 + 0x2572);
    local_13c = (ushort *)0x4d16f4;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d16fb;
    puVar4 = (ushort *)FUN_00579730();
    local_138 = (ushort **)(uint)*(ushort *)((int)puVar11 + 0x2572);
    local_13c = (ushort *)0x4d1711;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d1718;
    local_11c = (undefined1 *)FUN_00579390();
    if ((puVar4 != (ushort *)0x0) && (local_11c != (undefined1 *)0x0)) {
      local_138 = (ushort **)0x100;
      local_13c = puVar4;
      FUN_005d66f0();
      local_138 = (ushort **)0x100;
      local_13c = (ushort *)0x80;
      FUN_005d6590(local_58,0x40);
      iVar9 = *(int *)(puVar4 + 0xc);
      local_dc = (ushort *)0x0;
      local_d8 = 0;
      local_124 = (ushort *)0x0;
      local_120 = 0;
      iVar7 = *(int *)(puVar4 + 10);
      local_138 = (ushort **)(0x9c - iVar9 / 2);
      local_13c = (ushort *)(0x1a - iVar7 / 2);
      FUN_00436fb0();
      local_138 = (ushort **)(local_114 + -5);
      local_13c = local_118;
      FUN_00436fb0();
      puVar8 = (ushort *)(iVar7 + (int)local_fc);
      local_110 = local_fc;
      if ((int)puVar8 <= (int)local_fc) {
        local_110 = puVar8;
      }
      local_108 = local_fc;
      if ((int)local_fc <= (int)puVar8) {
        local_108 = puVar8;
      }
      local_10c = local_f8;
      iVar9 = local_f8 + iVar9;
      if (iVar9 <= local_f8) {
        local_10c = iVar9;
      }
      local_104 = local_f8;
      if (local_f8 <= iVar9) {
        local_104 = iVar9;
      }
      local_138 = &local_dc;
      local_13c = puVar4;
      FUN_005d5220(&local_110,local_a4,&local_124);
      local_124 = (ushort *)&local_138;
      param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffffbf | 0x20);
      local_138 = (ushort **)0xffffff;
      local_13c = (ushort *)0x4d1833;
      FUN_005d9d30();
      local_138 = (ushort **)0x89;
      local_13c = (ushort *)0x32;
      FUN_00436fb0();
      puVar4 = local_118 + 0x3e;
      puVar8 = local_118;
      if ((int)puVar4 <= (int)local_118) {
        puVar8 = puVar4;
      }
      puVar6 = local_118;
      if ((int)local_118 <= (int)puVar4) {
        puVar6 = puVar4;
      }
      puVar4 = (ushort *)((int)local_114 + 0x15);
      puVar5 = local_114;
      if ((int)puVar4 <= (int)local_114) {
        puVar5 = puVar4;
      }
      local_13c = local_114;
      if ((int)local_114 <= (int)puVar4) {
        local_13c = puVar4;
      }
      local_138 = (ushort **)0x100;
      FUN_005d9d80(local_11c,puVar8,puVar5,puVar6);
    }
  }
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  local_138 = (ushort **)0x0;
  local_13c = (ushort *)0x4d18b1;
  FUN_005d9d30();
  iVar9 = 0x6c;
  local_124 = (ushort *)((int)local_100 + 0x2574);
  local_13c = extraout_ECX;
  do {
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00436270(0);
    uVar1 = FUN_00436fb0(0x94,0xe);
    uVar2 = FUN_00436fb0(0,10);
    puVar11 = local_bc;
    FUN_00436fb0(0xb9,iVar9);
    uVar2 = FUN_004a9bc0(puVar11,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_00468c90(uVar1);
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00437020(0xc0,0xe3,0xc0);
    uVar1 = FUN_00436fb0(0x92,0xc);
    uVar2 = FUN_00436fb0(0,10);
    puVar11 = local_e4;
    FUN_00436fb0(0xba,iVar9 + 1);
    uVar2 = FUN_004a9bc0(puVar11,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_13c = local_124;
    if (*local_124 != 0) {
      local_138 = (ushort **)(uint)*local_124;
      local_13c = (ushort *)0x4d19ba;
      FUN_00585ee0();
      local_138 = (ushort **)0x4d19c1;
      local_11c = (undefined1 *)FUN_00579390();
      local_13c = extraout_ECX_00;
      if (local_11c != (undefined1 *)0x0) {
        local_138 = (ushort **)(iVar9 + -10);
        local_13c = (ushort *)0xb9;
        FUN_00436fb0();
        puVar4 = local_118 + 0x4a;
        puVar8 = local_118;
        if ((int)puVar4 <= (int)local_118) {
          puVar8 = puVar4;
        }
        if ((int)puVar4 < (int)local_118) {
          puVar4 = local_118;
        }
        puVar6 = local_114 + 7;
        puVar5 = local_114;
        if ((int)puVar6 <= (int)local_114) {
          puVar5 = puVar6;
        }
        local_13c = local_114;
        if ((int)local_114 <= (int)puVar6) {
          local_13c = puVar6;
        }
        local_138 = (ushort **)0x100;
        FUN_005d9d80(local_11c,puVar8,puVar5,puVar4);
        local_13c = extraout_ECX_01;
      }
    }
    iVar9 = iVar9 + 0x11;
    local_124 = local_124 + 1;
  } while (iVar9 < 0xb0);
  iVar9 = 0x6c;
  local_13c = (ushort *)((int)local_100 + 0x257c);
  local_124 = local_13c;
  do {
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00436270(0);
    uVar1 = FUN_00436fb0(0x94,0xe);
    uVar2 = FUN_00436fb0(0,10);
    puVar11 = local_ec;
    FUN_00436fb0(0x159,iVar9);
    uVar2 = FUN_004a9bc0(puVar11,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_00468c90(uVar1);
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00437020(0xff,0xff,0xaa);
    uVar1 = FUN_00436fb0(0x92,0xc);
    uVar2 = FUN_00436fb0(0,10);
    ppuVar10 = &local_fc;
    FUN_00436fb0(0x15a,iVar9 + 1);
    uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_13c = extraout_ECX_02;
    if (*local_124 != 0) {
      local_138 = (ushort **)(uint)*local_124;
      local_13c = (ushort *)0x4d1b4e;
      FUN_00585ee0();
      local_138 = (ushort **)0x4d1b55;
      local_11c = (undefined1 *)FUN_00579390();
      local_13c = extraout_ECX_03;
      if (local_11c != (undefined1 *)0x0) {
        local_138 = (ushort **)(iVar9 + -10);
        local_13c = (ushort *)0x159;
        FUN_00436fb0();
        puVar4 = local_118 + 0x4a;
        puVar8 = local_118;
        if ((int)puVar4 <= (int)local_118) {
          puVar8 = puVar4;
        }
        if ((int)puVar4 < (int)local_118) {
          puVar4 = local_118;
        }
        puVar6 = local_114 + 7;
        puVar5 = local_114;
        if ((int)puVar6 <= (int)local_114) {
          puVar5 = puVar6;
        }
        local_13c = local_114;
        if ((int)local_114 <= (int)puVar6) {
          local_13c = puVar6;
        }
        local_138 = (ushort **)0x100;
        FUN_005d9d80(local_11c,puVar8,puVar5,puVar4);
        local_13c = extraout_ECX_04;
      }
    }
    iVar9 = iVar9 + 0x11;
    local_124 = local_124 + 1;
  } while (iVar9 < 0x9f);
  local_124 = (ushort *)&local_138;
  local_13c = (ushort *)0x2;
  local_138 = (ushort **)0x0;
  uVar1 = FUN_00436fb0(0x1f2,0x57);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0xb,0xb5);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ca50(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0);
  uVar1 = FUN_00436fb0(0x1ee,0x14);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0xd,0xb7);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0xffffff);
  uVar1 = FUN_00436fb0(0x1ee,0x3f);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0xd,0xcb);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_138 = (ushort **)s_Proman12_00652eb0;
  local_13c = (ushort *)0x4d1d03;
  FUN_005d9d50();
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  local_138 = (ushort **)0xffffff;
  local_13c = (ushort *)0x4d1d2a;
  FUN_005d9d30();
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_1ST_DIVISION_00656e44,0xd,0xad,0x1fb,0xc1);
  local_138 = (ushort **)s_Proman10_00652e9c;
  local_13c = (ushort *)0x4d1d6d;
  FUN_005d9d50();
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffffbf | 0x20);
  local_138 = (ushort **)0x0;
  local_13c = (ushort *)0x4d1d93;
  FUN_005d9d30();
  local_138 = (ushort **)0xcb;
  local_13c = (ushort *)0x31;
  FUN_00436fb0();
  puVar4 = (ushort *)((int)local_118 + 0x7d);
  puVar8 = local_118;
  if ((int)puVar4 <= (int)local_118) {
    puVar8 = puVar4;
  }
  puVar6 = local_118;
  if ((int)local_118 <= (int)puVar4) {
    puVar6 = puVar4;
  }
  puVar4 = (ushort *)((int)local_114 + 0xf);
  puVar5 = local_114;
  if ((int)puVar4 <= (int)local_114) {
    puVar5 = puVar4;
  }
  if ((int)puVar4 < (int)local_114) {
    puVar4 = local_114;
  }
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_CHAMPION_00656e60,puVar8,puVar5,puVar6,puVar4);
  local_138 = (ushort **)0xc1;
  local_13c = (ushort *)0xb9;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  FUN_00436fb0();
  puVar4 = local_118 + 0x4a;
  puVar8 = local_118;
  if ((int)puVar4 <= (int)local_118) {
    puVar8 = puVar4;
  }
  puVar6 = local_118;
  if ((int)local_118 <= (int)puVar4) {
    puVar6 = puVar4;
  }
  puVar4 = local_114 + 5;
  puVar5 = local_114;
  if ((int)puVar4 <= (int)local_114) {
    puVar5 = puVar4;
  }
  if ((int)puVar4 < (int)local_114) {
    puVar4 = local_114;
  }
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_PROMOTED_00656e38,puVar8,puVar5,puVar6,puVar4);
  local_138 = (ushort **)0xc1;
  local_13c = (ushort *)0x159;
  FUN_00436fb0();
  puVar4 = local_118 + 0x4a;
  puVar8 = local_118;
  if ((int)puVar4 <= (int)local_118) {
    puVar8 = puVar4;
  }
  puVar6 = local_118;
  if ((int)local_118 <= (int)puVar4) {
    puVar6 = puVar4;
  }
  puVar4 = local_114 + 5;
  puVar5 = local_114;
  if ((int)puVar4 <= (int)local_114) {
    puVar5 = puVar4;
  }
  if ((int)puVar4 < (int)local_114) {
    puVar4 = local_114;
  }
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_RELEGATED_00656e54,puVar8,puVar5,puVar6,puVar4);
  local_138 = (ushort **)s_Proman8_00652ea8;
  local_13c = (ushort *)0x4d1ed0;
  FUN_005d9d50();
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0);
  uVar1 = FUN_00436fb0(0x9e,0x16);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0x10,0xe4);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_00468c90(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00437020(0,0,0x80);
  uVar1 = FUN_00436fb0(0x9c,0x14);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0x11,0xe5);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  puVar11 = local_100;
  if (*(ushort *)((int)local_100 + 0x2584) != 0) {
    local_138 = (ushort **)(uint)*(ushort *)((int)local_100 + 0x2584);
    local_13c = (ushort *)0x4d1fbb;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d1fc2;
    puVar4 = (ushort *)FUN_00579730();
    local_138 = (ushort **)(uint)*(ushort *)((int)puVar11 + 0x2584);
    local_13c = (ushort *)0x4d1fd8;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d1fdf;
    local_11c = (undefined1 *)FUN_00579390();
    if ((puVar4 != (ushort *)0x0) && (local_11c != (undefined1 *)0x0)) {
      local_138 = (ushort **)0x100;
      local_13c = puVar4;
      FUN_005d66f0();
      local_138 = (ushort **)0x100;
      local_13c = (ushort *)0x80;
      FUN_005d6590(local_58,0x40);
      local_118 = (ushort *)0x0;
      local_114 = (ushort *)0x0;
      local_fc = (ushort *)0x0;
      local_f8 = 0;
      local_108 = (ushort *)(0x1a - *(int *)(puVar4 + 10) / 2);
      puVar8 = (ushort *)(*(int *)(puVar4 + 10) + (int)local_108);
      local_104 = 0xe3 - *(int *)(puVar4 + 0xc) / 2;
      local_110 = local_108;
      if ((int)puVar8 <= (int)local_108) {
        local_110 = puVar8;
      }
      if ((int)local_108 <= (int)puVar8) {
        local_108 = puVar8;
      }
      iVar9 = local_104 + *(int *)(puVar4 + 0xc);
      local_10c = local_104;
      if (iVar9 <= local_104) {
        local_10c = iVar9;
      }
      if (local_104 <= iVar9) {
        local_104 = iVar9;
      }
      local_138 = &local_118;
      local_13c = puVar4;
      FUN_005d5220(&local_110,local_a4,&local_fc);
      local_124 = (ushort *)&local_138;
      param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffffbf | 0x20);
      local_138 = (ushort **)0xffffff;
      local_13c = (ushort *)0x4d20d5;
      FUN_005d9d30();
      local_138 = (ushort **)0x100;
      local_13c = (ushort *)0xef;
      FUN_005d9d80(local_11c,0x31,0xdb,0xad);
    }
  }
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  local_138 = (ushort **)0x0;
  local_13c = (ushort *)0x4d212d;
  FUN_005d9d30();
  iVar9 = 0xd5;
  local_124 = (ushort *)((int)local_100 + 0x2586);
  local_13c = extraout_ECX_05;
  do {
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00436270(0);
    uVar1 = FUN_00436fb0(0x94,0xe);
    uVar2 = FUN_00436fb0(0,10);
    puVar11 = local_ec;
    FUN_00436fb0(0xb9,iVar9);
    uVar2 = FUN_004a9bc0(puVar11,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_00468c90(uVar1);
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00437020(0xc0,0xe3,0xc0);
    uVar1 = FUN_00436fb0(0x92,0xc);
    uVar2 = FUN_00436fb0(0,10);
    ppuVar10 = &local_118;
    FUN_00436fb0(0xba,iVar9 + 1);
    uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_13c = local_124;
    if (*local_124 != 0) {
      local_138 = (ushort **)(uint)*local_124;
      local_13c = (ushort *)0x4d2232;
      FUN_00585ee0();
      local_138 = (ushort **)0x4d2239;
      local_11c = (undefined1 *)FUN_00579390();
      local_13c = extraout_ECX_06;
      if (local_11c != (undefined1 *)0x0) {
        local_13c = (ushort *)(iVar9 + -10);
        puVar4 = (ushort *)(iVar9 + 4);
        puVar8 = local_13c;
        if ((int)puVar4 <= (int)local_13c) {
          puVar8 = puVar4;
        }
        if ((int)local_13c <= (int)puVar4) {
          local_13c = puVar4;
        }
        local_138 = (ushort **)0x100;
        FUN_005d9d80(local_11c,0xb9,puVar8,0x14d);
        local_13c = extraout_ECX_07;
      }
    }
    iVar9 = iVar9 + 0x11;
    local_124 = local_124 + 1;
  } while (iVar9 < 0x108);
  iVar9 = 0xd5;
  local_13c = (ushort *)((int)local_100 + 0x258c);
  local_124 = local_13c;
  do {
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00436270(0);
    uVar1 = FUN_00436fb0(0x94,0xe);
    uVar2 = FUN_00436fb0(0,10);
    puVar11 = local_ec;
    FUN_00436fb0(0x159,iVar9);
    uVar2 = FUN_004a9bc0(puVar11,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_00468c90(uVar1);
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00437020(0xff,0xff,0xaa);
    uVar1 = FUN_00436fb0(0x92,0xc);
    uVar2 = FUN_00436fb0(0,10);
    ppuVar10 = &local_118;
    FUN_00436fb0(0x15a,iVar9 + 1);
    uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_13c = extraout_ECX_08;
    if (*local_124 != 0) {
      local_138 = (ushort **)(uint)*local_124;
      local_13c = (ushort *)0x4d23a0;
      FUN_00585ee0();
      local_138 = (ushort **)0x4d23a7;
      local_11c = (undefined1 *)FUN_00579390();
      local_13c = extraout_ECX_09;
      if (local_11c != (undefined1 *)0x0) {
        local_13c = (ushort *)(iVar9 + -10);
        puVar4 = (ushort *)(iVar9 + 4);
        puVar8 = local_13c;
        if ((int)puVar4 <= (int)local_13c) {
          puVar8 = puVar4;
        }
        if ((int)local_13c <= (int)puVar4) {
          local_13c = puVar4;
        }
        local_138 = (ushort **)0x100;
        FUN_005d9d80(local_11c,0x159,puVar8,0x1ed);
        local_13c = extraout_ECX_10;
      }
    }
    iVar9 = iVar9 + 0x11;
    local_124 = local_124 + 1;
  } while (iVar9 < 0x108);
  local_124 = (ushort *)&local_138;
  local_13c = (ushort *)0x2;
  local_138 = (ushort **)0x0;
  uVar1 = FUN_00436fb0(0x1f2,0x65);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0xb,0x10f);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ca50(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0);
  uVar1 = FUN_00436fb0(0x1ee,0x14);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0xd,0x111);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0xffffff);
  uVar1 = FUN_00436fb0(0x1ee,0x4d);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0xd,0x125);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_138 = (ushort **)s_Proman12_00652eb0;
  local_13c = (ushort *)0x4d2533;
  FUN_005d9d50();
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  local_138 = (ushort **)0xffffff;
  local_13c = (ushort *)0x4d255a;
  FUN_005d9d30();
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_2ND_DIVISION_00656e28,0xd,0x107,0x1fb,0x11b);
  local_138 = (ushort **)s_Proman10_00652e9c;
  local_13c = (ushort *)0x4d259e;
  FUN_005d9d50();
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffffbf | 0x20);
  local_138 = (ushort **)0x0;
  local_13c = (ushort *)0x4d25c4;
  FUN_005d9d30();
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_CHAMPION_00656e60,0x30,0x12a,0xce,0x138);
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  FUN_005da180(s_PROMOTED_00656e38,0xb9,0x11b,0x14d,0x125);
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_RELEGATED_00656e54,0x159,0x11b,0x1ed,0x125);
  local_138 = (ushort **)s_Proman8_00652ea8;
  local_13c = (ushort *)0x4d267f;
  FUN_005d9d50();
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0);
  uVar1 = FUN_00436fb0(0x9e,0x16);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0x10,0x143);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_00468c90(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00437020(0,0,0x80);
  uVar1 = FUN_00436fb0(0x9c,0x14);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0x11,0x144);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  puVar11 = local_100;
  if (*(ushort *)((int)local_100 + 0x2592) != 0) {
    local_138 = (ushort **)(uint)*(ushort *)((int)local_100 + 0x2592);
    local_13c = (ushort *)0x4d276a;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d2771;
    puVar4 = (ushort *)FUN_00579730();
    local_138 = (ushort **)(uint)*(ushort *)((int)puVar11 + 0x2592);
    local_13c = (ushort *)0x4d2787;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d278e;
    local_11c = (undefined1 *)FUN_00579390();
    if ((puVar4 != (ushort *)0x0) && (local_11c != (undefined1 *)0x0)) {
      local_138 = (ushort **)0x100;
      local_13c = puVar4;
      FUN_005d66f0();
      local_138 = (ushort **)0x100;
      local_13c = (ushort *)0x80;
      FUN_005d6590(local_58,0x40);
      local_118 = (ushort *)0x0;
      local_114 = (ushort *)0x0;
      local_fc = (ushort *)0x0;
      local_f8 = 0;
      local_108 = (ushort *)(0x1a - *(int *)(puVar4 + 10) / 2);
      puVar8 = (ushort *)(*(int *)(puVar4 + 10) + (int)local_108);
      local_104 = 0x143 - *(int *)(puVar4 + 0xc) / 2;
      local_110 = local_108;
      if ((int)puVar8 <= (int)local_108) {
        local_110 = puVar8;
      }
      if ((int)local_108 <= (int)puVar8) {
        local_108 = puVar8;
      }
      iVar9 = local_104 + *(int *)(puVar4 + 0xc);
      local_10c = local_104;
      if (iVar9 <= local_104) {
        local_10c = iVar9;
      }
      if (local_104 <= iVar9) {
        local_104 = iVar9;
      }
      local_138 = &local_118;
      local_13c = puVar4;
      FUN_005d5220(&local_110,local_a4,&local_fc);
      local_124 = (ushort *)&local_138;
      param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffffbf | 0x20);
      local_138 = (ushort **)0xffffff;
      local_13c = (ushort *)0x4d2884;
      FUN_005d9d30();
      local_138 = (ushort **)0x100;
      local_13c = (ushort *)0x14e;
      FUN_005d9d80(local_11c,0x31,0x13a,0xad);
    }
  }
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  local_138 = (ushort **)0x0;
  local_13c = (ushort *)0x4d28dc;
  FUN_005d9d30();
  iVar9 = 0x12f;
  local_124 = (ushort *)((int)local_100 + 0x2594);
  local_13c = extraout_ECX_11;
  do {
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00436270(0);
    uVar1 = FUN_00436fb0(0x94,0xe);
    uVar2 = FUN_00436fb0(0,10);
    puVar11 = local_ec;
    FUN_00436fb0(0xb9,iVar9);
    uVar2 = FUN_004a9bc0(puVar11,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_00468c90(uVar1);
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00437020(0xc0,0xe3,0xc0);
    uVar1 = FUN_00436fb0(0x92,0xc);
    uVar2 = FUN_00436fb0(0,10);
    ppuVar10 = &local_118;
    FUN_00436fb0(0xba,iVar9 + 1);
    uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_13c = local_124;
    if (*local_124 != 0) {
      local_138 = (ushort **)(uint)*local_124;
      local_13c = (ushort *)0x4d29e1;
      FUN_00585ee0();
      local_138 = (ushort **)0x4d29e8;
      local_11c = (undefined1 *)FUN_00579390();
      local_13c = extraout_ECX_12;
      if (local_11c != (undefined1 *)0x0) {
        local_13c = (ushort *)(iVar9 + -10);
        puVar4 = (ushort *)(iVar9 + 4);
        puVar8 = local_13c;
        if ((int)puVar4 <= (int)local_13c) {
          puVar8 = puVar4;
        }
        if ((int)local_13c <= (int)puVar4) {
          local_13c = puVar4;
        }
        local_138 = (ushort **)0x100;
        FUN_005d9d80(local_11c,0xb9,puVar8,0x14d);
        local_13c = extraout_ECX_13;
      }
    }
    iVar9 = iVar9 + 0x11;
    local_124 = local_124 + 1;
  } while (iVar9 < 0x162);
  iVar9 = 0x12f;
  local_13c = (ushort *)((int)local_100 + 0x259a);
  local_124 = local_13c;
  do {
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00436270(0);
    uVar1 = FUN_00436fb0(0x94,0xe);
    uVar2 = FUN_00436fb0(0,10);
    puVar11 = local_ec;
    FUN_00436fb0(0x159,iVar9);
    uVar2 = FUN_004a9bc0(puVar11,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_00468c90(uVar1);
    local_138 = (ushort **)0x100;
    local_11c = (undefined1 *)&local_13c;
    FUN_00437020(0xff,0xff,0xaa);
    uVar1 = FUN_00436fb0(0x92,0xc);
    uVar2 = FUN_00436fb0(0,10);
    ppuVar10 = &local_118;
    FUN_00436fb0(0x15a,iVar9 + 1);
    uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_13c = extraout_ECX_14;
    if (*local_124 != 0) {
      local_138 = (ushort **)(uint)*local_124;
      local_13c = (ushort *)0x4d2b4f;
      FUN_00585ee0();
      local_138 = (ushort **)0x4d2b56;
      local_11c = (undefined1 *)FUN_00579390();
      local_13c = extraout_ECX_15;
      if (local_11c != (undefined1 *)0x0) {
        local_13c = (ushort *)(iVar9 + -10);
        puVar4 = (ushort *)(iVar9 + 4);
        puVar8 = local_13c;
        if ((int)puVar4 <= (int)local_13c) {
          puVar8 = puVar4;
        }
        if ((int)local_13c <= (int)puVar4) {
          local_13c = puVar4;
        }
        local_138 = (ushort **)0x100;
        FUN_005d9d80(local_11c,0x159,puVar8,0x1ed);
        local_13c = extraout_ECX_16;
      }
    }
    iVar9 = iVar9 + 0x11;
    local_124 = local_124 + 1;
  } while (iVar9 < 0x173);
  local_124 = (ushort *)&local_138;
  local_13c = (ushort *)0x2;
  local_138 = (ushort **)0x0;
  uVar1 = FUN_00436fb0(0x1f2,0x65);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0xb,0x177);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ca50(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0);
  uVar1 = FUN_00436fb0(0x1ee,0x14);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0xd,0x179);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0xffffff);
  uVar1 = FUN_00436fb0(0x1ee,0x4d);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0xd,0x18d);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_138 = (ushort **)s_Proman12_00652eb0;
  local_13c = (ushort *)0x4d2ce2;
  FUN_005d9d50();
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  local_138 = (ushort **)0xffffff;
  local_13c = (ushort *)0x4d2d09;
  FUN_005d9d30();
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_3RD_DIVISION_00656e18,0xd,0x16f,0x1fb,0x183);
  local_138 = (ushort **)s_Proman10_00652e9c;
  local_13c = (ushort *)0x4d2d4d;
  FUN_005d9d50();
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffffbf | 0x20);
  local_138 = (ushort **)0x0;
  local_13c = (ushort *)0x4d2d73;
  FUN_005d9d30();
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  FUN_005da180(s_CHAMPION_00656e60,0x30,0x192,0xd1,0x1a0);
  local_138 = (ushort **)0x1;
  local_13c = (ushort *)0x100;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  FUN_005da180(s_PROMOTED_00656e38,0xb9,0x183,0x14d,0x18d);
  local_138 = (ushort **)s_Proman8_00652ea8;
  local_13c = (ushort *)0x4d2dfc;
  FUN_005d9d50();
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00436270(0);
  uVar1 = FUN_00436fb0(0x9e,0x16);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0x10,0x1ab);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_00468c90(uVar1);
  local_138 = (ushort **)0x100;
  local_124 = (ushort *)&local_13c;
  FUN_00437020(0,0,0x80);
  uVar1 = FUN_00436fb0(0x9c,0x14);
  uVar2 = FUN_00436fb0(0,10);
  puVar11 = local_ec;
  FUN_00436fb0(0x11,0x1ac);
  uVar2 = FUN_004a9bc0(puVar11,uVar2);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  puVar11 = local_100;
  if (*(ushort *)((int)local_100 + 0x25a2) != 0) {
    local_138 = (ushort **)(uint)*(ushort *)((int)local_100 + 0x25a2);
    local_13c = (ushort *)0x4d2ee7;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d2eee;
    puVar4 = (ushort *)FUN_00579730();
    local_138 = (ushort **)(uint)*(ushort *)((int)puVar11 + 0x25a2);
    local_13c = (ushort *)0x4d2f04;
    FUN_00585ee0();
    local_138 = (ushort **)0x4d2f0b;
    local_11c = (undefined1 *)FUN_00579390();
    if ((puVar4 != (ushort *)0x0) && (local_11c != (undefined1 *)0x0)) {
      local_138 = (ushort **)0x100;
      local_13c = puVar4;
      FUN_005d66f0();
      local_138 = (ushort **)0x100;
      local_13c = (ushort *)0x80;
      FUN_005d6590(local_58,0x40);
      local_118 = (ushort *)0x0;
      local_114 = (ushort *)0x0;
      local_fc = (ushort *)0x0;
      local_f8 = 0;
      local_108 = (ushort *)(0x1b - *(int *)(puVar4 + 10) / 2);
      puVar8 = (ushort *)(*(int *)(puVar4 + 10) + (int)local_108);
      local_104 = 0x1ab - *(int *)(puVar4 + 0xc) / 2;
      local_110 = local_108;
      if ((int)puVar8 <= (int)local_108) {
        local_110 = puVar8;
      }
      if ((int)local_108 <= (int)puVar8) {
        local_108 = puVar8;
      }
      iVar9 = local_104 + *(int *)(puVar4 + 0xc);
      local_10c = local_104;
      if (iVar9 <= local_104) {
        local_10c = iVar9;
      }
      if (local_104 <= iVar9) {
        local_104 = iVar9;
      }
      local_138 = &local_118;
      local_13c = puVar4;
      FUN_005d5220(&local_110,local_a4,&local_fc);
      local_124 = (ushort *)&local_138;
      param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffffbf | 0x20);
      local_138 = (ushort **)0xffffff;
      local_13c = (ushort *)0x4d3001;
      FUN_005d9d30();
      local_138 = (ushort **)0x100;
      local_13c = (ushort *)0x1b6;
      FUN_005d9d80(local_11c,0x30,0x1a2,0xad);
    }
  }
  local_124 = (ushort *)&local_138;
  param_1[0x51] = (ushort *)((uint)param_1[0x51] & 0xffffff9f);
  local_138 = (ushort **)0x0;
  local_13c = (ushort *)0x4d3059;
  FUN_005d9d30();
  iVar9 = 0x197;
  local_124 = (ushort *)((int)local_100 + 0x25a4);
  puVar4 = extraout_ECX_17;
  do {
    local_138 = (ushort **)0x100;
    local_100 = (undefined1 *)&local_13c;
    local_13c = puVar4;
    FUN_00436270(0);
    uVar1 = FUN_00436fb0(0x94,0xe);
    uVar2 = FUN_00436fb0(0,10);
    puVar11 = local_ec;
    FUN_00436fb0(0xb9,iVar9);
    uVar2 = FUN_004a9bc0(puVar11,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_00468c90(uVar1);
    local_138 = (ushort **)0x100;
    local_100 = (undefined1 *)&local_13c;
    local_13c = extraout_ECX_18;
    FUN_00437020(0xc0,0xe3,0xc0);
    uVar1 = FUN_00436fb0(0x92,0xc);
    uVar2 = FUN_00436fb0(0,10);
    ppuVar10 = &local_118;
    FUN_00436fb0(0xba,iVar9 + 1);
    uVar2 = FUN_004a9bc0(ppuVar10,uVar2);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    puVar4 = local_124;
    if (*local_124 != 0) {
      local_138 = (ushort **)(uint)*local_124;
      local_13c = (ushort *)0x4d315e;
      FUN_00585ee0();
      local_138 = (ushort **)0x4d3165;
      local_11c = (undefined1 *)FUN_00579390();
      puVar4 = extraout_ECX_19;
      if (local_11c != (undefined1 *)0x0) {
        local_13c = (ushort *)(iVar9 + -10);
        puVar4 = (ushort *)(iVar9 + 4);
        puVar8 = local_13c;
        if ((int)puVar4 <= (int)local_13c) {
          puVar8 = puVar4;
        }
        if ((int)local_13c <= (int)puVar4) {
          local_13c = puVar4;
        }
        local_138 = (ushort **)0x100;
        FUN_005d9d80(local_11c,0xb9,puVar8,0x14d);
        puVar4 = extraout_ECX_20;
      }
    }
    iVar9 = iVar9 + 0x11;
    local_124 = local_124 + 1;
  } while (iVar9 < 0x1db);
  local_4 = local_4 & 0xffffff00;
  local_138 = (ushort **)0x4d31da;
  thunk_FUN_005cb040();
  local_4 = 0xffffffff;
  local_138 = (ushort **)0x4d31f1;
  thunk_FUN_005cb040();
  ExceptionList = local_c;
  return;
}


