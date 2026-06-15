// FUN_0050bc50  entry=0050bc50  size=1256 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined1 * __thiscall FUN_0050bc50(int param_1,undefined4 param_2,undefined4 param_3)

{
  float fVar1;
  int iVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  int extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined1 *puVar5;
  undefined4 uVar6;
  undefined4 uStack_1c4;
  undefined4 uStack_1c0;
  undefined4 uStack_1bc;
  int iStack_1b8;
  undefined4 uStack_1b4;
  char *pcStack_1b0;
  undefined4 uStack_1ac;
  undefined4 uStack_1a8;
  undefined4 uStack_1a4;
  undefined4 uStack_1a0;
  int iStack_19c;
  undefined4 uStack_198;
  undefined1 *puStack_194;
  undefined4 uStack_190;
  undefined4 uStack_18c;
  undefined4 uStack_188;
  undefined4 uStack_184;
  int iStack_180;
  undefined4 uStack_17c;
  char *pcStack_178;
  undefined4 uStack_174;
  undefined4 uStack_170;
  undefined4 uStack_16c;
  int iStack_168;
  int iStack_164;
  undefined4 uStack_160;
  undefined *puStack_15c;
  undefined4 uStack_158;
  undefined1 *puStack_154;
  int iStack_150;
  char *local_14c;
  
  local_14c = (char *)0xffffff;
  iStack_150 = 0x50bc70;
  FUN_00436270();
  local_14c = (char *)0x0;
  iStack_150 = 0x1402;
  puStack_154 = &DAT_00666f70;
  uStack_158 = 0x6a;
  puStack_15c = (undefined *)0x100;
  uStack_160 = 0x50bc8d;
  uStack_158 = FUN_00436fb0();
  puStack_15c = (undefined *)0xbb;
  uStack_160 = 0xc0;
  iStack_164 = 0x50bca1;
  puStack_15c = (undefined *)FUN_00436fb0();
  uStack_160 = 0x50bcab;
  uStack_158 = FUN_00436fd0();
  puStack_15c = (undefined *)param_2;
  uStack_160 = 0x50bcbb;
  iVar2 = FUN_005c55b0();
  puVar5 = (undefined1 *)0x0;
  if (iVar2 != 0) {
    local_14c = s_ProMan10_006551e0;
    iStack_150 = 0x50bcd5;
    FUN_005beae0();
    if (DAT_0066b1e4 == 0) {
      *(undefined4 *)(param_1 + 0x43c) = 2;
      iStack_150 = extraout_ECX;
    }
    else {
      iStack_150 = 0x34 - DAT_0066b1d8;
      *(int *)(param_1 + 0x43c) = iStack_150;
    }
    *(uint *)(param_1 + 0x438) = *(uint *)(param_1 + 0x43c) >> 1;
    switch(param_3) {
    case 0:
      *(undefined4 *)(param_1 + 0x434) = 0x4e6e6b28;
      break;
    case 1:
      *(undefined4 *)(param_1 + 0x434) = 0x4e00befc;
      break;
    case 2:
      *(undefined4 *)(param_1 + 0x434) = 0x4dc380d4;
      break;
    case 3:
      *(undefined4 *)(param_1 + 0x434) = 0x4d9d5b34;
      break;
    case 4:
      *(undefined4 *)(param_1 + 0x434) = 0x4d6e6b28;
      break;
    case 5:
      *(undefined4 *)(param_1 + 0x434) = 0x4d3532b8;
      break;
    case 6:
      *(undefined4 *)(param_1 + 0x434) = 0x4cbebc20;
      break;
    default:
      *(undefined4 *)(param_1 + 0x434) = 0x4c8f0d18;
    }
    fVar1 = *(float *)(param_1 + 0x434) * _DAT_0062e000;
    puStack_154 = (undefined1 *)0xffffff;
    *(float *)(param_1 + 0x434) = fVar1;
    *(float *)(param_1 + 0x430) = fVar1 * _DAT_0062e004;
    local_14c = (char *)0xffffff;
    iVar2 = *(int *)(param_1 + 0x440);
    uStack_158 = 0x50bdb6;
    FUN_00436270();
    puStack_154 = (undefined1 *)0xc8;
    uStack_158 = 0;
    puStack_15c = &DAT_00652e60;
    uStack_160 = 0x17;
    iStack_164 = 0x3e;
    iStack_168 = 0x50bdce;
    uStack_160 = FUN_00436fb0();
    iStack_164 = 0x4d;
    iStack_168 = 0xb0;
    uStack_16c = 0x50bddf;
    iStack_164 = FUN_00436fb0();
    iStack_168 = 0x50bde9;
    uStack_160 = FUN_00436fd0();
    iStack_168 = 0x50bdf3;
    iStack_164 = param_1;
    (**(code **)(iVar2 + 0xc0))();
    uStack_170 = 0;
    uStack_174 = 0xdf;
    iStack_168 = 0x1cff;
    iVar2 = *(int *)(param_1 + 0x858);
    pcStack_178 = (char *)0xff;
    uStack_17c = 0x50be1e;
    FUN_00437020();
    uStack_170 = 0xd2;
    uStack_174 = 0;
    pcStack_178 = s_PAY_OFF_0065a378;
    uStack_17c = 0x17;
    iStack_180 = 0x68;
    uStack_184 = 0x50be36;
    uStack_17c = FUN_00436fb0();
    iStack_180 = 0x4d;
    uStack_184 = 0x3e;
    uStack_188 = 0x50be44;
    iStack_180 = FUN_00436fb0();
    uStack_184 = 0x50be4e;
    uStack_17c = FUN_00436fd0();
    uStack_184 = 0x50be58;
    iStack_180 = param_1;
    (**(code **)(iVar2 + 0xc0))();
    uStack_18c = 0;
    uStack_184 = 0xffffff;
    iVar2 = *(int *)(param_1 + 0xc70);
    uStack_190 = 0x50be72;
    FUN_00436270();
    uStack_18c = 0x6d;
    uStack_190 = 0;
    puStack_194 = &DAT_00666f70;
    uStack_198 = 0x10;
    iStack_19c = 0x10;
    uStack_1a0 = 0x50be87;
    uStack_198 = FUN_00436fb0();
    iStack_19c = 0x33;
    uStack_1a0 = 0x80;
    uStack_1a4 = 0x50be9d;
    iStack_168 = iVar2;
    iStack_19c = FUN_00436fb0();
    uStack_1a0 = 0x50bea7;
    uStack_198 = FUN_00436fd0();
    uStack_1a0 = 0x50beb5;
    iStack_19c = param_1;
    (**(code **)(iStack_168 + 0xc0))();
    uStack_1a0 = 0;
    uStack_1a4 = 0x32;
    uStack_1a8 = 0;
    uStack_1ac = 0;
    pcStack_1b0 = s_RECURSOS_ICONOS_flechar16_bmp_0065a32c;
    uStack_1b4 = 0x50bec9;
    FUN_005c06d0();
    *(undefined2 *)(param_1 + 0xffe) = 0x80;
    uStack_1a0 = 0xffffff;
    iVar2 = *(int *)(param_1 + 0x108c);
    uStack_1a8 = 0;
    uStack_1ac = 0x50beeb;
    FUN_00436270();
    uStack_1a8 = 0x6e;
    uStack_1ac = 0;
    pcStack_1b0 = &DAT_00666f70;
    uStack_1b4 = 0x10;
    iStack_1b8 = 0x10;
    uStack_1bc = 0x50bf01;
    uStack_1b4 = FUN_00436fb0();
    iStack_1b8 = 0x33;
    uStack_1bc = 0x11;
    uStack_1c0 = 0x50bf0f;
    iStack_1b8 = FUN_00436fb0();
    uStack_1bc = 0x50bf19;
    uStack_1b4 = FUN_00436fd0();
    uStack_1bc = 0x50bf23;
    iStack_1b8 = param_1;
    (**(code **)(iVar2 + 0xc0))();
    uStack_1bc = 0;
    uStack_1c0 = 0x32;
    uStack_1c4 = 0;
    FUN_005c06d0(s_RECURSOS_ICONOS_flechal16_bmp_0065a30c,0);
    *(undefined2 *)(param_1 + 0x141a) = 0x80;
    uStack_1bc = 0xffffff;
    iVar2 = *(int *)(param_1 + 0x14a8);
    uStack_1c4 = 0;
    FUN_00436270();
    uStack_1c4 = 0x6f;
    uVar6 = 0;
    puVar5 = &DAT_00666f70;
    uVar3 = FUN_00436fb0(0x10,0x10);
    uVar4 = FUN_00436fb0(0xde,0x33);
    uVar3 = FUN_00436fd0(uVar4,uVar3);
    (**(code **)(iVar2 + 0xc0))(param_1,uVar3,puVar5,uVar6);
    FUN_005c06d0(s_RECURSOS_ICONOS_flechar16_bmp_0065a32c,0,0,0x32,0);
    *(undefined2 *)(param_1 + 0x1836) = 0x80;
    iVar2 = *(int *)(param_1 + 0x18c4);
    FUN_00436270(0);
    puVar5 = &DAT_00666f70;
    uVar3 = FUN_00436fb0(0x10,0x10);
    uVar4 = FUN_00436fb0(0x98,0x33);
    uVar3 = FUN_00436fd0(uVar4,uVar3);
    (**(code **)(iVar2 + 0xc0))(param_1,uVar3);
    FUN_005c06d0(s_RECURSOS_ICONOS_flechal16_bmp_0065a30c,0,0,0x32,0);
    *(undefined2 *)(param_1 + 0x1c52) = 0x80;
    iVar2 = *(int *)(param_1 + 0x1ce0);
    FUN_00436270(0);
    FUN_0058dd00(&uStack_1a8,(double)*(float *)(param_1 + 0x430),0,0,0);
    FUN_005c8f80();
    uVar3 = FUN_00436fb0(0x5f,0xe);
    uVar4 = FUN_00436fb0(0x21,0x34);
    uVar3 = FUN_00436fd0(uVar4,uVar3);
    (**(code **)(iVar2 + 0xc0))(param_1,uVar3);
    FUN_005beae0(s_Proman8_00652ea8);
    iVar2 = *(int *)(param_1 + 0x20f8);
    uVar3 = extraout_ECX_00;
    FUN_00436270(0);
    FUN_0058df10(&uStack_1c4,*(undefined4 *)(param_1 + 0x438),0,0,uVar3);
    uVar3 = FUN_005c8f80();
    uVar4 = FUN_00436fb0(0x36,0xe);
    uVar6 = FUN_00436fb0(0xa8,0x34);
    uVar4 = FUN_00436fd0(uVar6,uVar4);
    (**(code **)(iVar2 + 0xc0))(param_1,uVar4,uVar3);
    FUN_005beae0(s_Proman8_00652ea8);
    FUN_005bebc0(6);
  }
  return puVar5;
}


