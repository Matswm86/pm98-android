// FUN_005d8520  entry=005d8520  size=2220 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined1 __thiscall
FUN_005d8520(int *param_1,undefined4 *param_2,int param_3,int *param_4,int param_5,int param_6,
            int param_7)

{
  bool bVar1;
  bool bVar2;
  byte bVar3;
  undefined4 uVar4;
  int iVar5;
  int *piVar6;
  int iVar7;
  int *piVar8;
  int iVar9;
  undefined4 *puVar10;
  int iVar11;
  undefined1 *puVar12;
  undefined4 uVar13;
  undefined1 uVar14;
  undefined4 uVar15;
  bool local_1ce;
  int local_1cc;
  int local_1c0;
  int local_1b8;
  int local_1b4;
  int local_1b0;
  int local_1ac;
  int local_1a8;
  int local_1a4;
  int local_1a0;
  int local_19c;
  int local_198;
  int local_194;
  int local_190;
  int local_18c;
  int local_188;
  int local_17c;
  int local_178;
  int local_174;
  int local_170;
  undefined4 local_16c;
  undefined4 local_168;
  undefined4 local_164;
  undefined4 local_160;
  undefined4 local_15c;
  undefined4 local_158;
  int local_154;
  int local_150;
  int local_14c;
  int local_148;
  int local_144;
  int local_140;
  undefined4 local_13c;
  undefined4 local_138;
  undefined4 local_134;
  int local_130;
  int local_12c;
  int local_128;
  undefined4 local_124;
  undefined4 local_120;
  undefined4 local_11c;
  int local_118;
  int local_114;
  int local_110;
  int local_10c;
  int local_108;
  int local_104;
  int local_100;
  int local_fc;
  int local_f8;
  int local_f4;
  int local_f0;
  int local_ec;
  undefined4 local_e8;
  undefined4 local_e4;
  undefined4 local_e0;
  int local_dc;
  int local_d8;
  int local_d4;
  undefined4 local_d0;
  undefined4 local_cc;
  undefined4 local_c8;
  int local_c4;
  int local_c0;
  int local_bc;
  int local_b8;
  int local_b4;
  int local_b0;
  undefined4 local_ac;
  undefined4 local_a8;
  undefined4 local_a4;
  int local_a0;
  int local_9c;
  int local_98 [5];
  float local_84;
  int local_80;
  int local_7c;
  int local_78;
  int local_74;
  int local_70;
  int local_6c;
  int local_68;
  int local_64;
  undefined1 local_20 [32];
  
  bVar1 = false;
  if ((param_1[0x5a] == 0) || (*(char *)(param_1[0x5a] + 0x3d0) == '\0')) {
    bVar2 = false;
  }
  else {
    bVar2 = true;
  }
  if (bVar2) {
    if (param_5 != 9) {
      return true;
    }
    uVar15 = 0;
    uVar13 = 4;
    puVar10 = param_2;
    uVar4 = FUN_005db4a0(param_1[0x42],param_1[0x43],param_1[0x40],param_1[0x44],param_1[0x45],
                         param_1[0x41]);
    iVar5 = FUN_005eedb0(uVar4,uVar13,puVar10,uVar15);
    if (iVar5 == 0) {
      return true;
    }
    bVar3 = *(byte *)(&DAT_006c29b4 + param_3);
    if ((DAT_006c2988 != 0) ||
       (DAT_006c2988 = FUN_005f69b0(s_redh_bmp_00664b94,0,0xffffffff), DAT_006c2988 != 0)) {
      FUN_005f67c0(param_1);
    }
    if ((*param_1 != 0) || (param_1[0x10] != 0)) {
      FUN_005cb320();
    }
    FUN_005ef2b0(4,param_2,&local_a0);
    piVar8 = param_2 + 2;
    piVar6 = local_98 + 2;
    iVar5 = 4;
    do {
      if (*piVar8 == 0) {
        piVar6[-2] = 0;
      }
      *piVar6 = -1;
      piVar6[1] = 0;
      piVar6[-1] = 0;
      piVar6[2] = 0x3f7e0000;
      piVar6[3] = (int)((float)(int)((uint)bVar3 * 2 + -0x100) * (float)_DAT_00639ac0);
      piVar8 = piVar8 + 3;
      piVar6 = piVar6 + 8;
      iVar5 = iVar5 + -1;
    } while (iVar5 != 0);
    FUN_005db240(0);
    FUN_005d8380();
    uVar14 = 0;
    (**(code **)(*(int *)param_1[0x5c] + 0x74))((int *)param_1[0x5c],6,2,&local_a0,4,8);
    return uVar14;
  }
  if ((*param_4 < param_4[2]) && (param_4[1] < param_4[3])) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  if (!bVar2) {
    return true;
  }
  FUN_00404a80(local_20,8,4,FUN_005c8f80);
  iVar5 = FUN_005eec60(param_1 + 0x3c,param_2,local_20,4);
  FUN_0044cac0();
  iVar9 = 4;
  puVar12 = (undefined1 *)register0x00000010;
  do {
    puVar12 = puVar12 + -8;
    FUN_005d42b0(puVar12);
    iVar7 = local_18c;
    iVar11 = local_194;
    iVar9 = iVar9 + -1;
  } while (iVar9 != 0);
  local_1ce = iVar5 == 0;
  if (param_6 == -1) {
    param_6 = 1;
  }
  else {
    if ((3 < iVar5) || (param_6 < 1)) goto LAB_005d8818;
    if (local_1ce) {
      FUN_00437be0(&local_17c,param_1 + 0xe);
      iVar5 = iVar11;
      if (iVar11 <= local_17c) {
        iVar5 = local_17c;
      }
      iVar9 = local_174;
      if (iVar7 < local_174) {
        iVar9 = iVar7;
      }
      if (iVar5 < iVar9) {
        iVar5 = local_190;
        if (local_190 <= local_178) {
          iVar5 = local_178;
        }
        if (local_188 < local_170) {
          local_170 = local_188;
        }
        if (iVar5 < local_170) {
          local_1ce = true;
          if ((((iVar7 - iVar11 < 0x21) || (local_188 - local_190 < 0x21)) ||
              ((iVar7 - iVar11) * 2 <= (param_4[2] - *param_4) * 3)) ||
             ((local_188 - local_190) * 2 <= (param_4[3] - param_4[1]) * 3)) goto LAB_005d8818;
          goto LAB_005d8813;
        }
      }
      local_1ce = false;
      goto LAB_005d8818;
    }
  }
LAB_005d8813:
  bVar1 = true;
LAB_005d8818:
  if (bVar1) {
    piVar8 = &local_1ac;
    uVar4 = 2;
    FUN_005a1700(&local_1b8,param_2 + 3);
    FUN_005a1870(piVar8,uVar4);
    piVar8 = &local_17c;
    uVar4 = 2;
    FUN_005a1700(&local_1b8,param_2 + 6);
    FUN_005a1870(piVar8,uVar4);
    piVar8 = &local_1a0;
    uVar4 = 2;
    FUN_005a1700(&local_1b8,param_2 + 9);
    FUN_005a1870(piVar8,uVar4);
    puVar10 = &local_16c;
    uVar4 = 2;
    FUN_005a1700(&local_1b8,param_2);
    FUN_005a1870(puVar10,uVar4);
    FUN_00590aa0(local_1a0 + local_1ac,local_19c + local_1a8,local_198 + local_1a4);
    FUN_00590aa0(local_1b8 / 2,local_1b4 / 2,local_1b0 / 2);
    puVar10 = &local_160;
    local_1cc = 4;
    do {
      FUN_00404a80(puVar10,0xc,4,FUN_005c8f80);
      puVar10 = puVar10 + 0xc;
      local_1cc = local_1cc + -1;
    } while (local_1cc != 0);
    iVar5 = param_4[2];
    local_98[0] = *param_4;
    iVar9 = param_4[1];
    iVar11 = (iVar5 + local_98[0]) / 2;
    local_1b4 = (iVar9 + param_4[3]) / 2;
    local_a0 = iVar11;
    if (local_98[0] < iVar11) {
      local_a0 = local_98[0];
    }
    if (local_98[0] <= iVar11) {
      local_98[0] = iVar11;
    }
    local_9c = iVar9;
    if (local_1b4 <= iVar9) {
      local_9c = local_1b4;
    }
    local_98[1] = local_1b4;
    if (local_1b4 < iVar9) {
      local_98[1] = iVar9;
    }
    FUN_00436fb0(iVar5,iVar9);
    local_98[2] = iVar5;
    if (iVar11 <= iVar5) {
      local_98[2] = iVar11;
    }
    local_98[4] = iVar5;
    if (iVar5 <= iVar11) {
      local_98[4] = iVar11;
    }
    local_98[3] = local_1c0;
    if (local_1b4 <= local_1c0) {
      local_98[3] = local_1b4;
    }
    local_84 = (float)local_1c0;
    if (local_1c0 <= local_1b4) {
      local_84 = (float)local_1b4;
    }
    local_78 = param_4[2];
    local_80 = local_78;
    if (iVar11 <= local_78) {
      local_80 = iVar11;
    }
    if (local_78 <= iVar11) {
      local_78 = iVar11;
    }
    local_74 = param_4[3];
    local_7c = local_74;
    if (local_1b4 <= local_74) {
      local_7c = local_1b4;
    }
    if (local_74 <= local_1b4) {
      local_74 = local_1b4;
    }
    FUN_00436fb0(*param_4,param_4[3]);
    local_70 = iVar5;
    if (iVar11 <= iVar5) {
      local_70 = iVar11;
    }
    local_68 = iVar5;
    if (iVar5 <= iVar11) {
      local_68 = iVar11;
    }
    local_6c = local_1c0;
    if (local_1b4 <= local_1c0) {
      local_6c = local_1b4;
    }
    if (local_1c0 <= local_1b4) {
      local_1c0 = local_1b4;
    }
    local_13c = local_16c;
    local_138 = local_168;
    local_134 = local_164;
    local_130 = local_1ac;
    local_12c = local_1a8;
    local_128 = local_1a4;
    local_124 = param_2[3];
    local_120 = param_2[4];
    local_11c = param_2[5];
    local_118 = local_17c;
    local_f4 = local_17c;
    local_160 = *param_2;
    local_15c = param_2[1];
    local_f0 = local_178;
    local_e8 = param_2[6];
    local_158 = param_2[2];
    local_e4 = param_2[7];
    local_e0 = param_2[8];
    local_d4 = local_198;
    local_154 = local_1ac;
    local_150 = local_1a8;
    local_114 = local_178;
    local_d0 = local_16c;
    local_14c = local_1a4;
    local_144 = local_190;
    local_140 = local_18c;
    local_110 = local_174;
    local_108 = local_190;
    local_104 = local_18c;
    local_fc = local_190;
    local_f8 = local_18c;
    local_ec = local_174;
    local_cc = local_168;
    local_c0 = local_190;
    local_bc = local_18c;
    local_ac = param_2[9];
    local_148 = local_194;
    local_10c = local_194;
    local_100 = local_194;
    local_dc = local_1a0;
    local_d8 = local_19c;
    local_c8 = local_164;
    local_c4 = local_194;
    local_b8 = local_1a0;
    local_b4 = local_19c;
    local_b0 = local_198;
    local_a8 = param_2[10];
    local_a4 = param_2[0xb];
    local_1ce = true;
    puVar10 = &local_160;
    piVar8 = &local_a0;
    iVar5 = 4;
    local_64 = local_1c0;
    do {
      bVar3 = FUN_005d8520(puVar10,param_3,piVar8,param_5,param_6 + -1,param_7);
      piVar8 = piVar8 + 4;
      local_1ce = (bool)(local_1ce & bVar3);
      puVar10 = puVar10 + 0xc;
      iVar5 = iVar5 + -1;
    } while (iVar5 != 0);
    return local_1ce;
  }
  if (local_1ce != false) {
    param_7 = param_7 + -1;
    iVar5 = *param_4;
    iVar9 = param_4[1];
    iVar11 = param_4[2];
    iVar7 = param_4[3];
    if (param_7 != 0) {
      do {
        if ((iVar11 - iVar5 <= local_18c - local_194) || (iVar7 - iVar9 <= local_188 - local_190))
        break;
        iVar5 = iVar5 / 2;
        iVar9 = iVar9 / 2;
        iVar11 = iVar11 / 2;
        iVar7 = iVar7 / 2;
        param_7 = param_7 + -1;
      } while (param_7 != 0);
    }
    if (param_5 != 9) {
      FUN_005cc670(local_20,param_3,iVar5,iVar9,iVar11,iVar7,param_5,0);
      return local_1ce;
    }
    FUN_005d2810(4,local_20,param_3);
  }
  return local_1ce;
}


