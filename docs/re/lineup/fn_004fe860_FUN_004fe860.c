// FUN_004fe860  entry=004fe860  size=1776 bytes

void __thiscall FUN_004fe860(int param_1,int param_2)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 *puVar5;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  undefined4 extraout_ECX_02;
  undefined4 extraout_ECX_03;
  int iVar6;
  undefined4 uVar7;
  undefined4 uStack_28;
  int iStack_24;
  undefined4 uStack_20;
  undefined4 uStack_1c;
  undefined1 auStack_18 [24];
  
  if (*(int *)(param_1 + 0xd78) != 0) {
    iVar6 = *(int *)(DAT_0066afd0 + 0x1c) * 0x10;
    uVar1 = FUN_005c12b0(0xffffffff);
    FUN_004f51e0(param_2);
    uVar7 = 0x100;
    uStack_28 = 0x54;
    iStack_24 = 0xc6;
    uVar2 = FUN_00436fb0(0,0);
    uVar4 = uVar1;
    uVar3 = FUN_004b7f40(auStack_18);
    uVar3 = FUN_00436fd0(&uStack_28,uVar3);
    FUN_004f7f20(uVar3,uVar4,uVar2,uVar7);
    uVar3 = 0x100;
    uStack_28 = 0x54;
    iStack_24 = iVar6 + 0xdc;
    uVar4 = FUN_00436fb0(0,0);
    uVar2 = FUN_004b7f40(&uStack_20);
    uVar2 = FUN_00436fd0(&uStack_28,uVar2);
    FUN_004f7f20(uVar2,uVar1,uVar4,uVar3);
    FUN_005d9d30(0x800000);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(&DAT_006593ac,0x19,5,0x30,0x11,0x100);
    }
    else {
      FUN_005da180(&DAT_006593ac,0x19,5,0x30,0x11,0x100,1);
    }
    FUN_005d9d30(0x96);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(&DAT_006593a8,0xa6,5,0xbf,0x11,0x100);
    }
    else {
      FUN_005da180(&DAT_006593a8,0xa6,5,0xbf,0x11,0x100,1);
    }
    FUN_005d9d30(0x8c6464);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(&DAT_006593a4,0xbf,5,0xd8,0x11,0x100);
    }
    else {
      FUN_005da180(&DAT_006593a4,0xbf,5,0xd8,0x11,0x100,1);
    }
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(&DAT_006593a0,0xd8,5,0xf1,0x11,0x100);
    }
    else {
      FUN_005da180(&DAT_006593a0,0xd8,5,0xf1,0x11,0x100,1);
    }
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(&DAT_0065939c,0xf0,5,0x109,0x11,0x100);
    }
    else {
      FUN_005da180(&DAT_0065939c,0xf0,5,0x109,0x11,0x100,1);
    }
    uStack_28 = 0x19;
    iStack_24 = 0xc;
    uStack_20 = 0x10a;
    uStack_1c = 5;
    puVar5 = (undefined4 *)FUN_00436fd0(&uStack_20,&uStack_28);
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      FUN_005d9d80(&DAT_00659398,*puVar5,puVar5[1],puVar5[2],puVar5[3],0x100);
      uVar4 = extraout_ECX_00;
    }
    else {
      FUN_005da180(&DAT_00659398,*puVar5,puVar5[1],puVar5[2],puVar5[3],0x100,1);
      uVar4 = extraout_ECX;
    }
    FUN_00437020(0x2a,0x5f,0xaa);
    FUN_005d9d30(uVar4);
    uVar4 = 0x100;
    uStack_20 = 0x19;
    uStack_1c = 0xc;
    uStack_28 = 0x125;
    iStack_24 = 5;
    puVar5 = (undefined4 *)FUN_00436fd0(&uStack_28,&uStack_20);
    FUN_004ca3c0(&DAT_00659394,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar4);
    uVar4 = extraout_ECX_01;
    FUN_00437020(0x50,0x6e,5);
    FUN_005d9d30(uVar4);
    puVar5 = &uStack_20;
    uVar1 = 0x100;
    uStack_20 = 0x19;
    uStack_1c = 0xc;
    uVar4 = FUN_00436fb0(0x13d,5);
    puVar5 = (undefined4 *)FUN_00436fd0(uVar4,puVar5);
    FUN_004ca3c0(&DAT_00659390,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar1);
    uVar4 = extraout_ECX_02;
    FUN_00437020(0xd4,0x5f,0);
    FUN_005d9d30(uVar4);
    puVar5 = &uStack_20;
    uVar1 = 0x100;
    uStack_20 = 0x19;
    uStack_1c = 0xc;
    uVar4 = FUN_00436fb0(0x156,5);
    puVar5 = (undefined4 *)FUN_00436fd0(uVar4,puVar5);
    FUN_004ca3c0(&DAT_0065938c,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar1);
    FUN_005d9d30(0);
    puVar5 = &uStack_20;
    uVar1 = 0x100;
    uStack_20 = 0x20;
    uStack_1c = 0xc;
    uVar4 = FUN_00436fb0(0x16c,5);
    puVar5 = (undefined4 *)FUN_00436fd0(uVar4,puVar5);
    FUN_004ca3c0(&PTR_LAB_004c4f4e_4_00659388,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar1);
    puVar5 = &uStack_20;
    uVar1 = 0x100;
    uStack_20 = 0x58;
    uStack_1c = 0xc;
    uVar4 = FUN_00436fb0(0x3f,5);
    puVar5 = (undefined4 *)FUN_00436fd0(uVar4,puVar5);
    FUN_004ca3c0(s_PLAYER_00652f0c,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar1);
    puVar5 = &uStack_20;
    uVar1 = 0x100;
    uStack_20 = 0xee;
    uStack_1c = 0xc;
    uVar4 = FUN_00436fb0(0x67,0xcc);
    puVar5 = (undefined4 *)FUN_00436fd0(uVar4,puVar5);
    FUN_004ca3c0(s_SUBSTITUTES_0065937c,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar1);
    puVar5 = &uStack_20;
    uVar1 = 0x100;
    uStack_20 = 0x10c;
    uStack_1c = 0xc;
    uVar4 = FUN_00436fb0(0x68,iVar6 + 0xe2);
    puVar5 = (undefined4 *)FUN_00436fd0(uVar4,puVar5);
    FUN_004ca3c0(s_RESERVES_00659370,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar1);
    uVar4 = extraout_ECX_03;
    FUN_00437020(0x80,0x80,0x80);
    FUN_005d9d30(uVar4);
    puVar5 = &uStack_20;
    uVar1 = 0x100;
    uStack_20 = 0x22;
    uStack_1c = 0xc;
    uVar4 = FUN_00436fb0(0x18a,5);
    puVar5 = (undefined4 *)FUN_00436fd0(uVar4,puVar5);
    FUN_004ca3c0(&DAT_00654060,*puVar5,puVar5[1],puVar5[2],puVar5[3],uVar1);
    return;
  }
  *(undefined4 *)(param_1 + 0xd78) = 1;
  return;
}


