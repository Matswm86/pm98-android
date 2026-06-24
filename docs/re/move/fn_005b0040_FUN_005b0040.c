// FUN_005b0040  entry=005b0040  size=1171 bytes

void __fastcall FUN_005b0040(int param_1)

{
  int *piVar1;
  int iVar2;
  int iVar3;
  bool bVar4;
  char cVar5;
  short sVar6;
  undefined2 extraout_var;
  uint uVar7;
  int iVar8;
  uint uVar9;
  int iVar10;
  int *piVar11;
  int iVar12;
  undefined4 uVar13;
  uint uVar14;
  int local_60;
  undefined4 local_50;
  undefined4 local_4c;
  undefined1 local_3c [12];
  int local_30;
  int local_2c;
  int local_28;
  int local_24;
  int local_20;
  int local_1c;
  undefined1 local_c [12];
  
  iVar12 = *(int *)(param_1 + 400);
  piVar1 = (int *)(param_1 + 4);
  FUN_00590aa0(*piVar1 - *(int *)(iVar12 + 4),*(int *)(param_1 + 8) - *(int *)(iVar12 + 8),
               *(int *)(param_1 + 0xc) - *(int *)(iVar12 + 0xc));
  FUN_005ee0f0(0x10000,CONCAT22(extraout_var,*(undefined2 *)(*(int *)(param_1 + 400) + 0x34)));
  local_24 = *(int *)(*(int *)(param_1 + 400) + 0x20);
  local_20 = *(int *)(*(int *)(param_1 + 400) + 0x24);
  uVar7 = FUN_005ee500(local_3c);
  iVar12 = *(int *)(param_1 + 0x70);
  iVar2 = *(int *)(param_1 + 0x3ac);
  iVar3 = *(int *)(param_1 + 0x3a8);
  if ((*(int *)(param_1 + 700) != 0) &&
     (iVar10 = *(int *)(param_1 + 400), *(int *)(iVar10 + 0x4c) == param_1)) {
    if (0x16666 < *(int *)(iVar10 + 0xc)) goto LAB_005b04a6;
    cVar5 = FUN_005b04e0(piVar1);
    iVar8 = (-(uint)(cVar5 != '\0') & 0xfffb0000) + 0x60000;
    uVar9 = *(int *)(iVar10 + 4) - *piVar1;
    uVar14 = (int)uVar9 >> 0x1f;
    if ((((int)((uVar9 ^ uVar14) - uVar14) < iVar8) &&
        (uVar9 = *(int *)(iVar10 + 8) - *(int *)(param_1 + 8), uVar14 = (int)uVar9 >> 0x1f,
        (int)((uVar9 ^ uVar14) - uVar14) < iVar8)) &&
       (uVar9 = *(int *)(iVar10 + 0xc) - *(int *)(param_1 + 0xc), uVar14 = (int)uVar9 >> 0x1f,
       (int)((uVar9 ^ uVar14) - uVar14) < iVar8)) {
      bVar4 = true;
    }
    else {
      bVar4 = false;
    }
    if (!bVar4) goto LAB_005b04a6;
  }
  iVar10 = *(int *)(param_1 + 400);
  if (((*(int *)(iVar10 + 0x20) == 0) && (*(int *)(iVar10 + 0x24) == 0)) &&
     (*(int *)(iVar10 + 0x28) == 0)) {
    bVar4 = true;
  }
  else {
    bVar4 = false;
  }
  if (!bVar4) {
    iVar10 = (uVar7 ^ (int)uVar7 >> 0x1f) - ((int)uVar7 >> 0x1f);
    for (local_60 = 0; (0xccc < iVar10 && (local_60 < 0x12)); local_60 = local_60 + 1) {
      iVar10 = *(int *)(param_1 + 400);
      piVar11 = (int *)FUN_005ee170(local_c,uVar7);
      iVar8 = (*piVar1 - *piVar11) - *(int *)(iVar10 + 4);
      iVar10 = (*(int *)(param_1 + 8) - *(int *)(iVar10 + 8)) - piVar11[1];
      sVar6 = FUN_005ee080(iVar8,iVar10);
      FUN_00436fb0(*(undefined4 *)(&DAT_006d31c8 + (sVar6 + 8 >> 4 & 0xfffU) * 4),
                   *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar6 >> 4 & 0xfffU) * 4));
      iVar10 = FUN_005edfb0(iVar8,local_50,iVar10,local_4c);
      iVar10 = iVar10 / ((iVar12 * iVar2) / 15000 + iVar3);
      uVar9 = ((int)(iVar10 - 0x3cU) < 0) - 1 & iVar10 - 0x3cU;
      iVar10 = (int)(iVar10 + (iVar10 >> 0x1f & 3U)) >> 2;
      if (0xf < iVar10) {
        iVar10 = 0xf;
      }
      iVar8 = *(int *)(param_1 + 400);
      piVar11 = (int *)(iVar8 + (iVar10 + 0x17) * 0xc);
      local_30 = (uVar9 * local_24 + *piVar11) - *(int *)(iVar8 + 4);
      local_2c = (uVar9 * local_20 + piVar11[1]) - *(int *)(iVar8 + 8);
      local_28 = -*(int *)(iVar8 + 0xc);
      iVar10 = FUN_005ee500(local_3c);
      uVar7 = (int)(iVar10 + uVar7) / 2;
      uVar9 = (int)(uVar7 - iVar10) >> 0x1f;
      iVar10 = (uVar7 - iVar10 ^ uVar9) - uVar9;
    }
    if (*(int *)(param_1 + 700) != 0) {
      iVar12 = *(int *)(param_1 + 400);
      if (0x2cccc < *(int *)(iVar12 + 0xb0)) {
        local_1c = *(int *)(iVar12 + 0xd4) - *(int *)(iVar12 + 0xc);
        local_20 = *(int *)(iVar12 + 0xd0) - *(int *)(iVar12 + 8);
        local_24 = *(int *)(iVar12 + 0xcc) - *(int *)(iVar12 + 4);
        iVar12 = FUN_005ee500(local_3c);
        if ((int)uVar7 <= iVar12) {
          iVar12 = *(int *)(param_1 + 400);
          local_28 = *(int *)(iVar12 + 0xd4) - *(int *)(iVar12 + 0xc);
          local_2c = *(int *)(iVar12 + 0xd0) - *(int *)(iVar12 + 8);
          local_30 = *(int *)(iVar12 + 0xcc) - *(int *)(iVar12 + 4);
          uVar7 = FUN_005ee500(local_3c);
        }
      }
      iVar12 = *(int *)(param_1 + 400);
      if (0x2cccc < *(int *)(iVar12 + 0xbc)) {
        local_1c = *(int *)(iVar12 + 0xe0) - *(int *)(iVar12 + 0xc);
        local_20 = *(int *)(iVar12 + 0xdc) - *(int *)(iVar12 + 8);
        local_24 = *(int *)(iVar12 + 0xd8) - *(int *)(iVar12 + 4);
        iVar12 = FUN_005ee500(local_3c);
        if ((int)uVar7 <= iVar12) {
          iVar12 = *(int *)(param_1 + 400);
          local_28 = *(int *)(iVar12 + 0xe0) - *(int *)(iVar12 + 0xc);
          local_2c = *(int *)(iVar12 + 0xdc) - *(int *)(iVar12 + 8);
          local_30 = *(int *)(iVar12 + 0xd8) - *(int *)(iVar12 + 4);
          uVar7 = FUN_005ee500(local_3c);
        }
      }
    }
    FUN_005ee170(local_c,uVar7);
  }
LAB_005b04a6:
  uVar13 = FUN_005b1330(local_c,*(int *)(param_1 + 0x18c) + 0x1828);
  FUN_005a89c0(uVar13,0x5a);
  return;
}


