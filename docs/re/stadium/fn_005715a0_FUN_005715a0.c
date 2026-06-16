// FUN_005715a0  entry=005715a0  size=561 bytes

undefined4 __thiscall FUN_005715a0(int param_1,int param_2,int param_3,int param_4)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  undefined4 uVar4;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  undefined4 extraout_ECX_02;
  undefined1 *puVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  undefined1 local_20 [8];
  undefined4 local_18;
  int iStack_c;
  
  FUN_00437be0(local_20,param_2 + 0x78);
  uVar8 = 0;
  uVar4 = extraout_ECX;
  FUN_00436270(0xffffff);
  uVar7 = 0;
  uVar6 = 2;
  puVar5 = &DAT_00666f70;
  uVar1 = FUN_00436fb0(local_18,param_3);
  uVar2 = FUN_00436fb0(0,param_4 - param_3);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  iVar3 = FUN_005bc780(param_2,uVar1,puVar5,uVar6,uVar7,uVar4,uVar8);
  uVar4 = 0;
  if (iVar3 != 0) {
    *(int *)(param_1 + 0x438) = param_3;
    *(int *)(param_1 + 0x43c) = param_4;
    *(char **)(param_1 + 0x430) = s_INFOFUT_GENERAL_HTM_00661bac;
    *(undefined **)(param_1 + 0x434) = &DAT_00661ba4;
    *(undefined4 *)(param_1 + 0x1088) = 0;
    FUN_005c06d0(s_RECURSOS_PREMIER_barraPopUp_bmp_00661bc0,0,0,0x32,0);
    uVar8 = 0xffffffff;
    iVar3 = *(int *)(param_1 + 0x440);
    uVar4 = extraout_ECX_00;
    FUN_00436270(0xffffffff);
    uVar7 = 10000;
    uVar6 = 0;
    puVar5 = &DAT_00666f70;
    uVar1 = FUN_00436fb0(0x20,0x24);
    uVar2 = FUN_00436fb0(0x24f,4);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    (**(code **)(iVar3 + 0xc0))(param_1,uVar1,puVar5,uVar6,uVar7,uVar4,uVar8);
    FUN_005c06d0(s_RECURSOS_iconos_minicasc00_bmp_00661b84,0,0,0x32,0);
    FUN_005c06d0(s_RECURSOS_iconos_minicasc_gif_00661b64,1,0,0x32,0);
    *(undefined2 *)(param_1 + 2000) = 0x100;
    uVar4 = extraout_ECX_01;
    if ((~(byte)(*(uint *)(param_1 + 0x4ec) >> 7) & 1) != 0) {
      FUN_005bf8c0(0,1);
      uVar4 = extraout_ECX_02;
    }
    if (iStack_c != 0) {
      uVar8 = 0xffffffff;
      iVar3 = *(int *)(param_1 + 0xc70);
      FUN_00436270(0xffffffff);
      uVar7 = 0x2712;
      uVar6 = 0;
      puVar5 = &DAT_00666f70;
      uVar1 = FUN_00436fb0(0x31,0x24);
      uVar2 = FUN_00436fb0(0x213,3);
      uVar1 = FUN_00436fd0(uVar2,uVar1);
      (**(code **)(iVar3 + 0xc0))(param_1,uVar1,puVar5,uVar6,uVar7,uVar4,uVar8);
      FUN_005c06d0(s_RECURSOS_iconos_MiniOpcion00_bmp_00661b40,0,0,0x32,0);
      FUN_005c06d0(s_RECURSOS_iconos_MiniOpcion_gif_00661b20,1,0,0x32,0);
      *(undefined2 *)(param_1 + 0x1000) = 0x100;
      if ((~(byte)(*(uint *)(param_1 + 0xd1c) >> 7) & 1) != 0) {
        FUN_005bf8c0(0,1);
      }
    }
    FUN_005bf140(100,500);
    uVar4 = local_18;
  }
  return uVar4;
}


