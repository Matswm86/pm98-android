// FUN_0042e590  entry=0042e590  size=1330 bytes

void __thiscall FUN_0042e590(void *param_1,void *param_2)

{
  byte *pbVar1;
  char cVar2;
  int *piVar3;
  int iVar4;
  void *pvVar5;
  int iVar6;
  int *piVar7;
  uint uVar8;
  uint uVar9;
  uint uVar10;
  int iVar11;
  uint uVar12;
  uint *puVar13;
  void **ppvVar14;
  ushort uVar15;
  int *piStack_5c;
  uint uStack_58;
  int iStack_54;
  int aiStack_48 [2];
  uint uStack_40;
  int iStack_3c;
  uint uStack_38;
  void *pvStack_30;
  int iStack_2c;
  void *pvStack_28;
  uint uStack_20;
  int iStack_1c;
  undefined1 auStack_10 [16];
  
  pvStack_30 = param_1;
  FUN_00404230((void *)((int)param_1 + 0x78),(int *)&uStack_20,(void *)((int)param_1 + 0x78));
  iVar4 = *(int *)((int)param_1 + 0x40);
  iVar11 = 0;
  while ((iVar4 != 0 && (iVar11 == 0))) {
    if ((*(int *)(iVar4 + 0xb4) == 1) || (*(int *)(iVar4 + 0xb4) == 0)) {
      iVar11 = iVar4;
    }
    iVar4 = *(int *)(iVar4 + 0x40);
  }
  iVar4 = *(int *)((int)param_1 + 0xa8);
  aiStack_48[0] = iVar11;
  if ((0xdc < iVar4) && (iVar4 < 0xe1)) {
    iStack_3c = iStack_1c;
    uStack_40 = uStack_20;
    pvStack_30 = (void *)0x0;
    iStack_2c = 0;
    ppvVar14 = &pvStack_30;
    uVar15 = 0x100;
    piVar7 = (int *)(iVar11 + 0x742c + *(int *)((int)param_1 + 0x54) * 0x4c);
    piVar3 = (int *)FUN_00404470(piVar7,aiStack_48);
    piVar3 = (int *)FUN_00404180(&uStack_58,(int *)&uStack_40,piVar3);
    FUN_0040f640(param_2,piVar3,piVar7,(int *)ppvVar14,uVar15);
    return;
  }
  uStack_40 = 0;
  if ((*(byte *)((int)param_1 + 0x3f4) & 2) != 0) {
    uStack_58 = 0xbfd4;
    uStack_40 = uStack_58;
  }
  if (iVar4 < 0x96) {
    if (0x9f < iVar4) goto LAB_0042e697;
    if (0xb3 < iVar4) goto LAB_0042e6b4;
    if (iVar4 < 200) goto LAB_0042e6e5;
  }
  else {
    if (iVar4 < 0xa0) {
      iVar4 = iVar4 + -0x96;
      piStack_5c = &DAT_00497480;
      goto LAB_0042e6e5;
    }
LAB_0042e697:
    if (iVar4 < 0xb4) {
      iVar4 = iVar4 + -0xa0;
      piStack_5c = &DAT_00497498;
      goto LAB_0042e6e5;
    }
LAB_0042e6b4:
    if (iVar4 < 200) {
      iVar4 = iVar4 + -0xb4;
      piStack_5c = &DAT_00497488;
      goto LAB_0042e6e5;
    }
  }
  if (iVar4 < 0xdc) {
    iVar4 = iVar4 + -200;
    piStack_5c = &DAT_00497490;
  }
LAB_0042e6e5:
  iVar4 = iVar4 * 0x50;
  uVar8 = *(uint *)(*piStack_5c + iVar4);
  pvVar5 = (void *)FUN_00445a90(&DAT_00497e10,*(uint *)(iVar11 + 0x2d58));
  pvVar5 = (void *)FUN_0043b680(pvVar5);
  iVar6 = FUN_0043c2f0(pvVar5,uVar8);
  uVar8 = (uint)*(byte *)(iVar6 + 0x4c);
  if (uVar8 == 0) {
    uStack_58 = 0xc0c0c0;
  }
  else if (uVar8 == 1) {
    uStack_58 = 0xa8264;
  }
  else if (uVar8 == 2) {
    uStack_58 = 0xbe0000;
  }
  else {
    uStack_58 = 0xff;
  }
  FUN_00452b40(param_2,uStack_40);
  if (*(int *)(iVar11 + 0x2d4c) == 0) {
    uVar10 = iStack_1c + 2;
    pvStack_28 = (void *)(uStack_20 + 6);
    pvVar5 = (void *)(uStack_20 + 0xb8);
    pvStack_30 = pvStack_28;
    if ((int)pvVar5 <= (int)pvStack_28) {
      pvStack_30 = pvVar5;
    }
    if ((int)pvStack_28 <= (int)pvVar5) {
      pvStack_28 = pvVar5;
    }
    uVar9 = iStack_1c + 0xd;
    uVar12 = uVar10;
    if ((int)uVar9 <= (int)uVar10) {
      uVar12 = uVar9;
    }
    if ((int)uVar10 <= (int)uVar9) {
      uVar10 = uVar9;
    }
    pbVar1 = (byte *)(*piStack_5c + 0xc + iVar4);
    if ((*(uint *)((int)param_2 + 0x228) >> 3 & 1) == 0) {
      FUN_00452b90(param_2,pbVar1,(uint)pvStack_30,uVar12,(uint)pvStack_28,uVar10,0x100);
    }
    else {
      FUN_00452f90(param_2,pbVar1,(uint)pvStack_30,uVar12,(uint)pvStack_28,uVar10,0x100,'\x01');
    }
    if (uVar8 != 0) {
      iVar4 = 0xc4;
      uVar10 = uStack_58;
      piVar7 = (int *)FUN_00404120(&pvStack_30,uStack_20,iStack_1c + 0xf);
      FUN_00404490(param_2,piVar7,iVar4,uVar10);
      uStack_58 = uStack_20 + 0xb7;
      iStack_54 = iStack_1c + 2;
      pvStack_30 = (void *)0x0;
      uStack_40 = *(uint *)(aiStack_48[0] + 0x72c4 + uVar8 * 0x4c);
      iStack_2c = 0;
      piVar7 = (int *)(aiStack_48[0] + 0x72b0 + uVar8 * 0x4c);
      iStack_3c = piVar7[6];
      piVar3 = (int *)FUN_00404180(auStack_10,(int *)&uStack_58,(int *)&uStack_40);
      FUN_0044ee60(param_2,*piVar3,piVar3[1],piVar3[2],piVar3[3],piVar7,(int)pvStack_30,iStack_2c);
    }
  }
  else {
    uVar9 = iStack_1c + 10;
    uStack_38 = uStack_20 + 0x28;
    uVar10 = uStack_20 + 0xbc;
    uStack_40 = uStack_38;
    if ((int)uVar10 <= (int)uStack_38) {
      uStack_40 = uVar10;
    }
    if ((int)uStack_38 <= (int)uVar10) {
      uStack_38 = uVar10;
    }
    uVar10 = iStack_1c + 0x1d;
    uVar12 = uVar9;
    if ((int)uVar10 <= (int)uVar9) {
      uVar12 = uVar10;
    }
    if ((int)uVar9 <= (int)uVar10) {
      uVar9 = uVar10;
    }
    pbVar1 = (byte *)(*piStack_5c + 0xc + iVar4);
    if ((*(uint *)((int)param_2 + 0x228) >> 3 & 1) == 0) {
      FUN_00452b90(param_2,pbVar1,uStack_40,uVar12,uStack_38,uVar9,0x100);
    }
    else {
      FUN_00452f90(param_2,pbVar1,uStack_40,uVar12,uStack_38,uVar9,0x100,'\x01');
    }
    if (uVar8 != 0) {
      iVar11 = 2;
      iVar4 = 0x88;
      uVar10 = uStack_58;
      piVar7 = (int *)FUN_00404120(&uStack_40,uStack_20 + 0x28,iStack_1c + 0x1b);
      FUN_00404590(param_2,piVar7,iVar4,iVar11,uVar10);
      uStack_58 = uStack_20 + 0xb0;
      iStack_54 = iStack_1c + 0x12;
      puVar13 = &uStack_40;
      uVar15 = 0x100;
      piVar7 = (int *)(aiStack_48[0] + 0x72b0 + uVar8 * 0x4c);
      uStack_40 = 0;
      iStack_3c = 0;
      piVar3 = (int *)FUN_00404470(piVar7,aiStack_48);
      piVar3 = (int *)FUN_00404180(auStack_10,(int *)&uStack_58,piVar3);
      FUN_0040f640(param_2,piVar3,piVar7,(int *)puVar13,uVar15);
    }
    pvVar5 = pvStack_30;
    cVar2 = FUN_004589b0(pvStack_30,0xffffffff);
    if (cVar2 != '\0') {
      piVar7 = (int *)FUN_00458c90(pvVar5,0xffffffff);
      ppvVar14 = &pvStack_30;
      uVar15 = 0x100;
      pvStack_30 = (void *)0x0;
      iStack_2c = 0;
      piVar3 = (int *)FUN_00404470(piVar7,&uStack_40);
      piVar3 = (int *)FUN_00404180(auStack_10,(int *)&uStack_20,piVar3);
      FUN_0040f640(param_2,piVar3,piVar7,(int *)ppvVar14,uVar15);
      FUN_0044f830(param_2,0,0,0x20,0x20,0x40,0xc0);
      return;
    }
  }
  return;
}


