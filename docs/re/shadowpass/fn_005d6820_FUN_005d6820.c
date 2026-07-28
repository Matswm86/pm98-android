// FUN_005d6820  entry=005d6820  size=678 bytes

undefined1 __thiscall FUN_005d6820(int *param_1,int *param_2,uint param_3)

{
  int iVar1;
  uint uVar2;
  uint uVar3;
  char cVar4;
  bool bVar5;
  undefined1 uVar6;
  undefined1 *puVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  uint *puVar11;
  undefined1 *puVar12;
  int iVar13;
  uint *puVar14;
  int local_8;
  
  uVar6 = 0;
  if ((param_3 & 1) == 0) {
    if ((param_1[1] == 0) && (*param_1 == 0)) {
      bVar5 = false;
    }
    else {
      bVar5 = true;
    }
    if (((!bVar5) || (param_1[5] != param_2[5])) || (param_1[6] != param_2[6])) {
      FUN_005c9a30(param_2[5],param_2[6],8,0,0xffffffff);
    }
    if ((*param_1 == 0) && (cVar4 = FUN_005cb2b0(), cVar4 == '\0')) {
      bVar5 = false;
    }
    else {
      bVar5 = true;
    }
    if (bVar5) {
      if ((*param_2 == 0) && (cVar4 = FUN_005cb2b0(), cVar4 == '\0')) {
        bVar5 = false;
      }
      else {
        bVar5 = true;
      }
      if (bVar5) {
        iVar13 = (param_1[6] + -1) * param_1[7] + -4 + param_1[5];
        puVar14 = (uint *)*param_1;
        iVar8 = (int)(iVar13 + (iVar13 >> 0x1f & 3U)) >> 2;
        puVar11 = (uint *)(iVar13 + *param_2);
        if ((param_3 & 2) == 0) {
          uVar2 = param_2[5];
          uVar3 = param_2[6];
          uVar6 = FUN_005cba50((0 < (int)uVar2) - 1 & uVar2,(0 < (int)uVar3) - 1 & uVar3,
                               uVar2 & ((int)uVar2 < 0) - 1,uVar3 & ((int)uVar3 < 0) - 1,param_2,0,0
                              );
        }
        else {
          do {
            uVar2 = *puVar11;
            puVar11 = puVar11 + -1;
            *puVar14 = uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 |
                       uVar2 << 0x18;
            puVar14 = puVar14 + 1;
            iVar8 = iVar8 + -1;
          } while (iVar8 != 0);
          uVar6 = 1;
        }
        if ((param_3 & 4) != 0) {
          FUN_005cc090();
        }
      }
    }
  }
  else {
    if ((param_1[1] == 0) && (*param_1 == 0)) {
      bVar5 = false;
    }
    else {
      bVar5 = true;
    }
    if (((!bVar5) || (param_1[5] != param_2[6])) || (param_1[6] != param_2[5])) {
      FUN_005c9a30(param_2[6],param_2[5],8,0,0xffffffff);
    }
    if ((*param_1 == 0) && (cVar4 = FUN_005cb2b0(), cVar4 == '\0')) {
      bVar5 = false;
    }
    else {
      bVar5 = true;
    }
    if (bVar5) {
      if ((*param_2 == 0) && (cVar4 = FUN_005cb2b0(), cVar4 == '\0')) {
        bVar5 = false;
      }
      else {
        bVar5 = true;
      }
      if (bVar5) {
        if ((param_3 & 4) == 0) {
          puVar7 = (undefined1 *)*param_1;
        }
        else {
          puVar7 = (undefined1 *)((param_1[6] + -1) * param_1[7] + *param_1);
        }
        iVar13 = param_1[6];
        iVar8 = param_1[5];
        if ((param_3 & 4) == 0) {
          iVar9 = param_1[7] - iVar8;
        }
        else {
          iVar9 = -(param_1[7] + iVar8);
        }
        iVar10 = iVar8;
        if ((param_3 & 2) == 0) {
          puVar12 = (undefined1 *)(*param_2 + -1 + param_2[5]);
          local_8 = param_2[7];
          param_2 = (int *)(-1 - local_8 * param_2[6]);
        }
        else {
          iVar1 = param_2[7];
          puVar12 = (undefined1 *)((param_2[6] + -1) * iVar1 + *param_2);
          local_8 = -iVar1;
          param_2 = (int *)(iVar1 * param_2[6] + 1);
        }
        do {
          do {
            *puVar7 = *puVar12;
            puVar12 = puVar12 + local_8;
            puVar7 = puVar7 + 1;
            iVar10 = iVar10 + -1;
          } while (iVar10 != 0);
          puVar12 = puVar12 + (int)param_2;
          puVar7 = puVar7 + iVar9;
          iVar13 = iVar13 + -1;
          iVar10 = iVar8;
        } while (iVar13 != 0);
        return 1;
      }
    }
  }
  return uVar6;
}


