// FUN_00457b10  entry=00457b10  size=1426 bytes

/* WARNING: Removing unreachable block (ram,0x00457b30) */

void __thiscall FUN_00457b10(void *this,void *param_1)

{
  int *piVar1;
  int iVar2;
  void *pvVar3;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  uint extraout_ECX_02;
  uint extraout_ECX_03;
  uint extraout_ECX_04;
  uint extraout_ECX_05;
  int iVar4;
  int iVar5;
  uint uVar6;
  uint uVar7;
  int iVar8;
  bool bVar9;
  CRect *pCVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  int local_78;
  undefined4 local_74;
  void *local_70;
  undefined4 local_6c;
  int *local_68;
  int *local_64;
  CRect local_60 [16];
  int local_50;
  uint local_4c;
  uint local_48;
  uint local_44;
  uint local_40;
  uint local_3c;
  uint local_38;
  uint local_34;
  int local_30;
  uint local_2c;
  int local_28;
  uint local_24;
  uint local_1c;
  int local_18;
  uint local_14;
  CRect local_10 [16];
  
  uVar6 = *(uint *)((int)this + 0xac) >> 7 & 1;
  uVar7 = uVar6 * 4;
  local_6c = CONCAT22(local_6c._2_2_,*(undefined2 *)((int)this + uVar6 * 8 + 0x388));
  local_70 = this;
  FUN_00404230((void *)((int)this + 0x78),&local_50,(void *)((int)this + 0x78));
  iVar5 = local_50;
  local_18 = local_48;
  local_1c = local_4c;
  local_14 = local_44;
  local_68 = (int *)FUN_00458cd0(this,uVar7,0,0xffffffff,0xffffffff);
  local_64 = (int *)FUN_00458dd0(this,uVar7,0,0xffffffff,0xffffffff);
  uVar6 = *(uint *)((int)this + 0xac);
  if ((uVar6 & 1) == 0) {
    uVar7 = uVar6 & 0x4000;
    if ((uVar7 == 0) || ((uVar6 & 0x800) == 0)) {
      if (((uVar7 != 0) || ((uVar6 & 0x800) != 0)) &&
         ((*(int *)((int)this + 0x44) != 0 || (this != DAT_00502018)))) goto LAB_00457fbc;
      uVar12 = 0x100;
      FUN_004042e0(&stack0xffffff70,(undefined4 *)((int)param_1 + 0x200));
    }
    else {
      uVar12 = local_6c;
      FUN_004042e0(&stack0xffffff70,(undefined4 *)((int)param_1 + 0x200));
    }
    FUN_00404b60(param_1,&local_50,uVar7,uVar12);
  }
  else {
    local_48 = local_48 - 6;
    local_28 = local_50 + 0x1c;
    local_44 = local_44 - 6;
    local_30 = local_50;
    if (local_28 <= local_50) {
      local_30 = local_28;
    }
    if (local_28 < local_50) {
      local_28 = local_50;
    }
    uVar6 = local_4c + 0x1c;
    local_2c = local_4c;
    if ((int)uVar6 <= (int)local_4c) {
      local_2c = uVar6;
    }
    local_24 = local_4c;
    if ((int)local_4c <= (int)uVar6) {
      local_24 = uVar6;
    }
    local_38 = local_50 + 0x1a;
    local_40 = local_48;
    if ((int)local_38 <= (int)local_48) {
      local_40 = local_38;
    }
    if ((int)local_38 < (int)local_48) {
      local_38 = local_48;
    }
    local_3c = local_4c;
    if ((int)uVar6 <= (int)local_4c) {
      local_3c = uVar6;
    }
    local_34 = local_4c;
    if ((int)local_4c <= (int)uVar6) {
      local_34 = uVar6;
    }
    iVar5 = 5;
    uVar6 = local_48;
    uVar7 = 0x100;
    do {
      iVar4 = (int)uVar7 / 10;
      FUN_004042d0(&stack0xffffff70,0);
      piVar1 = (int *)CRect::CRect(local_60,local_50 + 6,local_4c + 6,iVar5 + local_48,
                                   iVar5 + local_44);
      FUN_0043d1f0(param_1,piVar1,uVar6,iVar4);
      iVar5 = iVar5 + -1;
      bVar9 = uVar7 != 0x600;
      uVar6 = uVar7;
      uVar7 = uVar7 + 0x100;
    } while (bVar9);
    FUN_00404690(param_1,&local_50,2,0);
    FUN_00404690(param_1,&local_30,2,0);
    uVar11 = 0x100;
    uVar12 = extraout_ECX;
    FUN_004042b0(&stack0xffffff70,0xff,0xc0,0);
    piVar1 = (int *)FUN_0045ae70(&local_30,2);
    FUN_00404b30(param_1,piVar1,uVar12,uVar11);
    FUN_00404690(param_1,(int *)&local_40,2,0);
    uVar11 = 0x100;
    uVar12 = extraout_ECX_00;
    FUN_004042b0(&stack0xffffff70,0x2a,0x3f,0xaa);
    piVar1 = (int *)FUN_0045ae70(&local_40,2);
    FUN_00404b30(param_1,piVar1,uVar12,uVar11);
    iVar4 = 1;
    iVar5 = (int)(local_38 - local_40) / 0x14;
    iVar8 = 0;
    local_78 = (int)(iVar5 + (iVar5 >> 0x1f & 7U)) >> 3;
    pvVar3 = local_70;
    uVar6 = local_38;
    if (local_78 < 2) {
      local_78 = 1;
    }
    for (; local_70 = pvVar3, 0 < iVar5; iVar5 = iVar5 - local_78) {
      uVar12 = 0x100;
      FUN_004042b0(&stack0xffffff70,0,0,0x80);
      piVar1 = (int *)CRect::CRect(local_60,iVar8 + local_40,local_3c + 5,iVar8 + iVar5 + local_40,
                                   local_34 - 5);
      FUN_00404b30(param_1,piVar1,uVar6,uVar12);
      uVar11 = 0x100;
      uVar12 = extraout_ECX_01;
      FUN_004042b0(&stack0xffffff70,0,0,0x80);
      piVar1 = (int *)CRect::CRect(local_10,(local_38 - iVar5) - iVar8,local_3c + 5,local_38 - iVar8
                                   ,local_34 - 5);
      FUN_00404b30(param_1,piVar1,uVar12,uVar11);
      iVar8 = iVar8 + iVar4 + iVar5;
      iVar4 = iVar4 + 1;
      pvVar3 = local_70;
      uVar6 = extraout_ECX_02;
    }
    if ((*(uint *)((int)param_1 + 0x228) >> 3 & 1) == 0) {
      FUN_00452b90(param_1,*(byte **)((int)pvVar3 + 0xb8),local_40,local_3c,local_38,local_34,0x100)
      ;
    }
    else {
      FUN_00452f90(param_1,*(byte **)((int)pvVar3 + 0xb8),local_40,local_3c,local_38,local_34,0x100,
                   '\x01');
    }
    uVar11 = 0x100;
    local_4c = local_4c + 0x1c;
    uVar12 = 2;
    local_50 = local_50 + 2;
    local_48 = local_48 - 2;
    local_44 = local_44 - 2;
    FUN_004042e0(&stack0xffffff70,(undefined4 *)((int)pvVar3 + 0x60));
    FUN_00404b30(param_1,&local_50,uVar12,uVar11);
    iVar5 = 0x100;
    iVar4 = 3;
    uVar6 = extraout_ECX_03;
    do {
      iVar8 = iVar5 / 7;
      FUN_004042d0(&stack0xffffff70,0);
      iVar2 = FUN_00404d70(&local_50);
      piVar1 = (int *)FUN_00404120(&local_78,0,iVar4);
      pCVar10 = local_60;
      pvVar3 = (void *)FUN_004076c0(&local_50);
      piVar1 = (int *)FUN_00404140(pvVar3,(int *)pCVar10,piVar1);
      FUN_00404880(param_1,piVar1,iVar2,uVar6,iVar8);
      iVar5 = iVar5 + 0x100;
      iVar4 = iVar4 + -1;
      uVar6 = extraout_ECX_04;
    } while (-1 < iVar4);
    local_1c = local_2c;
    local_18 = local_28;
    local_14 = local_24;
    iVar5 = local_30;
    this = local_70;
  }
LAB_00457fbc:
  piVar1 = local_68;
  uVar6 = 0;
  if (local_68 != (int *)0x0) {
    local_74 = 0;
    local_68 = (int *)CONCAT31(local_68._1_3_,*(byte *)((int)this + 0x66));
    local_70 = (void *)CONCAT31(local_70._1_3_,*(char *)((int)this + 100));
    iVar4 = piVar1[5] + iVar5;
    local_30 = iVar5;
    if (iVar4 <= iVar5) {
      local_30 = iVar4;
    }
    local_28 = iVar5;
    if (iVar5 <= iVar4) {
      local_28 = iVar4;
    }
    uVar7 = piVar1[6] + local_1c;
    uVar6 = local_1c;
    if ((int)uVar7 <= (int)local_1c) {
      uVar6 = uVar7;
    }
    if ((int)uVar7 < (int)local_1c) {
      uVar7 = local_1c;
    }
    FUN_0044f2b0(param_1,CONCAT22((short)((uint)(*(int *)((int)this + 0x74) * 9) >> 0x10),
                                  *(undefined2 *)
                                   (*(int *)((int)this + *(int *)((int)this + 0x70) * 8 + 0x360) +
                                    0x90 + *(int *)((int)this + 0x74) * 0x94)),
                 *(char *)((int)this + 100),*(byte *)((int)this + 0x66),local_30,uVar6,local_28,
                 uVar7,piVar1,local_64,0,0,local_6c);
    uVar6 = extraout_ECX_05;
  }
  if ((*(uint *)((int)this + 0xac) & 0x8000) != 0) {
    uVar12 = 0x100;
    FUN_004042e0(&stack0xffffff70,(undefined4 *)((int)param_1 + 0x1fc));
    FUN_00404c20(param_1,&local_50,uVar6,uVar12);
  }
  return;
}


