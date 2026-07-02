// FUN_005264d0  entry=005264d0  size=360 bytes

undefined4 __thiscall FUN_005264d0(int param_1,undefined4 param_2,int param_3,int param_4)

{
  byte bVar1;
  bool bVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  int iVar5;
  uint uVar6;
  char *pcVar7;
  undefined1 *puVar8;
  undefined4 uVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined4 uStack_14;
  
  if ((param_3 != 0) && (param_4 != 0)) {
    uVar11 = 0xffffff;
    iVar5 = param_1;
    FUN_00436270(0xffffff);
    uVar10 = 0;
    uVar9 = 0x1402;
    puVar8 = &DAT_00666f70;
    uVar3 = FUN_00436fb0(0x1e8,0x16b);
    uVar4 = FUN_00436fb0(0x4c,0x3a);
    uVar3 = FUN_00436fd0(uVar4,uVar3);
    iVar5 = FUN_005c55b0(param_2,uVar3,puVar8,uVar9,uVar10,iVar5,uVar11);
    if (iVar5 != 0) {
      bVar2 = true;
      goto LAB_00526550;
    }
  }
  bVar2 = false;
LAB_00526550:
  uVar3 = 0;
  if (bVar2) {
    *(int *)(param_1 + 0x430) = param_4;
    *(int *)(param_1 + 0x434) = param_3;
    FUN_005beae0(s_ProMan12_006567d4);
    FUN_005bebc0(6);
    FUN_005c9f60(s_RECURSOS_ICONOS_bluegrad_bmp_0065bc28,0,0xffffffff);
    uVar3 = FUN_00586d20(**(undefined2 **)(param_1 + 0x434));
    *(undefined4 *)(param_1 + 0x438) = uVar3;
    pcVar7 = s_PLAYER_PLACED_ON_TRANSFER_MARKET_0065bc04;
    bVar1 = *(byte *)(*(int *)(param_1 + 0x434) + 0x98);
    uVar6 = (uint)bVar1;
    if (bVar1 == 0) {
      pcVar7 = &DAT_00666f70;
    }
    uVar11 = 0xffffff;
    iVar5 = *(int *)(param_1 + 0xcb8);
    FUN_00437020(0x52,0x6d,0);
    uVar10 = 0;
    uVar9 = 0;
    uVar3 = FUN_00436fb0(0x1a5,0xe);
    uVar4 = FUN_00436fb0(0x3c,0x132);
    uVar3 = FUN_00436fd0(uVar4,uVar3);
    (**(code **)(iVar5 + 0xc0))(param_1,uVar3,pcVar7,uVar9,uVar10,uVar6,uVar11);
    FUN_005beae0(s_ProMan10_006551e0);
    uVar3 = uStack_14;
  }
  return uVar3;
}


