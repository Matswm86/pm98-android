// FUN_005b94f0  entry=005b94f0  size=631 bytes

void __fastcall FUN_005b94f0(int *param_1)

{
  char cVar1;
  int iVar2;
  undefined4 *puVar3;
  int *piVar4;
  int iVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  uint uVar9;
  int iVar10;
  int local_24;
  int local_20;
  int local_14;
  int local_8;
  
  iVar2 = FUN_005b70b0();
  if (*(int *)(iVar2 + 0x58) != *(int *)(iVar2 + 0x54)) {
    for (iVar2 = param_1[1]; iVar2 != 0; iVar2 = iVar2 + -1) {
      FUN_005b13c0();
    }
  }
  cVar1 = FUN_005b8c90();
  if (cVar1 == '\0') {
    iVar2 = param_1[1];
    if (iVar2 != 0) {
      puVar3 = (undefined4 *)(*param_1 + 0x150);
      do {
        iVar2 = iVar2 + -1;
        puVar3[1] = 0;
        *puVar3 = 0;
        puVar3 = puVar3 + 0xef;
      } while (iVar2 != 0);
    }
    iVar2 = FUN_005b70c0();
    local_8 = *(int *)(iVar2 + 4);
    piVar4 = (int *)FUN_005b70c0();
    iVar2 = *piVar4;
    while (local_8 != 0) {
      local_8 = local_8 + -1;
      FUN_005b70c0();
      *(undefined4 *)(iVar2 + 0x154) = 0;
      *(undefined4 *)(iVar2 + 0x150) = 0;
      if ((iVar2 == *(int *)(*(int *)(iVar2 + 400) + 0x40)) ||
         (iVar5 = FUN_005b70b0(), iVar2 == *(int *)(iVar5 + 0x4c))) {
        local_14 = param_1[1];
        iVar5 = *param_1;
        local_24 = 0x3e80000;
        local_20 = 0;
        while (local_14 != 0) {
          local_14 = local_14 + -1;
          if (iVar2 == 0) {
            iVar10 = 0xc80000;
          }
          else {
            iVar10 = *(int *)(iVar5 + 0xe4 +
                             (*(int *)(iVar2 + 0x2b8) * 0xb + *(int *)(iVar2 + 0x2c4)) * 4);
          }
          uVar6 = *(int *)(iVar5 + 8) - *(int *)(iVar2 + 8);
          uVar9 = (int)uVar6 >> 0x1f;
          iVar10 = (int)((uVar6 ^ uVar9) - uVar9) / 3 + iVar10;
          if (*(int *)(iVar5 + 700) != 0) {
            if (*(int *)(iVar5 + 0x2b8) == *(int *)(iVar2 + 0x2b8)) {
              if (iVar2 == 0) {
LAB_005b9682:
                iVar8 = 0xc80000;
              }
              else {
                uVar6 = *(int *)(iVar2 + 4) - *(int *)(iVar2 + 0x3a4);
                uVar9 = (int)uVar6 >> 0x1f;
                iVar8 = (uVar6 ^ uVar9) - uVar9;
              }
            }
            else {
              if (iVar2 == 0) goto LAB_005b9682;
              uVar6 = *(int *)(iVar2 + 0x3a4) + *(int *)(iVar2 + 4);
              uVar9 = (int)uVar6 >> 0x1f;
              iVar8 = (uVar6 ^ uVar9) - uVar9;
            }
            if (iVar5 == 0) {
              iVar7 = 0xc80000;
            }
            else {
              uVar6 = *(int *)(iVar5 + 4) - *(int *)(iVar5 + 0x3a4);
              uVar9 = (int)uVar6 >> 0x1f;
              iVar7 = (uVar6 ^ uVar9) - uVar9;
            }
            if ((iVar7 < iVar8) && (iVar10 < local_24)) {
              local_24 = iVar10;
              local_20 = iVar5;
            }
          }
          iVar5 = iVar5 + 0x3bc;
        }
        if (local_20 != 0) {
          *(int *)(local_20 + 0x150) = iVar2;
          *(int *)(iVar2 + 0x154) = local_20;
        }
      }
      FUN_005b70c0();
      iVar2 = iVar2 + 0x3bc;
    }
    iVar2 = param_1[1];
    iVar5 = *param_1;
    while (iVar2 != 0) {
      iVar2 = iVar2 + -1;
      if ((*(int *)(iVar5 + 700) != 0) && (*(int *)(iVar5 + 0x150) == 0)) {
        iVar10 = FUN_005b36f0();
        *(int *)(iVar5 + 0x150) = iVar10;
        if ((iVar10 != 0) && (*(int *)(iVar10 + 0x154) == 0)) {
          *(int *)(iVar10 + 0x154) = iVar5;
        }
      }
      iVar5 = iVar5 + 0x3bc;
    }
  }
  return;
}


