// FUN_00402130  entry=00402130  size=2039 bytes

void __thiscall FUN_00402130(void *param_1,byte *param_2)

{
  void *this;
  char cVar1;
  uint *puVar2;
  int *piVar3;
  int *piVar4;
  undefined4 *puVar5;
  uint uVar6;
  uint extraout_ECX;
  uint extraout_ECX_00;
  uint extraout_ECX_01;
  uint extraout_ECX_02;
  uint extraout_ECX_03;
  uint extraout_ECX_04;
  uint extraout_ECX_05;
  uint extraout_ECX_06;
  uint extraout_ECX_07;
  uint extraout_ECX_08;
  uint extraout_ECX_09;
  uint extraout_ECX_10;
  uint extraout_ECX_11;
  uint extraout_ECX_12;
  uint extraout_ECX_13;
  uint extraout_ECX_14;
  uint extraout_ECX_15;
  uint extraout_ECX_16;
  uint extraout_ECX_17;
  uint extraout_ECX_18;
  uint extraout_ECX_19;
  uint extraout_ECX_20;
  uint extraout_ECX_21;
  int iVar7;
  int iVar8;
  uint uVar9;
  uint uVar10;
  int iVar11;
  uint uVar12;
  undefined4 uStack_4c;
  int iStack_48;
  int iStack_44;
  uint uStack_40;
  undefined4 uStack_3c;
  int aiStack_38 [2];
  int iStack_30;
  uint uStack_2c;
  int iStack_28;
  int iStack_24;
  int iStack_20;
  int iStack_1c;
  int iStack_18;
  int iStack_14;
  undefined1 auStack_10 [16];
  
  FUN_00404230((void *)((int)param_1 + 0x78),&iStack_20,(void *)((int)param_1 + 0x78));
  uStack_3c = *(undefined4 *)((int)param_1 + 0x5c);
  iStack_48 = 0;
  iStack_44 = 0;
  uVar10 = 0x100;
  uVar9 = 0xa0;
  uStack_40 = 0x50;
  CRect::CRect((CRect *)&iStack_30,iStack_20 + 3,iStack_1c + 3,iStack_18 + -3,iStack_14 + -3);
  this = param_2;
  FUN_0044f830(param_2,iStack_30,uStack_2c,iStack_28,iStack_24,0x40,0xc0);
  uVar12 = *(uint *)((int)param_1 + 0xac);
  if ((uVar12 & 0x80) == 0) {
    uVar6 = *(uint *)((int)param_1 + 0x3f4) & 2;
    if ((uVar6 == 0) || ((uVar12 & 0x400000) == 0)) {
      if ((uVar6 != 0) && ((uVar12 & 0x200000) != 0)) {
        uStack_3c = *(undefined4 *)((int)param_1 + 0x414);
      }
    }
    else {
      puVar2 = (uint *)FUN_00404450((int)param_1);
      uVar12 = *puVar2;
      uVar6 = 2;
      piVar3 = (int *)FUN_00404200(&iStack_20,&iStack_30,1);
      FUN_00404690(this,piVar3,uVar6,uVar12);
      uVar6 = extraout_ECX_00;
    }
  }
  else {
    uVar10 = 0x80;
    *(undefined2 *)((int)param_1 + 0x388) = 0x80;
    uVar6 = extraout_ECX;
  }
  if ((*(byte *)((int)param_1 + 0x3f4) & 1) != 0) {
    uVar9 = 0x50;
    iStack_48 = 2;
    iStack_44 = 2;
    uStack_40 = 0xa0;
  }
  uVar12 = uVar10;
  FUN_004042d0(&stack0xffffff9c,0);
  piVar3 = (int *)FUN_00404200(&iStack_20,&iStack_30,3);
  FUN_00404bf0(this,piVar3,uVar6,uVar12);
  uStack_4c = *(undefined4 *)((int)param_1 + 0x60);
  param_2 = (byte *)0xffffff;
  FUN_004042f0(&uStack_4c,(undefined1 *)aiStack_38,(byte *)&param_2,0xbe);
  uVar12 = extraout_ECX_01;
  uVar6 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,uVar9);
  iVar8 = iStack_18 + -8;
  piVar3 = (int *)FUN_00404120(aiStack_38,iStack_20 + 4,iStack_1c + 4);
  FUN_00404880(this,piVar3,iVar8,uVar12,uVar6);
  uVar12 = extraout_ECX_02;
  uVar6 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,uVar9);
  iVar8 = iStack_18 + -9;
  piVar3 = (int *)FUN_00404120(aiStack_38,iStack_20 + 4,iStack_1c + 5);
  FUN_00404880(this,piVar3,iVar8,uVar12,uVar6);
  uVar12 = extraout_ECX_03;
  uVar6 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,uVar9);
  piVar3 = (int *)FUN_00404120(aiStack_38,2,3);
  piVar4 = (int *)FUN_00404120(&iStack_30,iStack_20 + 4,iStack_1c + 6);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar6);
  uVar6 = uVar10;
  puVar5 = (undefined4 *)FUN_00404460((int)param_1);
  uVar12 = extraout_ECX_04;
  FUN_004042e0(&stack0xffffff9c,puVar5);
  piVar3 = (int *)FUN_00404120(&iStack_30,2,0xd);
  piVar4 = (int *)FUN_00404120(aiStack_38,iStack_20 + 4,iStack_1c + 9);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar6);
  uVar12 = extraout_ECX_05;
  uVar6 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,uVar9);
  iVar8 = 5;
  piVar3 = (int *)FUN_00404120(&iStack_30,iStack_20 + 4,iStack_1c + 0x16);
  FUN_00404930(this,piVar3,iVar8,uVar12,uVar6);
  uVar12 = extraout_ECX_06;
  uVar6 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,uVar9);
  iVar8 = 4;
  piVar3 = (int *)FUN_00404120(&iStack_30,iStack_20 + 5,iStack_1c + 0x16);
  FUN_00404930(this,piVar3,iVar8,uVar12,uVar6);
  uVar12 = uStack_40;
  uVar9 = extraout_ECX_07;
  uVar6 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,uStack_40);
  iVar8 = iStack_18 + -10;
  piVar3 = (int *)FUN_00404120(&iStack_30,iStack_20 + 5,iStack_1c + 0x1a);
  FUN_00404880(this,piVar3,iVar8,uVar9,uVar6);
  uVar9 = extraout_ECX_08;
  uVar6 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,uVar12);
  iVar8 = iStack_18 + -0xb;
  piVar3 = (int *)FUN_00404120(&iStack_30,iStack_20 + 6,iStack_1c + 0x19);
  FUN_00404880(this,piVar3,iVar8,uVar9,uVar6);
  uVar9 = extraout_ECX_09;
  uVar6 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,uVar12);
  iVar8 = 0x16;
  piVar3 = (int *)FUN_00404120(&iStack_30,iStack_20 + -5 + iStack_18,iStack_1c + 5);
  FUN_00404930(this,piVar3,iVar8,uVar9,uVar6);
  uVar9 = extraout_ECX_10;
  uVar6 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,uVar12);
  iVar8 = 0x15;
  piVar3 = (int *)FUN_00404120(&iStack_30,iStack_20 + -6 + iStack_18,iStack_1c + 6);
  FUN_00404930(this,piVar3,iVar8,uVar9,uVar6);
  uVar9 = uVar10;
  puVar5 = (undefined4 *)FUN_00404460((int)param_1);
  uVar12 = extraout_ECX_11;
  FUN_004042e0(&stack0xffffff9c,puVar5);
  piVar3 = (int *)FUN_00404120(&iStack_30,iStack_18 + -0xc,0x13);
  piVar4 = (int *)FUN_00404120(aiStack_38,iStack_20 + 6,iStack_1c + 6);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar9);
  uVar12 = extraout_ECX_12;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  piVar3 = (int *)FUN_00404120(&iStack_30,10,0xd);
  piVar4 = (int *)FUN_00404120(aiStack_38,iStack_20 + 6,iStack_1c + 9);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar9);
  uVar12 = extraout_ECX_13;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  piVar3 = (int *)FUN_00404120(&iStack_30,7,0xd);
  piVar4 = (int *)FUN_00404120(aiStack_38,iStack_20 + 0x11,iStack_1c + 9);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar9);
  uVar12 = extraout_ECX_14;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  piVar3 = (int *)FUN_00404120(&iStack_30,4,0xd);
  piVar4 = (int *)FUN_00404120(aiStack_38,iStack_20 + 0x1a,iStack_1c + 9);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar9);
  uVar12 = extraout_ECX_15;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  piVar3 = (int *)FUN_00404120(&iStack_30,2,0xd);
  piVar4 = (int *)FUN_00404120(aiStack_38,iStack_20 + 0x21,iStack_1c + 9);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar9);
  uVar12 = extraout_ECX_16;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  iVar8 = 0xd;
  piVar3 = (int *)FUN_00404120(&iStack_30,iStack_20 + 0x27,iStack_1c + 9);
  FUN_00404930(this,piVar3,iVar8,uVar12,uVar9);
  iVar8 = iStack_18;
  uVar12 = extraout_ECX_17;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  iVar11 = 0xd;
  piVar3 = (int *)FUN_00404120(&iStack_30,iVar8 + -0x28,iStack_1c + 9);
  FUN_00404930(this,piVar3,iVar11,uVar12,uVar9);
  uVar12 = extraout_ECX_18;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  piVar3 = (int *)FUN_00404120(&iStack_30,2,0xd);
  piVar4 = (int *)FUN_00404120(aiStack_38,iVar8 + -0x23,iStack_1c + 9);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar9);
  uVar12 = extraout_ECX_19;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  piVar3 = (int *)FUN_00404120(&iStack_30,4,0xd);
  piVar4 = (int *)FUN_00404120(aiStack_38,iVar8 + -0x1e,iStack_1c + 9);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar9);
  uVar12 = extraout_ECX_20;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  piVar3 = (int *)FUN_00404120(&iStack_30,7,0xd);
  piVar4 = (int *)FUN_00404120(aiStack_38,iVar8 + -0x18,iStack_1c + 9);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar9);
  uVar12 = extraout_ECX_21;
  uVar9 = uVar10;
  FUN_00404390(&uStack_4c,(uint *)&stack0xffffff9c,100);
  piVar3 = (int *)FUN_00404120(&iStack_30,10,0xd);
  piVar4 = (int *)FUN_00404120(aiStack_38,iVar8 + -0x10,iStack_1c + 9);
  piVar3 = (int *)FUN_00404180(auStack_10,piVar4,piVar3);
  FUN_00404b30(this,piVar3,uVar12,uVar9);
  cVar1 = FUN_004589b0(param_1,0xffffffff);
  if (cVar1 != '\0') {
    iVar8 = FUN_00458c90(param_1,0xffffffff);
    aiStack_38[0] = iStack_48 + 5 + iStack_20;
    iVar8 = (iStack_14 - *(int *)(iVar8 + 0x18)) / 2 + iStack_44;
    piVar3 = (int *)FUN_00458c90(param_1,0xffffffff);
    iVar11 = piVar3[5] + aiStack_38[0];
    iStack_30 = aiStack_38[0];
    if (iVar11 <= aiStack_38[0]) {
      iStack_30 = iVar11;
    }
    iStack_28 = aiStack_38[0];
    if (aiStack_38[0] <= iVar11) {
      iStack_28 = iVar11;
    }
    iVar7 = piVar3[6] + iVar8;
    iVar11 = iVar8;
    if (iVar7 <= iVar8) {
      iVar11 = iVar7;
    }
    if (iVar8 <= iVar7) {
      iVar8 = iVar7;
    }
    FUN_0044f2b0(this,0x10,'\0',0,iStack_30,iVar11,iStack_28,iVar8,piVar3,(int *)0x0,0,0,uVar10);
  }
  FUN_00452b40(this,uStack_3c);
  param_2 = *(byte **)((int)param_1 + 0xb8);
  uVar12 = iStack_48 + iStack_20 + 3 + *(int *)((int)param_1 + 0x3fc);
  uVar9 = iStack_44 + 3 + iStack_1c;
  uVar6 = (iStack_18 - *(int *)((int)param_1 + 0x3fc)) - 3;
  if ((*(uint *)((int)this + 0x228) >> 3 & 1) != 0) {
    FUN_00452f90(this,param_2,uVar12,uVar9,uVar6,iStack_14 - 3U,uVar10,'\x01');
    return;
  }
  FUN_00452b90(this,param_2,uVar12,uVar9,uVar6,iStack_14 - 3U,uVar10);
  return;
}


