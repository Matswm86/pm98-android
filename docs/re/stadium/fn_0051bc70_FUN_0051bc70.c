// FUN_0051bc70  entry=0051bc70  size=263 bytes

int __thiscall FUN_0051bc70(int param_1,undefined4 param_2,int param_3)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  undefined1 *puVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  
  uVar7 = 0xffffffff;
  iVar3 = param_1;
  FUN_00437020(0,0,0x84);
  uVar6 = 0;
  uVar5 = 0x28;
  puVar4 = &DAT_00666f70;
  uVar1 = FUN_00436fb0(0x10d,0x18c);
  uVar2 = FUN_00436fb0(0xc,0x45);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  iVar3 = FUN_005bc780(param_2,uVar1,puVar4,uVar5,uVar6,iVar3,uVar7);
  if (iVar3 != 0) {
    FUN_005beae0(s_Proman14_00652ebc);
    *(undefined4 *)(param_1 + 0x54) = *(undefined4 *)(param_3 + 0x1e0);
    FUN_005c9f60(s_recursos_iconos_estadio_Enobras__0065b41c,0,0xffffffff);
    FUN_005c9f60(s_recursos_iconos_estadio_EnobrasM_0065b3f4,0,0xffffffff);
    FUN_005c9f60(s_recursos_iconos_estadio_gradas_b_0065b3d0,0,0xffffffff);
    FUN_005c9f60(s_recursos_iconos_estadio_parking__0065b3ac,0,0xffffffff);
    FUN_005c9f60(s_recursos_iconos_estadio_equipam__0065b388,0,0xffffffff);
    FUN_005c9f60(s_recursos_iconos_estadio_extras_b_0065b364,0,0xffffffff);
  }
  return iVar3;
}


