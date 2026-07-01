// FUN_005efac0  entry=005efac0  size=1435 bytes

undefined1 __thiscall
FUN_005efac0(int *param_1,undefined4 *param_2,int *param_3,int param_4,uint *param_5,
            undefined4 param_6,int *param_7)

{
  bool bVar1;
  bool bVar2;
  undefined4 *puVar3;
  int iVar4;
  int iVar5;
  int *piVar6;
  int iVar7;
  int *piVar8;
  undefined4 uVar9;
  uint *puVar10;
  int iVar11;
  uint uVar12;
  int iVar13;
  uint uVar14;
  int local_a0;
  undefined1 local_99;
  int local_98;
  int local_90;
  int local_8c;
  int local_88;
  int local_84;
  int local_80;
  int local_7c;
  undefined4 local_78;
  int *local_74;
  uint local_70;
  uint local_6c;
  uint local_68;
  int local_64;
  int local_60;
  int local_5c;
  int local_58;
  int *local_54;
  int local_50;
  int local_4c;
  int local_48;
  int local_44;
  int local_40;
  undefined4 local_3c;
  undefined4 local_38;
  undefined4 local_34;
  int local_30 [11];
  int local_4;
  
  local_38 = param_2[1];
  local_3c = *param_2;
  local_34 = param_2[2];
  local_84 = *param_3;
  local_80 = param_3[1];
  local_7c = param_3[2];
  local_99 = 0;
  local_70 = *param_5;
  local_6c = param_5[1];
  local_68 = param_5[2];
  local_54 = param_1;
  local_40 = FUN_005ee080(local_3c,local_38);
  iVar13 = -local_40;
  puVar3 = (undefined4 *)FUN_005ee670(iVar13);
  iVar4 = FUN_005ee080(*puVar3,puVar3[2]);
  iVar5 = -iVar4;
  local_50 = 1;
  local_58 = iVar4;
  FUN_005ee670(iVar13);
  FUN_005ee6e0(iVar5);
  if ((int)local_70 < 0) {
    local_50 = -1;
    local_70 = -local_70;
    local_68 = -local_68;
    iVar4 = iVar4 + -0x8000;
    local_58 = iVar4;
  }
  local_84 = local_84 - *param_1;
  local_80 = local_80 - param_1[1];
  local_74 = param_1 + 2;
  local_7c = local_7c - *local_74;
  iVar5 = -iVar4;
  FUN_005ee670(iVar13);
  FUN_005ee6e0(iVar5);
  if (local_70 != 0) {
    iVar5 = (local_70 ^ (int)local_70 >> 0x1f) - ((int)local_70 >> 0x1f);
    iVar11 = -((local_84 + param_4) * (((-1 < (int)local_70) - 1 & 0xfffffffe) + 1));
    if (((-1 < iVar11) && (iVar11 < iVar5)) || ((-param_4 < local_84 && (local_84 < 1)))) {
      local_78 = FUN_005edf90(iVar11,iVar5);
      piVar8 = local_30;
      local_98 = 4;
      piVar6 = local_74;
      do {
        *piVar8 = piVar6[-2];
        piVar8[1] = piVar6[-1];
        *(int *)(((int)&local_3c - (int)param_1) + (int)(piVar6 + 3)) = *piVar6;
        piVar8 = piVar8 + 3;
        local_98 = local_98 + -1;
        piVar6 = piVar6 + 3;
      } while (local_98 != 0);
      iVar5 = FUN_005ee170(&local_64,local_78);
      local_8c = *(int *)(iVar5 + 4) + local_80;
      local_88 = *(int *)(iVar5 + 8) + local_7c;
      bVar2 = false;
      iVar5 = 4;
      piVar8 = &local_4;
      do {
        piVar8[-2] = piVar8[-2] - *param_1;
        piVar8[-1] = piVar8[-1] - param_1[1];
        *piVar8 = *piVar8 - *local_74;
        iVar5 = iVar5 + -1;
        piVar8 = piVar8 + -3;
      } while (iVar5 != 0);
      local_98 = 4;
      do {
        FUN_005ee670(iVar13);
        local_98 = local_98 + -1;
      } while (local_98 != 0);
      iVar5 = 4;
      do {
        FUN_005ee6e0(-iVar4);
        iVar5 = iVar5 + -1;
      } while (iVar5 != 0);
      local_a0 = -1;
      do {
        if (1 < local_a0) break;
        for (iVar4 = -1; (!bVar2 && (iVar4 < 2)); iVar4 = iVar4 + 2) {
          bVar2 = false;
          iVar5 = local_a0 + local_8c;
          local_5c = iVar4 + local_88;
          piVar8 = local_30 + 1;
          uVar14 = 1;
          do {
            iVar13 = *piVar8;
            uVar12 = (int)uVar14 >> 0x1f;
            if (iVar13 < iVar5) {
              iVar7 = ((uVar14 ^ uVar12) - uVar12 & 3 ^ uVar12) - uVar12;
              iVar11 = local_30[iVar7 * 3 + 1];
              piVar6 = local_30 + iVar7 * 3;
              if (iVar5 <= iVar11) goto LAB_005efde4;
              if (iVar5 <= iVar13) goto LAB_005efdc1;
            }
            else {
LAB_005efdc1:
              iVar11 = ((uVar14 ^ uVar12) - uVar12 & 3 ^ uVar12) - uVar12;
              piVar6 = local_30 + iVar11 * 3;
              iVar11 = local_30[iVar11 * 3 + 1];
              if (iVar11 < iVar5) {
LAB_005efde4:
                iVar13 = MulDiv(piVar6[2] - piVar8[1],iVar5 - iVar13,iVar11 - iVar13);
                if (iVar13 + piVar8[1] < local_5c) {
                  bVar2 = (bool)(bVar2 ^ 1);
                }
              }
            }
            piVar8 = piVar8 + 3;
            bVar1 = (int)uVar14 < 4;
            uVar14 = uVar14 + 1;
          } while (bVar1);
          param_1 = local_54;
        }
        local_a0 = local_a0 + 2;
      } while (!bVar2);
      if (bVar2) {
        piVar8 = (int *)FUN_005ee170(&local_90,local_78);
        *param_3 = *param_3 + *piVar8;
        iVar4 = param_3[2];
        param_3[1] = param_3[1] + piVar8[1];
        iVar5 = piVar8[2];
        param_3[2] = iVar4 + iVar5;
        if (param_7 != (int *)0x0) {
          local_4c = param_1[3] - *param_1;
          local_48 = param_1[4] - param_1[1];
          local_44 = param_1[5] - *local_74;
          local_88 = (iVar4 + iVar5) - *local_74;
          local_64 = param_1[6] - param_1[3];
          local_60 = param_1[7] - param_1[4];
          local_5c = param_1[8] - param_1[5];
          local_90 = *param_3 - *param_1;
          local_8c = param_3[1] - param_1[1];
          uVar9 = ftol();
          uVar9 = FUN_005edfa0(uVar9,uVar9);
          FUN_005ee200(uVar9);
          uVar9 = ftol();
          uVar9 = FUN_005edfa0(uVar9,uVar9);
          FUN_005ee200(uVar9);
          iVar4 = FUN_005ee500(&local_90);
          iVar5 = FUN_005ee500(&local_90);
          *param_7 = iVar4 * local_50;
          param_7[1] = iVar5 * local_50;
        }
        iVar4 = local_58;
        iVar5 = local_40;
        FUN_005ee750(0xffff8000);
        FUN_005ee6e0(iVar4);
        piVar8 = (int *)FUN_005ee670(iVar5);
        local_88 = -piVar8[2];
        local_8c = -piVar8[1];
        local_90 = -*piVar8;
        puVar10 = (uint *)FUN_005ee1c0(param_6);
        *param_5 = *puVar10;
        param_5[1] = puVar10[1];
        param_5[2] = puVar10[2];
        piVar8 = (int *)FUN_005ee170(&local_90,local_78);
        *param_3 = *param_3 - *piVar8;
        local_99 = 1;
        param_3[1] = param_3[1] - piVar8[1];
        param_3[2] = param_3[2] - piVar8[2];
      }
    }
  }
  return local_99;
}


