// FUN_0044d5f0  entry=0044d5f0  size=3602 bytes

void __fastcall FUN_0044d5f0(int param_1)

{
  uint uVar1;
  short sVar2;
  byte bVar3;
  undefined4 uVar4;
  int iVar5;
  int iVar6;
  char *pcVar7;
  undefined2 *puVar8;
  int iVar9;
  short *psVar10;
  int iVar11;
  uint uVar12;
  int *piVar13;
  uint uVar14;
  int iVar15;
  int iVar16;
  uint uVar17;
  int iVar18;
  uint *puVar19;
  undefined4 *puVar20;
  uint *puVar21;
  undefined4 *puVar22;
  uint uVar23;
  uint *puVar24;
  uint local_94;
  int local_8c;
  undefined2 uStack_82;
  uint local_7c;
  undefined1 local_74 [4];
  undefined2 *local_70;
  uint local_6c;
  undefined1 local_68 [4];
  undefined1 local_64 [4];
  undefined1 local_60 [4];
  int local_5c;
  uint *local_58;
  undefined4 local_54;
  uint local_50 [4];
  uint local_40;
  uint local_3c;
  uint local_38;
  uint local_34;
  undefined4 local_20;
  undefined4 local_4;
  
  *(uint *)(param_1 + 100) = (uint)*(ushort *)(DAT_0066afd0 + 0x18);
  *(uint *)(param_1 + 0x804) = (uint)*(ushort *)(DAT_0066afd0 + 0x1a);
  if ((((DAT_0066b1dc == 0) || (DAT_0066b1dc == 1)) || (DAT_0066b1dc == 2)) || (DAT_0066b1dc == 3))
  {
    uVar4 = 1;
  }
  else {
    uVar4 = 0;
  }
  *(undefined4 *)(param_1 + 0x18) = uVar4;
  *(undefined4 *)(param_1 + 0x14) = 0;
  local_58 = (uint *)(param_1 + 0x7f8);
  *(undefined4 *)(param_1 + 0x10) = *(undefined4 *)(DAT_0066afd0 + 4);
  *(undefined4 *)(param_1 + 0x44) = *(undefined4 *)(DAT_0066afd0 + 0x58);
  *(undefined4 *)(param_1 + 0x48) = *(undefined4 *)(DAT_0066afd0 + 0x5c);
  *(undefined4 *)(param_1 + 0x1c) = *(undefined4 *)(DAT_0066afd0 + 0x40);
  *(undefined4 *)(param_1 + 0x20) = *(undefined4 *)(DAT_0066afd0 + 0x48);
  *(undefined4 *)(param_1 + 0x24) = *(undefined4 *)(DAT_0066afd0 + 0x50);
  *(undefined4 *)(param_1 + 0x28) = *(undefined4 *)(DAT_0066afd0 + 0x30);
  *(uint *)(param_1 + 0x2c) = (uint)*(byte *)(DAT_0066afd0 + 0x34);
  *(uint *)(param_1 + 0x30) = (uint)*(byte *)(DAT_0066afd0 + 0x35);
  *(uint *)(param_1 + 0x34) = (uint)*(byte *)(DAT_0066afd0 + 0x36);
  *(uint *)(param_1 + 0x38) = (uint)*(byte *)(DAT_0066afd0 + 0x37);
  local_5c = param_1;
  FUN_00585ee0(*(undefined2 *)(DAT_0066afd0 + 0x44));
  iVar5 = FUN_005793d0();
  iVar18 = (uint)*(ushort *)(iVar5 + 0x36) << 0x10;
  iVar5 = (uint)*(ushort *)(iVar5 + 0x34) << 0x10;
  *(int *)(param_1 + 0x4c) = iVar18;
  *(int *)(param_1 + 0x50) = iVar5;
  *(undefined4 *)(param_1 + 0x54) = 0;
  *(undefined2 *)(param_1 + 0x7e8) = *(undefined2 *)(DAT_0066afd0 + 0x38);
  FUN_00585ee0(*(undefined2 *)(DAT_0066afd0 + 0x38));
  uVar4 = FUN_00579390();
  FUN_0044bc60(uVar4);
  FUN_00585ee0(*(undefined2 *)(DAT_0066afd0 + 0x38));
  iVar6 = FUN_005793d0();
  uVar14 = (uint)(*(int *)(iVar6 + 0x5c) != 0xffff);
  *(uint *)(param_1 + 0x7f0) = uVar14;
  if (uVar14 == 0) {
    pcVar7 = s_COMPUTER_00653340;
  }
  else {
    pcVar7 = (char *)FUN_0057d1f0();
  }
  FUN_0044bd10(pcVar7);
  *(uint *)(param_1 + 0x68) = (uint)*(byte *)(iVar6 + 0x1d9);
  *(uint *)(param_1 + 0x6c) = (uint)*(byte *)(iVar6 + 0x1da);
  *(uint *)(param_1 + 0x70) = (uint)*(byte *)(iVar6 + 0x1db);
  *(uint *)(param_1 + 0x74) = (uint)*(byte *)(iVar6 + 0x1dd);
  *(uint *)(param_1 + 0x78) = (uint)*(byte *)(iVar6 + 0x1de);
  *(uint *)(param_1 + 0x7c) = (uint)*(byte *)(iVar6 + 0x1df);
  *(uint *)(param_1 + 0x80) = (uint)*(byte *)(iVar6 + 0x1dc);
  local_20 = *(undefined4 *)(iVar6 + 0x25c);
  FUN_0058c300(0x13e,0xc6,iVar18,iVar5);
  *(undefined4 *)(param_1 + 0x60) = local_20;
  local_20 = *(undefined4 *)(iVar6 + 0x260);
  FUN_0058c300(0x13e,0xc6,iVar18,iVar5);
  *(undefined4 *)(param_1 + 0x5c) = local_20;
  sVar2 = *(short *)(DAT_0066afd0 + 0x44);
  if ((*(short *)(DAT_0066afd0 + 0x38) == sVar2) || (*(short *)(DAT_0066afd0 + 0x3a) == sVar2)) {
    *(uint *)(param_1 + 0x58) = (uint)(*(short *)(DAT_0066afd0 + 0x38) == sVar2);
  }
  else {
    *(uint *)(param_1 + 0x58) = 1;
  }
  local_94 = 0;
  do {
    local_6c = local_94 + 1;
    puVar8 = (undefined2 *)FUN_0057a2e0(local_6c);
    iVar11 = param_1 + 0x84 + local_94 * 0xac;
    if ((puVar8 == (undefined2 *)0x0) || (iVar9 = FUN_005836a0(), iVar9 != 0)) {
      *(undefined2 *)(iVar11 + 4) = 0;
      FUN_0044ba70(&DAT_00653338);
      *(undefined4 *)(iVar11 + 0x18) = 0;
      *(undefined4 *)(iVar11 + 8) = 0;
      *(undefined4 *)(iVar11 + 0x10) = 0;
      *(undefined4 *)(iVar11 + 0x1c) = 0;
      *(undefined4 *)(iVar11 + 0x28) = 0xffffffff;
      *(undefined4 *)(iVar11 + 0xc) = 0;
      *(undefined4 *)(iVar11 + 0x20) = 0;
      *(undefined4 *)(iVar11 + 0x14) = 0;
      *(undefined4 *)(iVar11 + 0x2c) = 0;
      *(undefined4 *)(iVar11 + 0x30) = 0;
      *(undefined4 *)(iVar11 + 0x24) = 0;
      *(undefined1 *)(iVar11 + 0x34) = 0;
      *(undefined1 *)(iVar11 + 0x35) = 0;
      *(undefined1 *)(iVar11 + 0x36) = 0;
      *(undefined1 *)(iVar11 + 0x37) = 0;
      *(undefined1 *)(iVar11 + 0x38) = 0;
      *(undefined1 *)(iVar11 + 0x39) = 0;
      *(undefined1 *)(iVar11 + 0x3a) = 0;
      *(undefined1 *)(iVar11 + 0x3b) = 0;
      *(undefined1 *)(iVar11 + 0x3c) = 0;
      *(undefined1 *)(iVar11 + 0x3d) = 0;
      *(undefined1 *)(iVar11 + 0x3e) = 0;
      *(undefined1 *)(iVar11 + 0x3f) = 0;
      *(undefined1 *)(iVar11 + 0x40) = 0;
      *(undefined1 *)(iVar11 + 0x41) = 0;
      *(undefined1 *)(iVar11 + 0x42) = 0;
      *(undefined4 *)(iVar11 + 0x44) = 0;
      FUN_0044bb20(&DAT_00653338);
      *(undefined4 *)(iVar11 + 0x68) = 0;
      *(undefined4 *)(iVar11 + 0x6c) = 0;
      *(undefined4 *)(iVar11 + 0x70) = 0;
      *(undefined4 *)(iVar11 + 0x74) = 0;
      *(undefined4 *)(iVar11 + 0x78) = 0;
      *(undefined4 *)(iVar11 + 0x7c) = 0;
      *(undefined4 *)(iVar11 + 0x80) = 0;
      *(undefined4 *)(iVar11 + 0x84) = 0;
      *(undefined4 *)(iVar11 + 0x88) = 0;
      *(undefined4 *)(iVar11 + 0x8c) = 0;
      *(undefined4 *)(iVar11 + 0x90) = 0;
      *(undefined4 *)(iVar11 + 0x94) = 0;
      *(undefined4 *)(iVar11 + 0x98) = 0;
      *(undefined4 *)(iVar11 + 0x9c) = 0;
      *(undefined4 *)(iVar11 + 0xa0) = 0;
      *(undefined4 *)(iVar11 + 0xa4) = 0;
      *(undefined4 *)(iVar11 + 0xa8) = 0;
      *(undefined4 *)(iVar11 + 0x54) = 0;
      *(undefined4 *)(iVar11 + 0x50) = 0;
      *(undefined4 *)(iVar11 + 0x58) = 0;
    }
    else {
      *(undefined2 *)(iVar11 + 4) = *puVar8;
      FUN_0044ba70(*(undefined4 *)(puVar8 + 2));
      *(int *)(iVar11 + 0x28) = *(int *)(iVar6 + 0x230 + local_94 * 4) + -1;
      if (local_94 < 0xb) {
        puVar19 = (uint *)((local_94 + 3) * 0x20 + iVar6);
      }
      else {
        puVar19 = (uint *)0x0;
      }
      puVar21 = local_50;
      for (iVar9 = 8; iVar9 != 0; iVar9 = iVar9 + -1) {
        *puVar21 = *puVar19;
        puVar19 = puVar19 + 1;
        puVar21 = puVar21 + 1;
      }
      FUN_0058c300(0x13e,0xc6,iVar18,iVar5);
      *(uint *)(iVar11 + 8) = local_40;
      *(uint *)(iVar11 + 0xc) = local_3c;
      *(uint *)(iVar11 + 0x10) = local_38;
      *(uint *)(iVar11 + 0x14) = local_34;
      uVar14 = local_50[2] + local_50[0];
      uVar23 = local_50[0];
      if ((int)uVar14 <= (int)local_50[0]) {
        uVar23 = uVar14;
      }
      if ((int)uVar14 < (int)local_50[0]) {
        uVar14 = local_50[0];
      }
      uVar1 = local_50[3] + local_50[1];
      uVar12 = local_50[1];
      if ((int)uVar1 <= (int)local_50[1]) {
        uVar12 = uVar1;
      }
      uVar17 = local_50[1];
      if ((int)local_50[1] <= (int)uVar1) {
        uVar17 = uVar1;
      }
      *(uint *)(iVar11 + 0x18) = uVar23;
      *(uint *)(iVar11 + 0x1c) = uVar12;
      *(uint *)(iVar11 + 0x20) = uVar14;
      *(uint *)(iVar11 + 0x24) = uVar17;
      *(uint *)(iVar11 + 0x2c) = (uint)*(byte *)(puVar8 + 0xb);
      *(uint *)(iVar11 + 0x30) = (uint)*(byte *)((int)puVar8 + 0x17);
      FUN_005841e0(local_64,local_74,local_68,local_60,&local_70);
      *(undefined1 *)(iVar11 + 0x34) = *(undefined1 *)(puVar8 + 0x54);
      *(undefined1 *)(iVar11 + 0x35) = local_64[0];
      *(undefined1 *)(iVar11 + 0x36) = local_74[0];
      *(undefined1 *)(iVar11 + 0x37) = local_68[0];
      *(undefined1 *)(iVar11 + 0x38) = local_60[0];
      *(undefined1 *)(iVar11 + 0x39) = *(undefined1 *)((int)puVar8 + 0xa7);
      *(undefined1 *)(iVar11 + 0x3a) = 99;
      *(undefined1 *)(iVar11 + 0x3b) = local_70._0_1_;
      bVar3 = *(byte *)(puVar8 + 0x50);
      if ((local_94 == 0) && (bVar3 = bVar3 + 10, 99 < bVar3)) {
        bVar3 = 99;
      }
      *(byte *)(iVar11 + 0x3c) = bVar3;
      if (*(char *)(puVar8 + 0xe) == '\x01') {
        bVar3 = *(char *)((int)puVar8 + 0xa1) + 10;
        if (99 < bVar3) {
          bVar3 = 99;
        }
        *(byte *)(iVar11 + 0x3d) = bVar3;
      }
      else {
        *(undefined1 *)(iVar11 + 0x3d) = *(undefined1 *)((int)puVar8 + 0xa1);
      }
      *(undefined1 *)(iVar11 + 0x3e) = *(undefined1 *)(puVar8 + 0x51);
      *(undefined1 *)(iVar11 + 0x3f) = *(undefined1 *)((int)puVar8 + 0xa3);
      *(undefined1 *)(iVar11 + 0x40) = *(undefined1 *)(puVar8 + 0x52);
      bVar3 = *(byte *)((int)puVar8 + 0xa5);
      if ((*(int *)(iVar6 + 0x5c) != 0xffff) && (0x1e < bVar3)) {
        bVar3 = bVar3 - 10;
      }
      *(byte *)(iVar11 + 0x41) = bVar3;
      *(undefined1 *)(iVar11 + 0x42) = *(undefined1 *)(puVar8 + 0x7c);
      *(uint *)(iVar11 + 0x44) = *(byte *)(puVar8 + 0xc) + 1;
      FUN_0044bb20((&PTR_s_GOALKEEPER_00662d10)[*(byte *)(puVar8 + 0xe)]);
      switch(*(undefined1 *)(puVar8 + 0xe)) {
      case 0:
        *(undefined4 *)(iVar11 + 0x48) = 0;
        break;
      case 1:
        *(undefined4 *)(iVar11 + 0x48) = 1;
        break;
      case 2:
        *(undefined4 *)(iVar11 + 0x48) = 2;
        break;
      case 3:
        *(undefined4 *)(iVar11 + 0x48) = 3;
      }
      local_8c = 0;
      *(undefined4 *)(iVar11 + 0x68) = 0;
      *(undefined4 *)(iVar11 + 0x6c) = 0;
      *(undefined4 *)(iVar11 + 0x70) = 0;
      *(undefined4 *)(iVar11 + 0x74) = 0;
      *(undefined4 *)(iVar11 + 0x78) = 0;
      *(undefined4 *)(iVar11 + 0x7c) = 0;
      *(undefined4 *)(iVar11 + 0x80) = 0;
      *(undefined4 *)(iVar11 + 0x84) = 0;
      *(undefined4 *)(iVar11 + 0x88) = 0;
      *(undefined4 *)(iVar11 + 0x8c) = 0;
      *(undefined4 *)(iVar11 + 0x90) = 0;
      *(undefined4 *)(iVar11 + 0x94) = 0;
      *(undefined4 *)(iVar11 + 0x98) = 0;
      *(undefined4 *)(iVar11 + 0x9c) = 0;
      *(undefined4 *)(iVar11 + 0xa0) = 0;
      *(undefined4 *)(iVar11 + 0xa4) = 0;
      *(undefined4 *)(iVar11 + 0xa8) = 0;
      if (0 < *(int *)(DAT_0066afd0 + 0xa0)) {
        sVar2 = *(short *)(iVar11 + 4);
        iVar16 = 0;
        iVar9 = DAT_0066afd0;
        do {
          puVar20 = (undefined4 *)(*(int *)(iVar9 + 0x9c) + iVar16);
          if (*(short *)(puVar20 + 0x11) == sVar2) {
            puVar22 = (undefined4 *)(iVar11 + 0x68);
            for (iVar15 = 0x11; iVar9 = DAT_0066afd0, iVar15 != 0; iVar15 = iVar15 + -1) {
              *puVar22 = *puVar20;
              puVar20 = puVar20 + 1;
              puVar22 = puVar22 + 1;
            }
          }
          local_8c = local_8c + 1;
          iVar16 = iVar16 + 0x48;
        } while (local_8c < *(int *)(iVar9 + 0xa0));
      }
      *(undefined4 *)(iVar11 + 0x54) = 0;
      *(undefined4 *)(iVar11 + 0x50) = 0;
      *(undefined4 *)(iVar11 + 0x58) = 0;
      iVar16 = 0;
      iVar9 = *(int *)(DAT_0066afd0 + 0x98);
      if (0 < iVar9) {
        psVar10 = (short *)(*(int *)(DAT_0066afd0 + 0x94) + 8);
        do {
          if (*psVar10 == *(short *)(iVar11 + 4)) {
            iVar16 = 0;
            if (0 < iVar9) {
              iVar9 = 0;
              do {
                piVar13 = (int *)(*(int *)(DAT_0066afd0 + 0x94) + iVar9);
                if (*(short *)(*(int *)(DAT_0066afd0 + 0x94) + 8 + iVar9) == *(short *)(iVar11 + 4))
                {
                  if (*piVar13 == 1) {
                    bVar3 = *(byte *)(piVar13 + 1);
                    if (*(int *)(iVar11 + 0x50) == 0) {
                      *(undefined4 *)(iVar11 + 0x50) = 1;
                      *(uint *)(iVar11 + 0x5c) = (uint)bVar3;
                    }
                    else {
                      *(undefined4 *)(iVar11 + 0x54) = 1;
                      *(uint *)(iVar11 + 0x60) = (uint)bVar3;
                    }
                  }
                  else {
                    bVar3 = *(byte *)(piVar13 + 1);
                    *(undefined4 *)(iVar11 + 0x58) = 1;
                    *(uint *)(iVar11 + 100) = (uint)bVar3;
                  }
                }
                iVar16 = iVar16 + 1;
                iVar9 = iVar9 + 0xc;
              } while (iVar16 < *(int *)(DAT_0066afd0 + 0x98));
            }
            break;
          }
          iVar16 = iVar16 + 1;
          psVar10 = psVar10 + 6;
        } while (iVar16 < iVar9);
      }
    }
    puVar19 = local_58;
    local_94 = local_6c;
  } while ((int)local_6c < 0xb);
  *(undefined2 *)(local_58 + 0x1e4) = *(undefined2 *)(DAT_0066afd0 + 0x3a);
  FUN_00585ee0(*(undefined2 *)(DAT_0066afd0 + 0x3a));
  uVar4 = FUN_00579390();
  FUN_0044bc60(uVar4);
  FUN_00585ee0(*(undefined2 *)(DAT_0066afd0 + 0x3a));
  iVar11 = FUN_005793d0();
  iVar6 = local_5c;
  uVar14 = (uint)(*(int *)(iVar11 + 0x5c) != 0xffff);
  *(uint *)(local_5c + 0xf90) = uVar14;
  if (uVar14 == 0) {
    pcVar7 = s_COMPUTER_00653340;
  }
  else {
    pcVar7 = (char *)FUN_0057d1f0();
  }
  FUN_0044bd10(pcVar7);
  *(uint *)(iVar6 + 0x808) = (uint)*(byte *)(iVar11 + 0x1d9);
  *(uint *)(iVar6 + 0x80c) = (uint)*(byte *)(iVar11 + 0x1da);
  *(uint *)(iVar6 + 0x810) = (uint)*(byte *)(iVar11 + 0x1db);
  *(uint *)(iVar6 + 0x814) = (uint)*(byte *)(iVar11 + 0x1dd);
  *(uint *)(iVar6 + 0x818) = (uint)*(byte *)(iVar11 + 0x1de);
  *(uint *)(iVar6 + 0x81c) = (uint)*(byte *)(iVar11 + 0x1df);
  *(uint *)(iVar6 + 0x820) = (uint)*(byte *)(iVar11 + 0x1dc);
  local_20 = *(undefined4 *)(iVar11 + 0x25c);
  FUN_0058c300(0x13e,0xc6,iVar18,iVar5);
  *(undefined4 *)(iVar6 + 0x800) = local_20;
  local_20 = *(undefined4 *)(iVar11 + 0x260);
  FUN_0058c300(0x13e,0xc6,iVar18,iVar5);
  *(undefined4 *)(iVar6 + 0x7fc) = local_20;
  sVar2 = *(short *)(DAT_0066afd0 + 0x44);
  if ((*(short *)(DAT_0066afd0 + 0x38) == sVar2) || (*(short *)(DAT_0066afd0 + 0x3a) == sVar2)) {
    *puVar19 = (uint)(*(short *)(DAT_0066afd0 + 0x3a) == sVar2);
  }
  else {
    *puVar19 = 1;
  }
  local_94 = 0;
  do {
    local_6c = local_94 + 1;
    puVar8 = (undefined2 *)FUN_0057a2e0(local_6c);
    puVar19 = local_58;
    iVar6 = local_94 * 0xac;
    local_70 = puVar8;
    if ((puVar8 == (undefined2 *)0x0) || (iVar9 = FUN_005836a0(), iVar9 != 0)) {
      *(undefined2 *)(puVar19 + local_94 * 0x2b + 0xc) = 0;
      FUN_0044ba70(&DAT_00653338);
      puVar19[local_94 * 0x2b + 0x11] = 0;
      puVar19[local_94 * 0x2b + 0xd] = 0;
      puVar19[local_94 * 0x2b + 0xf] = 0;
      puVar19[local_94 * 0x2b + 0x12] = 0;
      puVar19[local_94 * 0x2b + 0x15] = 0xffffffff;
      puVar19[local_94 * 0x2b + 0xe] = 0;
      puVar19[local_94 * 0x2b + 0x13] = 0;
      puVar19[local_94 * 0x2b + 0x10] = 0;
      puVar19[local_94 * 0x2b + 0x16] = 0;
      puVar19[local_94 * 0x2b + 0x17] = 0;
      puVar19[local_94 * 0x2b + 0x14] = 0;
      *(undefined1 *)(puVar19 + local_94 * 0x2b + 0x18) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x61) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x62) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 99) = 0;
      *(undefined1 *)(puVar19 + local_94 * 0x2b + 0x19) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x65) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x66) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x67) = 0;
      *(undefined1 *)(puVar19 + local_94 * 0x2b + 0x1a) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x69) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x6a) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x6b) = 0;
      *(undefined1 *)(puVar19 + local_94 * 0x2b + 0x1b) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x6d) = 0;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x6e) = 0;
      puVar19[local_94 * 0x2b + 0x1c] = 0;
      FUN_0044bb20(&DAT_00653338);
      puVar19[local_94 * 0x2b + 0x25] = 0;
      puVar19[local_94 * 0x2b + 0x26] = 0;
      puVar19[local_94 * 0x2b + 0x27] = 0;
      puVar19[local_94 * 0x2b + 0x28] = 0;
      puVar19[local_94 * 0x2b + 0x29] = 0;
      puVar19[local_94 * 0x2b + 0x2a] = 0;
      puVar19[local_94 * 0x2b + 0x2b] = 0;
      puVar19[local_94 * 0x2b + 0x2c] = 0;
      puVar19[local_94 * 0x2b + 0x2d] = 0;
      puVar19[local_94 * 0x2b + 0x2e] = 0;
      puVar19[local_94 * 0x2b + 0x2f] = 0;
      puVar19[local_94 * 0x2b + 0x30] = 0;
      puVar19[local_94 * 0x2b + 0x31] = 0;
      puVar19[local_94 * 0x2b + 0x32] = 0;
      puVar19[local_94 * 0x2b + 0x33] = 0;
      puVar19[local_94 * 0x2b + 0x34] = 0;
      puVar19[local_94 * 0x2b + 0x35] = 0;
      puVar19[local_94 * 0x2b + 0x20] = 0;
      puVar19[local_94 * 0x2b + 0x1f] = 0;
      puVar19[local_94 * 0x2b + 0x21] = 0;
    }
    else {
      *(undefined2 *)(puVar19 + local_94 * 0x2b + 0xc) = *puVar8;
      FUN_0044ba70(*(undefined4 *)(puVar8 + 2));
      puVar19[local_94 * 0x2b + 0x15] = *(int *)(iVar11 + 0x230 + local_94 * 4) - 1;
      if (local_94 < 0xb) {
        puVar21 = (uint *)((local_94 + 3) * 0x20 + iVar11);
      }
      else {
        puVar21 = (uint *)0x0;
      }
      puVar24 = local_50;
      for (iVar9 = 8; iVar9 != 0; iVar9 = iVar9 + -1) {
        *puVar24 = *puVar21;
        puVar21 = puVar21 + 1;
        puVar24 = puVar24 + 1;
      }
      FUN_0058c300(0x13e,0xc6,iVar18,iVar5);
      puVar8 = local_70;
      puVar19[local_94 * 0x2b + 0xd] = local_40;
      puVar19[local_94 * 0x2b + 0xe] = local_3c;
      puVar19[local_94 * 0x2b + 0xf] = local_38;
      puVar19[local_94 * 0x2b + 0x10] = local_34;
      uVar14 = local_50[2] + local_50[0];
      uVar23 = local_50[0];
      if ((int)uVar14 <= (int)local_50[0]) {
        uVar23 = uVar14;
      }
      if ((int)uVar14 < (int)local_50[0]) {
        uVar14 = local_50[0];
      }
      uVar1 = local_50[3] + local_50[1];
      uVar12 = local_50[1];
      if ((int)uVar1 <= (int)local_50[1]) {
        uVar12 = uVar1;
      }
      uVar17 = local_50[1];
      if ((int)local_50[1] <= (int)uVar1) {
        uVar17 = uVar1;
      }
      puVar19[local_94 * 0x2b + 0x11] = uVar23;
      puVar19[local_94 * 0x2b + 0x12] = uVar12;
      puVar19[local_94 * 0x2b + 0x13] = uVar14;
      puVar19[local_94 * 0x2b + 0x14] = uVar17;
      puVar19[local_94 * 0x2b + 0x16] = (uint)*(byte *)(local_70 + 0xb);
      puVar19[local_94 * 0x2b + 0x17] = (uint)*(byte *)((int)local_70 + 0x17);
      FUN_005841e0(local_60,local_68,local_74,local_64,&local_54);
      *(undefined1 *)(puVar19 + local_94 * 0x2b + 0x18) = *(undefined1 *)(puVar8 + 0x54);
      *(undefined1 *)((int)puVar19 + iVar6 + 0x61) = local_60[0];
      *(undefined1 *)((int)puVar19 + iVar6 + 0x62) = local_68[0];
      *(undefined1 *)((int)puVar19 + iVar6 + 99) = local_74[0];
      *(undefined1 *)(puVar19 + local_94 * 0x2b + 0x19) = local_64[0];
      *(undefined1 *)((int)puVar19 + iVar6 + 0x65) = *(undefined1 *)((int)puVar8 + 0xa7);
      *(undefined1 *)((int)puVar19 + iVar6 + 0x66) = 99;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x67) = (undefined1)local_54;
      bVar3 = *(byte *)(puVar8 + 0x50);
      if ((local_94 == 0) && (bVar3 = bVar3 + 10, 99 < bVar3)) {
        bVar3 = 99;
      }
      *(byte *)(puVar19 + local_94 * 0x2b + 0x1a) = bVar3;
      if (*(char *)(puVar8 + 0xe) == '\x01') {
        bVar3 = *(char *)((int)puVar8 + 0xa1) + 10;
        if (99 < bVar3) {
          bVar3 = 99;
        }
        *(byte *)((int)puVar19 + iVar6 + 0x69) = bVar3;
      }
      else {
        *(undefined1 *)((int)puVar19 + iVar6 + 0x69) = *(undefined1 *)((int)puVar8 + 0xa1);
      }
      *(undefined1 *)((int)puVar19 + iVar6 + 0x6a) = *(undefined1 *)(puVar8 + 0x51);
      *(undefined1 *)((int)puVar19 + iVar6 + 0x6b) = *(undefined1 *)((int)puVar8 + 0xa3);
      *(undefined1 *)(puVar19 + local_94 * 0x2b + 0x1b) = *(undefined1 *)(puVar8 + 0x52);
      bVar3 = *(byte *)((int)puVar8 + 0xa5);
      if ((*(int *)(iVar11 + 0x5c) != 0xffff) && (0x1e < bVar3)) {
        bVar3 = bVar3 - 10;
      }
      *(byte *)((int)puVar19 + iVar6 + 0x6d) = bVar3;
      *(undefined1 *)((int)puVar19 + iVar6 + 0x6e) = *(undefined1 *)(puVar8 + 0x7c);
      puVar19[local_94 * 0x2b + 0x1c] = *(byte *)(puVar8 + 0xc) + 1;
      FUN_0044bb20((&PTR_s_GOALKEEPER_00662d10)[*(byte *)(puVar8 + 0xe)]);
      switch(*(undefined1 *)(puVar8 + 0xe)) {
      case 0:
        puVar19[local_94 * 0x2b + 0x1d] = 0;
        break;
      case 1:
        puVar19[local_94 * 0x2b + 0x1d] = 1;
        break;
      case 2:
        puVar19[local_94 * 0x2b + 0x1d] = 2;
        break;
      case 3:
        puVar19[local_94 * 0x2b + 0x1d] = 3;
      }
      local_8c = 0;
      puVar19[local_94 * 0x2b + 0x25] = 0;
      puVar19[local_94 * 0x2b + 0x26] = 0;
      puVar19[local_94 * 0x2b + 0x27] = 0;
      puVar19[local_94 * 0x2b + 0x28] = 0;
      puVar19[local_94 * 0x2b + 0x29] = 0;
      puVar19[local_94 * 0x2b + 0x2a] = 0;
      puVar19[local_94 * 0x2b + 0x2b] = 0;
      puVar19[local_94 * 0x2b + 0x2c] = 0;
      puVar19[local_94 * 0x2b + 0x2d] = 0;
      puVar19[local_94 * 0x2b + 0x2e] = 0;
      puVar19[local_94 * 0x2b + 0x2f] = 0;
      puVar19[local_94 * 0x2b + 0x30] = 0;
      puVar19[local_94 * 0x2b + 0x31] = 0;
      puVar19[local_94 * 0x2b + 0x32] = 0;
      puVar19[local_94 * 0x2b + 0x33] = 0;
      puVar19[local_94 * 0x2b + 0x34] = 0;
      puVar19[local_94 * 0x2b + 0x35] = 0;
      if (0 < *(int *)(DAT_0066afd0 + 0xa8)) {
        uVar14 = puVar19[local_94 * 0x2b + 0xc];
        iVar9 = 0;
        iVar6 = DAT_0066afd0;
        do {
          puVar21 = (uint *)(*(int *)(iVar6 + 0xa4) + iVar9);
          if ((short)puVar21[0x11] == (short)uVar14) {
            puVar24 = puVar19 + local_94 * 0x2b + 0x25;
            for (iVar16 = 0x11; iVar6 = DAT_0066afd0, iVar16 != 0; iVar16 = iVar16 + -1) {
              *puVar24 = *puVar21;
              puVar21 = puVar21 + 1;
              puVar24 = puVar24 + 1;
            }
          }
          local_8c = local_8c + 1;
          iVar9 = iVar9 + 0x48;
        } while (local_8c < *(int *)(iVar6 + 0xa8));
      }
      puVar19[local_94 * 0x2b + 0x20] = 0;
      puVar19[local_94 * 0x2b + 0x1f] = 0;
      puVar19[local_94 * 0x2b + 0x21] = 0;
      iVar9 = 0;
      iVar6 = *(int *)(DAT_0066afd0 + 0x98);
      if (0 < iVar6) {
        psVar10 = (short *)(*(int *)(DAT_0066afd0 + 0x94) + 8);
        do {
          if (*psVar10 == (short)puVar19[local_94 * 0x2b + 0xc]) {
            iVar9 = 0;
            if (0 < iVar6) {
              iVar6 = 0;
              do {
                piVar13 = (int *)(*(int *)(DAT_0066afd0 + 0x94) + iVar6);
                if ((short)piVar13[2] == (short)puVar19[local_94 * 0x2b + 0xc]) {
                  if (*piVar13 == 1) {
                    bVar3 = *(byte *)(piVar13 + 1);
                    if (puVar19[local_94 * 0x2b + 0x1f] == 0) {
                      puVar19[local_94 * 0x2b + 0x1f] = 1;
                      puVar19[local_94 * 0x2b + 0x22] = (uint)bVar3;
                    }
                    else {
                      puVar19[local_94 * 0x2b + 0x20] = 1;
                      puVar19[local_94 * 0x2b + 0x23] = (uint)bVar3;
                    }
                  }
                  else {
                    bVar3 = *(byte *)(piVar13 + 1);
                    puVar19[local_94 * 0x2b + 0x21] = 1;
                    puVar19[local_94 * 0x2b + 0x24] = (uint)bVar3;
                  }
                }
                iVar9 = iVar9 + 1;
                iVar6 = iVar6 + 0xc;
              } while (iVar9 < *(int *)(DAT_0066afd0 + 0x98));
            }
            break;
          }
          iVar9 = iVar9 + 1;
          psVar10 = psVar10 + 6;
        } while (iVar9 < iVar6);
      }
    }
    iVar6 = local_5c;
    local_94 = local_6c;
    if (10 < (int)local_6c) {
      iVar18 = *(int *)(local_5c + 0xf9c);
      iVar5 = iVar18 + -1;
      *(int *)(local_5c + 0xf9c) = iVar5;
      while (iVar11 = iVar5, iVar18 != 0) {
        iVar5 = iVar11 + -1;
        *(int *)(local_5c + 0xf9c) = iVar5;
        iVar18 = iVar11;
      }
      if (*(int *)(local_5c + 0xf98) != 0) {
        FUN_005bbed0(*(int *)(local_5c + 0xf98));
        *(undefined4 *)(iVar6 + 0xf98) = 0;
      }
      *(undefined4 *)(iVar6 + 0xf9c) = 0;
      iVar5 = 0;
      uVar4 = local_54;
      if (*(short *)(DAT_0066afd0 + 100) != 0) {
        do {
          puVar20 = (undefined4 *)FUN_00449660(local_50,iVar5);
          local_7c = puVar20[2];
          switch(puVar20[1]) {
          case 1:
            uVar4 = 0;
            break;
          case 2:
            uVar4 = 1;
            local_7c = (uint)(byte)((char)local_7c - 0x2d);
            break;
          case 3:
            uVar4 = 2;
            local_7c = (uint)(byte)((char)local_7c + 0xa6);
            break;
          case 4:
            uVar4 = 3;
            local_7c = (uint)(byte)((char)local_7c + 0x97);
            break;
          case 5:
            uVar4 = 4;
          }
          uStack_82 = (undefined2)((uint)*puVar20 >> 0x10);
          local_4 = CONCAT22((short)*puVar20,uStack_82);
          FUN_004510b0(uVar4,local_7c & 0xff,puVar20[3],local_4);
          iVar5 = iVar5 + 1;
        } while (iVar5 < (int)(uint)*(ushort *)(DAT_0066afd0 + 100));
      }
      return;
    }
  } while( true );
}


