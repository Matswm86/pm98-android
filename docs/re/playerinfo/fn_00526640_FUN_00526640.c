// FUN_00526640  entry=00526640  size=118 bytes

void __fastcall FUN_00526640(int param_1)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined1 *puVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  int iVar7;
  undefined4 uVar8;
  
  uVar8 = 0xffffffff;
  iVar1 = *(int *)(param_1 + 0x488);
  iVar7 = param_1;
  FUN_00436270(0xffffffff);
  uVar6 = 0;
  uVar5 = 0;
  puVar4 = &DAT_00666f70;
  uVar2 = FUN_00436fb0(0x28,0x28);
  uVar3 = FUN_00436fb0(7,7);
  uVar2 = FUN_00436fd0(uVar3,uVar2);
  (**(code **)(iVar1 + 0xc0))(param_1,uVar2,puVar4,uVar5,uVar6,iVar7,uVar8);
  FUN_005c06d0(s_RECURSOS_ICONOS_info_gif_0065bc48,0,0,0x32,0);
  return;
}


