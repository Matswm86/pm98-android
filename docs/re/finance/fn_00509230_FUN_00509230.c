// FUN_00509230  entry=00509230  size=3458 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void FUN_00509230(int param_1,int param_2)

{
  float fVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined **ppuVar4;
  undefined4 uVar5;
  int iVar6;
  LPCSTR pCVar7;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  undefined4 extraout_ECX_02;
  undefined4 extraout_ECX_03;
  undefined4 extraout_ECX_04;
  float *pfVar8;
  float *pfVar9;
  undefined *extraout_ECX_05;
  undefined *extraout_ECX_06;
  undefined *extraout_ECX_07;
  undefined *puVar10;
  uint uVar11;
  uint uVar12;
  float10 fVar13;
  undefined4 extraout_var;
  undefined4 uVar14;
  undefined1 *puVar15;
  undefined1 *local_2e0;
  float local_2dc;
  float *local_2d8;
  undefined *local_2d4;
  undefined *local_2d0;
  float local_2cc;
  undefined1 *local_2c8 [2];
  undefined8 local_2c0;
  undefined4 local_2b8;
  undefined4 local_2b0;
  float local_210 [68];
  undefined1 local_100;
  
  uVar14 = 0x100;
  FUN_00436270(0);
  uVar5 = extraout_var;
  uVar2 = FUN_00436fb0(0x243,0x4b);
  uVar3 = FUN_00436fb0(6,0xe9);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  FUN_0043ce50(uVar2,uVar5,uVar14);
  uVar14 = 0x100;
  uVar5 = extraout_ECX;
  FUN_00437020(0x4a,0x6d,0xad);
  uVar2 = FUN_00436fb0(0x11f,0x13);
  uVar3 = FUN_00436fb0(0x129,0xea);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  FUN_0043ce50(uVar2,uVar5,uVar14);
  uVar14 = 0x100;
  uVar5 = extraout_ECX_00;
  FUN_00437020(0,0,0xa5);
  uVar2 = FUN_00436fb0(0x2f,0x15);
  uVar3 = FUN_00436fb0(7,0xfe);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  FUN_0043ce50(uVar2,uVar5,uVar14);
  uVar14 = 0x100;
  uVar5 = extraout_ECX_01;
  FUN_00437020(0x52,0,0);
  uVar2 = FUN_00436fb0(0x2f,0x15);
  uVar3 = FUN_00436fb0(7,0x114);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  FUN_0043ce50(uVar2,uVar5,uVar14);
  uVar14 = 0x100;
  uVar5 = extraout_ECX_02;
  FUN_00437020(0x52,0x6d,0);
  uVar2 = FUN_00436fb0(0x2f,10);
  uVar3 = FUN_00436fb0(7,0x129);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  FUN_0043ce50(uVar2,uVar5,uVar14);
  uVar14 = 0x100;
  uVar5 = extraout_ECX_03;
  FUN_00437020(0xce,0xdf,0xf7);
  uVar2 = FUN_00436fb0(0x211,0x15);
  uVar3 = FUN_00436fb0(0x37,0xfe);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  FUN_0043ce50(uVar2,uVar5,uVar14);
  uVar14 = 0x100;
  uVar5 = extraout_ECX_04;
  FUN_00437020(0xff,0xff,0xad);
  uVar2 = FUN_00436fb0(0x211,0x15);
  uVar3 = FUN_00436fb0(0x37,0x114);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  FUN_0043ce50(uVar2,uVar5,uVar14);
  FUN_005d9d50(s_ProMan10_006551e0);
  FUN_005d9d30(0xffffff);
  uVar11 = *(uint *)(param_1 + 0x144);
  *(uint *)(param_1 + 0x144) = uVar11 | 0x20;
  if ((uVar11 & 8) == 0) {
    FUN_005d9d80(s_BALANCE_00659b4c,0xc,0xe9,0x66,0xfd,0x100);
  }
  else {
    FUN_005da180(s_BALANCE_00659b4c,0xc,0xe9,0x66,0xfd,0x100,1);
  }
  FUN_005d9d50(s_ProMan10_006551e0);
  FUN_005d9d30(0);
  if ((*(uint *)(param_1 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_WEEKLY_BALANCE_TABLE_00659b34,0x14d,0xea,0x248,0xfd,0x100);
  }
  else {
    FUN_005da180(s_WEEKLY_BALANCE_TABLE_00659b34,0x14d,0xea,0x248,0xfd,0x100,1);
  }
  FUN_005d9d50(s_ProMan8_00658928);
  FUN_005d9d30(0x3c967b);
  if ((*(uint *)(param_1 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_00657558,6,0x135,0x37,0x140,0x100);
  }
  else {
    FUN_005da180(&DAT_00657558,6,0x135,0x37,0x140,0x100,1);
  }
  *(uint *)(param_1 + 0x144) = *(uint *)(param_1 + 0x144) & 0xffffffdf;
  FUN_005d9d30(0);
  if ((*(uint *)(param_1 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_006558bc,0x2d,0x135,0x4a,0x140,0x100);
  }
  else {
    FUN_005da180(&DAT_006558bc,0x2d,0x135,0x4a,0x140,0x100,1);
  }
  if ((*(uint *)(param_1 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_00655308,0x87,0x135,0xa4,0x140,0x100);
  }
  else {
    FUN_005da180(&DAT_00655308,0x87,0x135,0xa4,0x140,0x100,1);
  }
  if ((*(uint *)(param_1 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_00655300,0xeb,0x135,0x108,0x140,0x100);
  }
  else {
    FUN_005da180(&DAT_00655300,0xeb,0x135,0x108,0x140,0x100,1);
  }
  if ((*(uint *)(param_1 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_006552f8,0x14f,0x135,0x16c,0x140,0x100);
  }
  else {
    FUN_005da180(&DAT_006552f8,0x14f,0x135,0x16c,0x140,0x100,1);
  }
  if ((*(uint *)(param_1 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_006552f0,0x1b3,0x135,0x1d0,0x140,0x100);
  }
  else {
    FUN_005da180(&DAT_006552f0,0x1b3,0x135,0x1d0,0x140,0x100,1);
  }
  if ((*(uint *)(param_1 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(&DAT_00659b30,0x217,0x135,0x234,0x140,0x100);
  }
  else {
    FUN_005da180(&DAT_00659b30,0x217,0x135,0x234,0x140,0x100,1);
  }
  pfVar9 = local_210;
  local_2cc = 0.0;
  uVar12 = 0;
  local_2dc = *(float *)(param_2 + 0x1e8);
  uVar11 = 0x37;
  do {
    pfVar8 = pfVar9;
    if ((uVar11 == 0x37) || (pfVar8 = (float *)0xa, uVar12 % 10 == 9)) {
      local_2d4 = (undefined *)0xbed6;
      ppuVar4 = &local_2d4;
    }
    else {
      local_2d0 = (undefined *)0xdedfde;
      ppuVar4 = &local_2d0;
    }
    uVar3 = 0x100;
    local_2d8 = pfVar9;
    FUN_004ac740(ppuVar4);
    uVar5 = FUN_00436fb0(9,9);
    uVar2 = FUN_00436fb0(uVar11,0x12a);
    uVar5 = FUN_00436fd0(uVar2,uVar5);
    FUN_0043ce50(uVar5,pfVar8,uVar3);
    fVar13 = (float10)FUN_0057fce0(uVar12);
    local_2c0 = (double)CONCAT44(local_2c0._4_4_,(float)fVar13);
    local_2c8[0] = (undefined1 *)0x0;
    FUN_00580710(uVar12);
    iVar6 = FUN_004ecf70(local_2c8);
    if (iVar6 == 0) {
      fVar1 = (float)local_2c0 - local_2dc;
      if (fVar1 <= _DAT_0062d918) {
        if ((fVar1 < _DAT_0062d918) && (local_2cc < -fVar1)) {
          local_2cc = -fVar1;
        }
      }
      else if (local_2cc < fVar1) {
        local_2cc = fVar1;
      }
      local_2dc = fVar1 + local_2dc;
      *local_2d8 = fVar1;
    }
    else {
      *local_2d8 = 0.0;
    }
    uVar11 = uVar11 + 10;
    uVar12 = uVar12 + 1;
    pfVar9 = local_2d8 + 1;
  } while (uVar11 < 0x23f);
  uVar3 = 0x100;
  local_2d8 = pfVar9;
  FUN_00437020(0xde,0xdf,0xde);
  uVar5 = FUN_00436fb0(9,9);
  uVar2 = FUN_00436fb0(0x23f,0x12a);
  uVar5 = FUN_00436fd0(uVar2,uVar5);
  FUN_0043ce50(uVar5,pfVar9,uVar3);
  if (local_2cc != _DAT_0062d918) {
    pfVar9 = (float *)(s_Mrecursos_iconos_caja_flechar_bm_0065954b + 1);
    fVar1 = _DAT_00659548;
    do {
      pfVar8 = pfVar9 + -1;
      pfVar9 = pfVar9 + -1;
      if (local_2cc <= *pfVar8) {
        fVar1 = *pfVar9;
      }
    } while (pfVar9 != (float *)&DAT_00659540);
    uVar11 = 0x3a;
    pfVar9 = local_210;
    local_2c0 = (double)CONCAT44(local_2c0._4_4_,fVar1 * _DAT_0062d920);
    puVar10 = &DAT_00659540;
    local_2cc = fVar1;
    do {
      local_2dc = *pfVar9 / (float)local_2c0;
      if (local_2dc <= _DAT_0062d918) {
        if (local_2dc < _DAT_0062d918) {
          if (uVar11 < 0x45) {
            local_2c8[0] = &LAB_00525dff;
            local_2e0 = &LAB_00525dff;
          }
          else {
            local_2d0 = (undefined *)0xad;
            local_2e0 = (undefined1 *)0xad;
            puVar10 = local_2d0;
          }
          local_2dc = -local_2dc;
          uVar5 = 0x100;
          if (local_2dc <= _DAT_0062d924) {
            FUN_004ac740(&local_2e0);
            uVar2 = ftol();
            uVar2 = FUN_00436fb0(7,uVar2);
            uVar3 = FUN_00436fb0(uVar11 - 2,0x114);
            goto LAB_00509d5b;
          }
          FUN_004ac740(&local_2e0);
          uVar2 = FUN_00436fb0(7,0x12);
          uVar3 = FUN_00436fb0(uVar11 - 2,0x114);
          uVar2 = FUN_00436fd0(uVar3,uVar2);
          FUN_0043ce50(uVar2,puVar10,uVar5);
          uVar2 = 5;
          puVar15 = local_2e0;
          uVar5 = FUN_00436fb0(uVar11 - 1,0x126);
          FUN_0043c970(uVar5,uVar2,puVar15);
          uVar2 = 3;
          puVar15 = local_2e0;
          uVar5 = FUN_00436fb0(uVar11,0x127);
          FUN_0043c970(uVar5,uVar2,puVar15);
          uVar2 = 1;
          puVar15 = local_2e0;
          uVar5 = FUN_00436fb0(uVar11 + 1,0x128);
          FUN_0043c970(uVar5,uVar2,puVar15);
          puVar10 = extraout_ECX_06;
        }
      }
      else {
        if (uVar11 < 0x45) {
          local_2d4 = (undefined *)0xbd9273;
          local_2e0 = (undefined1 *)0xbd9273;
        }
        else {
          local_2d8 = (float *)0xad3c29;
          local_2e0 = (undefined1 *)0xad3c29;
        }
        uVar5 = 0x100;
        if (local_2dc <= _DAT_0062d924) {
          FUN_004ac740(&local_2e0);
          uVar2 = ftol();
          uVar2 = FUN_00436fb0(7,uVar2);
          uVar3 = ftol(uVar2);
          uVar3 = FUN_00436fb0(uVar11 - 2,uVar3);
LAB_00509d5b:
          uVar2 = FUN_00436fd0(uVar3,uVar2);
          FUN_0043ce50(uVar2,puVar10,uVar5);
          puVar10 = extraout_ECX_07;
        }
        else {
          FUN_004ac740(&local_2e0);
          uVar2 = FUN_00436fb0(7,0x12);
          uVar3 = FUN_00436fb0(uVar11 - 2,0x102);
          uVar2 = FUN_00436fd0(uVar3,uVar2);
          FUN_0043ce50(uVar2,puVar10,uVar5);
          uVar2 = 5;
          puVar15 = local_2e0;
          uVar5 = FUN_00436fb0(uVar11 - 1,0x101);
          FUN_0043c970(uVar5,uVar2,puVar15);
          uVar2 = 3;
          puVar15 = local_2e0;
          uVar5 = FUN_00436fb0(uVar11,0x100);
          FUN_0043c970(uVar5,uVar2,puVar15);
          uVar2 = 1;
          puVar15 = local_2e0;
          uVar5 = FUN_00436fb0(uVar11 + 1,0xff);
          FUN_0043c970(uVar5,uVar2,puVar15);
          puVar10 = extraout_ECX_05;
        }
      }
      uVar11 = uVar11 + 10;
      pfVar9 = pfVar9 + 1;
    } while (uVar11 < 0x242);
    FUN_005d9d30(0xbd9273);
    FUN_005d9d50(s_euro8_006597a4);
    local_100 = 0;
    local_2c0 = (double)(local_2cc * (float)_DAT_0062d930);
    pCVar7 = (LPCSTR)FUN_005e5ee0(local_2c0,0);
    lstrcpyA((LPSTR)local_210,&DAT_006587d4);
    iVar6 = lstrlenA((LPCSTR)local_210);
    lstrcpyA((LPSTR)((int)local_210 + iVar6),pCVar7);
    pCVar7 = &DAT_00659b2c;
    iVar6 = lstrlenA((LPCSTR)local_210);
    lstrcpyA((LPSTR)((int)local_210 + iVar6),pCVar7);
    if ((*(uint *)(param_1 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(local_210,7,0xfe,0x36,0x113,0x100);
    }
    else {
      FUN_005da180(local_210,7,0xfe,0x36,0x113,0x100,1);
    }
    FUN_005d9d30(0x1cff);
    local_2b8 = 7;
    local_2b0 = 0x36;
    local_100 = 0;
    pCVar7 = (LPCSTR)FUN_005e5ee0((float)local_2c0,local_2c0._4_4_,0);
    lstrcpyA((LPSTR)local_210,&DAT_00654448);
    iVar6 = lstrlenA((LPCSTR)local_210);
    lstrcpyA((LPSTR)((int)local_210 + iVar6),pCVar7);
    pCVar7 = &DAT_00659b2c;
    iVar6 = lstrlenA((LPCSTR)local_210);
    lstrcpyA((LPSTR)((int)local_210 + iVar6),pCVar7);
    if ((*(uint *)(param_1 + 0x144) >> 3 & 1) != 0) {
      FUN_005da180(local_210,local_2b8,0x114,local_2b0,0x129,0x100,1);
      return;
    }
    FUN_005d9d80(local_210,local_2b8,0x114,local_2b0,0x129,0x100);
  }
  return;
}


