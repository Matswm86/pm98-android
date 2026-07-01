// FUN_005b8f20  entry=005b8f20  size=1169 bytes

int __fastcall FUN_005b8f20(int *param_1)

{
  undefined4 uVar1;
  int *_Dst;
  bool bVar2;
  char cVar3;
  int iVar4;
  int iVar5;
  undefined4 *puVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  bool bVar10;
  int local_18;
  int local_14;
  int local_c;
  int local_8;
  
  iVar8 = param_1[0x5a];
  if (DAT_006d31c4 != '\0') {
    if (iVar8 != 0) {
      *(undefined1 *)(iVar8 + 0x5c) = 0;
    }
    iVar8 = *(int *)(param_1[0x4e] + 0x438);
    param_1[0x5a] = iVar8;
    if (iVar8 != 0) {
      *(undefined1 *)(iVar8 + 0x5c) = 1;
      return param_1[0x5a];
    }
    goto LAB_005b93a3;
  }
  if (iVar8 != 0) {
    *(undefined1 *)(iVar8 + 0x5c) = 0;
  }
  param_1[0x5a] = 0;
  iVar8 = *(int *)(param_1[0x4e] + 0x448);
  if ((iVar8 == 7) || (iVar8 == 5)) {
    if (param_1[0x83] == 0) {
      local_8 = param_1[1];
      local_c = *param_1;
      bVar2 = true;
      if (local_8 != 0) {
        do {
          local_8 = local_8 + -1;
          if ((!bVar2) || (bVar2 = true, *(int *)(local_c + 0x8c) == 0)) {
            bVar2 = false;
          }
          iVar4 = param_1[0x83];
          iVar8 = (iVar4 + 1) * 4;
          FUN_005bbf10(param_1 + 0x82,iVar8);
          param_1[0x83] = iVar4 + 1;
          *(int *)(param_1[0x82] + -4 + iVar8) = local_c;
          local_c = local_c + 0x3bc;
        } while (local_8 != 0);
      }
      iVar8 = param_1[0x83];
      if (0 < iVar8) {
        local_18 = 0;
        local_14 = 1;
        do {
          iVar4 = *(int *)(local_18 + param_1[0x82]);
          iVar7 = local_14;
          if (local_14 < iVar8) {
            do {
              iVar8 = param_1[0x82];
              iVar5 = *(int *)(iVar8 + iVar7 * 4);
              if (*(int *)(iVar4 + 700) == 0) {
LAB_005b924f:
                uVar1 = *(undefined4 *)(local_18 + iVar8);
                *(undefined4 *)(local_18 + iVar8) = *(undefined4 *)(iVar8 + iVar7 * 4);
                *(undefined4 *)(iVar8 + iVar7 * 4) = uVar1;
              }
              else {
                iVar9 = *(int *)(iVar4 + 0x3a0);
                if (*(int *)(param_1[0x4e] + 0x448) == 7) {
                  iVar9 = iVar9 + *(int *)(iVar4 + 0x388);
                  iVar5 = *(int *)(iVar5 + 0x3a0) + *(int *)(iVar5 + 0x388);
                  bVar10 = SBORROW4(iVar9,iVar5);
                  iVar9 = iVar9 - iVar5;
                }
                else {
                  bVar10 = SBORROW4(iVar9,*(int *)(iVar5 + 0x3a0));
                  iVar9 = iVar9 - *(int *)(iVar5 + 0x3a0);
                }
                if (bVar10 != iVar9 < 0) goto LAB_005b924f;
              }
              iVar7 = iVar7 + 1;
            } while (iVar7 < param_1[0x83]);
          }
          iVar8 = param_1[0x83];
          local_18 = local_18 + 4;
          bVar10 = local_14 < iVar8;
          local_14 = local_14 + 1;
        } while (bVar10);
      }
      if (*(char *)((int)param_1 + 0x2ee) == '\0') {
LAB_005b92d4:
        cVar3 = '\0';
      }
      else {
        cVar3 = FUN_005943f0();
        if (cVar3 == '\0') {
          cVar3 = FUN_005943d0();
          if ((cVar3 == '\0') && (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
            bVar10 = false;
          }
          else {
            bVar10 = true;
          }
          if (!bVar10) goto LAB_005b92d4;
        }
        cVar3 = '\x01';
      }
      *(char *)((int)param_1 + 0x2ed) = cVar3;
      if ((cVar3 != '\0') || (*(int *)(param_1[0x4e] + 0x19a0) != 4)) {
        FUN_005bbf10(param_1 + 0x82,4);
        param_1[0x83] = 1;
      }
      if ((bVar2) || (*(int *)(param_1[0x4e] + 0x19a0) != 4)) {
        iVar8 = param_1[1];
        if (iVar8 != 0) {
          puVar6 = (undefined4 *)(*param_1 + 0x8c);
          do {
            iVar8 = iVar8 + -1;
            *puVar6 = 0;
            puVar6 = puVar6 + 0xef;
          } while (iVar8 != 0);
        }
      }
    }
    _Dst = (int *)param_1[0x82];
    param_1[0x5a] = *_Dst;
    memmove(_Dst,_Dst + 1,param_1[0x83] * 4 - 4);
    iVar8 = param_1[0x83];
    param_1[0x83] = iVar8 + -1;
    FUN_005bbf10(param_1 + 0x82,(iVar8 + -1) * 4);
  }
  else if (iVar8 == 4) {
    iVar8 = param_1[1];
    iVar4 = *param_1;
    iVar9 = 0;
    iVar7 = iVar8;
    iVar5 = iVar4;
    while (iVar7 != 0) {
      iVar7 = iVar7 + -1;
      if ((*(int *)(iVar5 + 700) != 0) &&
         ((iVar9 == 0 || (*(int *)(iVar9 + 0x39c) < *(int *)(iVar5 + 0x39c))))) {
        iVar9 = iVar5;
      }
      iVar5 = iVar5 + 0x3bc;
    }
    local_18 = 0;
    iVar7 = iVar8;
    iVar5 = iVar4;
    while (iVar7 != 0) {
      iVar7 = iVar7 + -1;
      if (((*(int *)(iVar5 + 700) != 0) && (iVar5 != iVar9)) &&
         ((local_18 == 0 || (*(int *)(local_18 + 0x39c) < *(int *)(iVar5 + 0x39c))))) {
        local_18 = iVar5;
      }
      iVar5 = iVar5 + 0x3bc;
    }
    while (iVar8 != 0) {
      iVar8 = iVar8 + -1;
      if ((((*(int *)(iVar4 + 700) != 0) && (iVar4 != iVar9)) && (iVar4 != local_18)) &&
         ((param_1[0x5a] == 0 || (*(int *)(param_1[0x5a] + 0x394) < *(int *)(iVar4 + 0x394))))) {
        param_1[0x5a] = iVar4;
      }
      iVar4 = iVar4 + 0x3bc;
    }
  }
  else if (iVar8 == 2) {
    iVar8 = param_1[1];
    iVar4 = *param_1;
    while (iVar8 != 0) {
      iVar8 = iVar8 + -1;
      if ((*(int *)(iVar4 + 700) != 0) &&
         ((param_1[0x5a] == 0 ||
          (*(int *)(&DAT_006392c8 + *(int *)(param_1[0x5a] + 0x2c8) * 4) <=
           *(int *)(&DAT_006392c8 + *(int *)(iVar4 + 0x2c8) * 4))))) {
        param_1[0x5a] = iVar4;
      }
      iVar4 = iVar4 + 0x3bc;
    }
  }
  else if (iVar8 == 6) {
    param_1[0x5a] = *param_1;
  }
  else {
    FUN_005b8ce0(0);
  }
  if (param_1[0x5a] != 0) {
    *(undefined1 *)(param_1[0x5a] + 0x5c) = 1;
  }
LAB_005b93a3:
  return param_1[0x5a];
}


