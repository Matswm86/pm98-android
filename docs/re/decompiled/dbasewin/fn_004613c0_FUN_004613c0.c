// FUN_004613c0  entry=004613c0  size=2560 bytes

/* WARNING: Removing unreachable block (ram,0x0046150a) */

void __thiscall FUN_004613c0(void *this,int *param_1)

{
  undefined2 uVar1;
  bool bVar2;
  ushort uVar3;
  int iVar4;
  undefined4 *puVar5;
  int *piVar6;
  byte *pbVar7;
  void *this_00;
  int *piVar8;
  int *piVar9;
  uint extraout_ECX;
  uint extraout_ECX_00;
  uint uVar10;
  undefined4 extraout_ECX_01;
  uint extraout_ECX_02;
  undefined4 extraout_ECX_03;
  int *piVar11;
  uint uVar12;
  undefined1 uVar13;
  undefined1 **ppuVar14;
  undefined1 uVar15;
  int iVar16;
  int iVar17;
  char cVar18;
  undefined4 uVar19;
  undefined4 uVar20;
  uint local_2ec;
  uint local_2e8;
  uint local_2e4;
  uint local_2e0;
  uint local_2dc;
  uint local_2d8;
  undefined1 *local_2d4;
  uint local_2d0;
  int local_2cc;
  int local_2c8;
  uint local_2c4;
  undefined4 local_2c0;
  int *local_2bc;
  undefined4 local_2b8;
  int local_2b4;
  int local_2b0;
  int *local_2ac;
  uint local_2a8;
  int local_2a4;
  uint local_298;
  uint local_294;
  int local_290;
  int local_284 [141];
  HGLOBAL local_50;
  undefined4 local_4c;
  HGLOBAL local_14;
  undefined4 local_10;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00482eee;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_00451be0(local_284);
  piVar11 = (int *)((int)this + 0x78);
  local_4 = 0;
  local_2ac = piVar11;
  FUN_00404230(piVar11,(int *)&local_2ec,piVar11);
  uVar10 = *(uint *)((int)this + 0xac);
  if ((uVar10 & 0x10) != 0) {
    iVar4 = FUN_0045b4a0(*(int *)((int)this + 0x4c));
    uVar10 = *(uint *)(iVar4 + 0xac);
  }
  local_2dc = (uint)(~(byte)(uVar10 >> 7) & 1);
  uVar10 = *(uint *)((int)this + 0x3f4);
  local_2a8 = uVar10 & 2;
  if ((((uVar10 & 1) == 0) || ((uVar10 >> 4 & 1) != 0)) &&
     (((uVar10 & 1) != 0 || ((uVar10 >> 4 & 1) == 0)))) {
    local_2c4 = 0;
    bVar2 = false;
  }
  else {
    bVar2 = true;
    local_2c4 = 1;
  }
  local_294 = 0;
  local_2d8 = 0;
  local_2bc = (int *)0x0;
  if ((local_2a8 == 0) ||
     (puVar5 = (undefined4 *)((int)this + 0x410), (*(uint *)((int)this + 0xac) & 0x200000) == 0)) {
    puVar5 = (undefined4 *)((int)this + 0x60);
  }
  local_2c0 = *puVar5;
  if (local_2dc == 0) {
    local_294 = 4;
    local_2d8 = -(uint)bVar2 & 2;
    local_2bc = (int *)(-(uint)bVar2 & 3);
  }
  else if (local_2a8 == 0) {
    if (bVar2) {
      local_2d8 = 1;
      local_294 = 2;
    }
  }
  else {
    local_2bc = (int *)0x1;
    local_294 = (-(uint)bVar2 & 2) + 1;
    local_2d8 = bVar2 + 1;
  }
  uVar12 = local_294;
  uVar10 = *(uint *)((int)this + 0xac);
  uVar3 = *(ushort *)((int)this + local_294 * 2 + 0x388);
  local_298 = (uint)uVar3;
  if (((uVar10 & 0x800) != 0) && (uVar3 != 0x100)) {
    cVar18 = '\x01';
    piVar6 = (int *)FUN_00461de0(param_1,(int *)&local_2d4);
    FUN_00452910(local_284,param_1,piVar6,cVar18);
    uVar10 = extraout_ECX;
  }
  if ((*(uint *)((int)this + 0xac) & 0x80800) == 0) {
    uVar19 = 0x100;
    FUN_004042e0(&stack0xfffffcfc,param_1 + 0x80);
    FUN_00404b60(param_1,(int *)&local_2ec,uVar10,uVar19);
    uVar10 = extraout_ECX_00;
  }
  if ((*(uint *)((int)this + 0xac) & 0x400000) != 0) {
    local_2ec = local_2ec + 2;
    local_2e8 = local_2e8 + 2;
    local_2e4 = local_2e4 - 2;
    uVar10 = local_2e0 - 2;
    local_2e0 = uVar10;
  }
  if ((*(uint *)((int)this + 0xac) & 0x80000) != 0) {
    uVar19 = 0x100;
    local_2d4 = &stack0xfffffcfc;
    FUN_004042d0(&stack0xfffffcfc,0);
    FUN_00404bf0(param_1,(int *)&local_2ec,uVar10,uVar19);
    local_2ec = local_2ec + 1;
    local_2e8 = local_2e8 + 1;
    local_2e4 = local_2e4 - 1;
    local_2e0 = local_2e0 - 1;
    local_2d4 = &stack0xfffffd00;
    if (local_2c4 == 0) {
      FUN_00461e20(param_1,(int *)&local_2ec,*(uint *)((int)this + 0x40c));
      local_2d4 = &stack0xfffffd00;
      FUN_0043d2d0(param_1,(int *)&local_2ec,*(uint *)((int)this + 0x400));
      local_2ec = local_2ec + 1;
      local_2e8 = local_2e8 + 1;
      local_2e4 = local_2e4 + -1;
      local_2e0 = local_2e0 + -1;
      local_2d4 = &stack0xfffffd00;
      FUN_00461e20(param_1,(int *)&local_2ec,*(uint *)((int)this + 0x408));
      local_2d4 = &stack0xfffffd00;
      FUN_0043d2d0(param_1,(int *)&local_2ec,*(uint *)((int)this + 0x404));
      local_2e4 = local_2e4 - 1;
      local_2e0 = local_2e0 - 1;
    }
    else {
      local_2d4 = &stack0xfffffd00;
      FUN_00461e20(param_1,(int *)&local_2ec,*(uint *)((int)this + 0x400));
      local_2d4 = &stack0xfffffd00;
      FUN_0043d2d0(param_1,(int *)&local_2ec,*(uint *)((int)this + 0x404));
      local_2ec = local_2ec + 1;
      local_2e8 = local_2e8 + 1;
      local_2e4 = local_2e4 - 1;
      local_2e0 = local_2e0 - 1;
      local_2d4 = &stack0xfffffd00;
      FUN_00461e20(param_1,(int *)&local_2ec,*(uint *)((int)this + 0x404));
    }
    local_2e8 = local_2e8 + 1;
    local_2ec = local_2ec + 1;
    uVar20 = 0x100;
    pbVar7 = (byte *)FUN_00461dd0((int)&local_2c0);
    uVar10 = (uint)*pbVar7 << 1;
    uVar15 = (undefined1)(uVar10 / 3);
    local_2d4 = &stack0xfffffcfc;
    pbVar7 = (byte *)FUN_00461dc0((int)&local_2c0);
    uVar13 = (undefined1)(((uint)*pbVar7 << 1) / 3);
    pbVar7 = (byte *)FUN_004076c0(&local_2c0);
    FUN_004042b0(&stack0xfffffcfc,(char)(((uint)*pbVar7 << 1) / 3),uVar13,uVar15);
    local_2d4 = &stack0xfffffcf8;
    uVar19 = extraout_ECX_01;
    FUN_004042e0(&stack0xfffffcf8,&local_2c0);
    FUN_0044f630(param_1,(int *)&local_2ec,uVar19,uVar10,uVar20);
    uVar10 = extraout_ECX_02;
    uVar12 = local_294;
    if (local_2c4 != 0) {
      uVar10 = local_2ec + 1;
      local_2e8 = local_2e8 + 1;
      local_2ec = uVar10;
    }
  }
  if (((local_2dc != 0) && (local_2a8 != 0)) && ((*(uint *)((int)this + 0xac) & 0x400000) != 0)) {
    uVar19 = 0x100;
    local_2d4 = &stack0xfffffcfc;
    FUN_004042e0(&stack0xfffffcfc,(undefined4 *)((int)this + 0x410));
    piVar6 = (int *)FUN_00445320(this,&local_2d4);
    FUN_00404bf0(param_1,piVar6,uVar10,uVar19);
    uVar20 = 0x100;
    local_2d4 = &stack0xfffffcfc;
    uVar19 = extraout_ECX_03;
    FUN_004042e0(&stack0xfffffcfc,(undefined4 *)((int)this + 0x410));
    ppuVar14 = &local_2d4;
    iVar4 = 1;
    this_00 = (void *)FUN_00445320(this,&local_2a8);
    piVar6 = (int *)FUN_00404200(this_00,(int *)ppuVar14,iVar4);
    FUN_00404bf0(param_1,piVar6,uVar19,uVar20);
  }
  iVar4 = FUN_00458e90(this,uVar12,local_2d8,(uint)local_2bc,0);
  if (iVar4 != 0) {
    piVar11 = *(int **)(iVar4 + 0x80);
    piVar6 = *(int **)(iVar4 + 0x88);
    local_2d0 = piVar11[6];
    iVar4 = (int)((local_2e0 - local_2e8) - local_2d0) / 2;
    local_2bc = piVar6;
    if ((*(uint *)((int)this + 0xac) & 0x800000) == 0) {
      if ((*(uint *)((int)this + 0xac) & 0x1000000) == 0) {
        uVar19 = 0x100;
        iVar16 = (int)(local_2e4 + local_2ec) / 2;
        local_2a8 = iVar16 - piVar11[5] / 2;
        local_2a4 = (int)(local_2e8 + local_2e0) / 2 - (int)local_2d0 / 2;
        iVar4 = *(int *)((int)this + 0x74);
        uVar1 = *(undefined2 *)
                 (*(int *)((int)this + *(int *)((int)this + 0x70) * 8 + 0x360) + 0x90 + iVar4 * 0x94
                 );
        local_2dc._1_3_ = (undefined3)((uint)iVar16 >> 8);
        local_2dc = CONCAT31(local_2dc._1_3_,*(undefined1 *)((int)this + 0x66));
        local_2d4 = (undefined1 *)piVar11[5];
        local_2d8 = CONCAT31(local_2d8._1_3_,*(undefined1 *)((int)this + 100));
        iVar17 = 0;
        iVar16 = 0;
        piVar9 = (int *)FUN_00404180(&local_2bc,(int *)&local_2a8,(int *)&local_2d4);
        FUN_0044f2b0(param_1,CONCAT22((short)((uint)(iVar4 * 9) >> 0x10),uVar1),(char)local_2d8,
                     (byte)local_2dc,*piVar9,piVar9[1],piVar9[2],piVar9[3],piVar11,piVar6,iVar16,
                     iVar17,uVar19);
        piVar11 = local_2ac;
      }
      else {
        local_294 = (local_2e4 - iVar4) - piVar11[5];
        uVar19 = 0x100;
        local_290 = iVar4 + local_2e0;
        local_2a8 = CONCAT31(local_2a8._1_3_,*(undefined1 *)((int)this + 100));
        local_2c4 = CONCAT22(local_2c4._2_2_,
                             *(undefined2 *)
                              (*(int *)((int)this + *(int *)((int)this + 0x70) * 8 + 0x360) + 0x90 +
                              *(int *)((int)this + 0x74) * 0x94));
        local_2d4 = (undefined1 *)piVar11[5];
        local_2d8 = CONCAT31(local_2d8._1_3_,*(undefined1 *)((int)this + 0x66));
        iVar17 = 0;
        iVar16 = 0;
        piVar9 = piVar11;
        local_2dc = local_2d0;
        piVar8 = (int *)FUN_00404180(&local_2bc,(int *)&local_294,(int *)&local_2d4);
        FUN_0044f2b0(param_1,local_2c4,(char)local_2a8,(byte)local_2d8,*piVar8,piVar8[1],piVar8[2],
                     piVar8[3],piVar9,piVar6,iVar16,iVar17,uVar19);
        if (((*(uint *)((int)this + 0xac) & 0x80000) == 0) ||
           ((*(byte *)((int)this + 0x3f4) & 0xd) == 0)) {
          iVar16 = 0;
        }
        else {
          iVar16 = 1;
        }
        local_2e4 = local_2e4 + ((iVar16 - iVar4) * 2 - piVar11[5]);
        piVar11 = local_2ac;
      }
    }
    else {
      uVar19 = 0x100;
      local_2d4 = (undefined1 *)(iVar4 + local_2ec);
      local_2d8 = CONCAT31(local_2d8._1_3_,*(undefined1 *)((int)this + 100));
      local_2dc._1_3_ = (undefined3)(local_2d0 >> 8);
      local_2dc = CONCAT31(local_2dc._1_3_,*(undefined1 *)((int)this + 0x66));
      local_2a8 = CONCAT22(local_2a8._2_2_,
                           *(undefined2 *)
                            (*(int *)((int)this + *(int *)((int)this + 0x70) * 8 + 0x360) + 0x90 +
                            *(int *)((int)this + 0x74) * 0x94));
      iVar17 = 0;
      iVar16 = 0;
      piVar9 = piVar11;
      local_2d0 = iVar4 + local_2e8;
      piVar8 = (int *)FUN_00404470(piVar11,&local_2bc);
      piVar8 = (int *)FUN_00404180(&local_294,(int *)&local_2d4,piVar8);
      FUN_0044f2b0(param_1,local_2a8,(char)local_2d8,(byte)local_2dc,*piVar8,piVar8[1],piVar8[2],
                   piVar8[3],piVar9,piVar6,iVar16,iVar17,uVar19);
      if (((*(uint *)((int)this + 0xac) & 0x80000) == 0) ||
         ((*(byte *)((int)this + 0x3f4) & 0xd) == 0)) {
        iVar16 = 0;
      }
      else {
        iVar16 = 1;
      }
      local_2ec = local_2ec + piVar11[5] + (iVar4 + iVar16) * 2;
      piVar11 = local_2ac;
    }
  }
  if (*(int *)(*(int *)((int)this + 0xb8) + -8) != 0) {
    if (((*(byte *)((int)this + 0x3f4) & 2) != 0) && ((*(uint *)((int)this + 0xac) & 0x200000) != 0)
       ) {
      local_2d4 = &stack0xfffffd00;
      FUN_00452b40(param_1,*(undefined4 *)((int)this + 0x414));
    }
    local_2ec = local_2ec + *(int *)((int)this + 0x3fc);
    local_2e4 = local_2e4 - *(int *)((int)this + 0x3fc);
    if (((uint)param_1[0x8a] >> 3 & 1) == 0) {
      FUN_00452b90(param_1,*(byte **)((int)this + 0xb8),local_2ec,local_2e8,local_2e4,local_2e0,
                   0x100);
    }
    else {
      FUN_00452f90(param_1,*(byte **)((int)this + 0xb8),local_2ec,local_2e8,local_2e4,local_2e0,
                   0x100,'\x01');
    }
  }
  if ((short)local_298 != 0x100) {
    if ((*(uint *)((int)this + 0xac) & 0x800) == 0) {
      local_2d4 = &stack0xfffffd00;
      FUN_00445320(this,&local_2d4);
      FUN_00461f00(param_1);
    }
    else {
      local_2b4 = piVar11[2] - *piVar11;
      local_2b0 = piVar11[3] - piVar11[1];
      local_2dc = piVar11[1];
      local_2d0 = 0;
      local_2cc = piVar11[2] - *piVar11;
      local_2bc = (int *)0x0;
      local_2c8 = piVar11[3] - local_2dc;
      uVar3 = 0x100 - (short)local_298;
      local_2b8 = 0;
      local_2d4 = (undefined1 *)0x0;
      if (uVar3 < 0x100) {
        FUN_0045bbb0(param_1,(int *)&local_2d4,uVar3,local_284,(int *)&local_2bc);
      }
      else {
        FUN_0044ee60(param_1,0,0,local_2cc,local_2c8,local_284,0,0);
      }
    }
  }
  local_4 = 2;
  if (local_14 != (HGLOBAL)0x0) {
    FUN_0044faf0(local_14);
    local_14 = (HGLOBAL)0x0;
  }
  local_10 = 0;
  local_4 = CONCAT31(local_4._1_3_,1);
  if (local_50 != (HGLOBAL)0x0) {
    FUN_0044faf0(local_50);
    local_50 = (HGLOBAL)0x0;
  }
  local_4c = 0;
  local_4 = 0xffffffff;
  thunk_FUN_0044e5d0(local_284);
  ExceptionList = local_c;
  return;
}


