// FUN_0058fda0  entry=0058fda0  size=1290 bytes

void __fastcall FUN_0058fda0(int param_1)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  int iVar6;
  int *piVar7;
  int iVar8;
  int *piVar9;
  int *local_3c;
  int local_38;
  int *local_34;
  int local_30;
  int *local_28;
  int local_24;
  int local_20;
  int local_1c;
  uint local_10;
  int local_c;
  int local_8;
  
  local_24 = *(int *)(param_1 + 4);
  local_20 = *(int *)(param_1 + 8);
  iVar5 = *(int *)(param_1 + 0x24);
  local_10 = *(uint *)(param_1 + 0x28);
  local_1c = *(int *)(param_1 + 0xc);
  local_3c = (int *)(param_1 + 0x74);
  iVar8 = *(int *)(param_1 + 0x20);
  piVar7 = (int *)(param_1 + 0xa8);
  local_30 = 3;
  do {
    if ((local_10 == 0) && (local_1c == 0)) {
      uVar1 = FUN_005ee080(iVar8,iVar5);
      FUN_005ee0f0(0x22,uVar1);
      iVar6 = local_c;
      if (local_c == 0) {
        iVar6 = 0x10000;
      }
      iVar2 = local_8;
      if (local_8 == 0) {
        iVar2 = 0x10000;
      }
      if (iVar5 / iVar2 < iVar8 / iVar6) {
        iVar6 = iVar8;
        iVar2 = local_c;
        if (local_c == 0) {
          iVar2 = 0x10000;
        }
      }
      else {
        iVar6 = iVar5;
        iVar2 = local_8;
        if (local_8 == 0) {
          iVar2 = 0x10000;
        }
      }
      iVar6 = (iVar6 / iVar2) / 9;
      iVar2 = iVar6 / 2;
      *piVar7 = (iVar8 - (iVar2 * local_c) / 2) * iVar2 + local_24;
      piVar7[1] = (iVar5 - (iVar2 * local_8) / 2) * iVar2 + local_20;
      piVar7[2] = 0;
      *local_3c = iVar6;
      piVar7[9] = (iVar8 - (iVar6 * local_c) / 2) * iVar6 + local_24;
      iVar8 = iVar8 - iVar6 * local_c;
      piVar7[10] = (iVar5 - (iVar6 * local_8) / 2) * iVar6 + local_20;
      piVar7[0xb] = 0;
      local_24 = piVar7[9];
      local_20 = piVar7[10];
      local_1c = piVar7[0xb];
      iVar5 = iVar5 - iVar6 * local_8;
      piVar7[0x12] = iVar8;
      piVar7[0x13] = iVar5;
    }
    else {
      if ((int)local_10 < 1) {
        *piVar7 = local_24;
        piVar7[1] = local_20;
        piVar7[2] = local_1c;
      }
      else {
        iVar6 = (int)local_10 / 0xb2;
        *piVar7 = iVar8 * iVar6 + local_24;
        piVar7[1] = iVar5 * iVar6 + local_20;
        piVar7[2] = (local_10 - (iVar6 * 0xb2) / 2) * iVar6 + local_1c;
      }
      iVar6 = ftol();
      *local_3c = iVar6;
      piVar7[9] = iVar8 * iVar6 + local_24;
      piVar7[10] = iVar5 * iVar6 + local_20;
      piVar7[0xb] = 0;
      local_24 = piVar7[9];
      local_20 = piVar7[10];
      local_1c = piVar7[0xb];
      iVar8 = FUN_005edfa0(iVar8,0xc51e);
      iVar5 = FUN_005edfa0(iVar5,0xc51e);
      iVar6 = FUN_005edfa0(local_10 + iVar6 * -0xb2,0x9c28);
      local_10 = -iVar6;
      if ((int)((local_10 ^ (int)local_10 >> 0x1f) - ((int)local_10 >> 0x1f)) < 0x28f) {
        local_10 = 0;
      }
      piVar7[0x12] = iVar8;
      piVar7[0x13] = iVar5;
    }
    piVar7[0x14] = local_10;
    local_3c = local_3c + 1;
    piVar7 = piVar7 + 3;
    local_30 = local_30 + -1;
  } while (local_30 != 0);
  iVar2 = 0;
  iVar6 = 0;
  local_30 = 0;
  local_20 = *(int *)(param_1 + 8);
  local_24 = *(int *)(param_1 + 4);
  local_10 = *(int *)(param_1 + 0x28);
  iVar5 = *(int *)(param_1 + 0x20);
  iVar8 = *(int *)(param_1 + 0x24);
  local_1c = *(int *)(param_1 + 0xc);
  local_34 = (int *)(param_1 + 0x74);
  local_28 = (int *)(param_1 + 0xf0);
  local_3c = (int *)(param_1 + 0x114);
  local_38 = 0;
  do {
    if (0xf < iVar6) {
      return;
    }
    if (iVar2 < *local_34) {
      if (local_10 == 0) {
        uVar1 = FUN_005ee080(iVar5,iVar8);
        FUN_005ee0f0(0x22,uVar1);
        iVar6 = local_c;
        if (local_c == 0) {
          iVar6 = 0x10000;
        }
        iVar3 = local_8;
        if (local_8 == 0) {
          iVar3 = 0x10000;
        }
        if (iVar8 / iVar3 < iVar5 / iVar6) {
          iVar6 = local_c;
          if (local_c == 0) {
            iVar6 = 0x10000;
          }
          iVar6 = iVar5 / iVar6;
        }
        else {
          iVar6 = local_8;
          if (local_8 == 0) {
            iVar6 = 0x10000;
          }
          iVar6 = iVar8 / iVar6;
        }
        if (iVar2 < iVar6) {
          iVar6 = iVar2;
        }
        *local_3c = (iVar5 - (iVar6 * local_c) / 2) * iVar6 + local_24;
        local_3c[1] = (iVar8 - (iVar6 * local_8) / 2) * iVar6 + local_20;
        local_3c[2] = 0;
      }
      else {
        *local_3c = iVar5 * iVar2 + local_24;
        local_3c[1] = iVar8 * iVar2 + local_20;
        local_3c[2] = (local_10 - (iVar2 * 0xb2) / 2) * iVar2 + local_1c;
      }
      iVar2 = iVar2 + 4;
      iVar6 = local_38 + 1;
      local_3c = local_3c + 3;
      local_38 = iVar6;
    }
    else {
      iVar2 = iVar2 - *local_34;
      local_24 = local_28[-9];
      local_20 = local_28[-8];
      local_1c = local_28[-7];
      iVar5 = *local_28;
      iVar8 = local_28[1];
      local_10 = local_28[2];
      local_30 = local_30 + 1;
      local_34 = local_34 + 1;
      local_28 = local_28 + 3;
    }
  } while (local_30 < 3);
  if (iVar6 < 0x10) {
    piVar7 = (int *)(param_1 + (iVar6 + 0x17) * 0xc);
    *piVar7 = local_24;
    piVar7[1] = local_20;
    piVar7[2] = local_1c;
    piVar9 = piVar7 + 3;
    for (uVar4 = iVar6 * -0xc + 0xb4U >> 2; uVar4 != 0; uVar4 = uVar4 - 1) {
      *piVar9 = *piVar7;
      piVar7 = piVar7 + 1;
      piVar9 = piVar9 + 1;
    }
  }
  return;
}


