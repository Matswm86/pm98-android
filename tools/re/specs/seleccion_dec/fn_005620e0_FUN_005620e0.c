// FUN_005620e0  entry=005620e0  size=868 bytes

void __fastcall FUN_005620e0(int param_1)

{
  undefined2 uVar1;
  int iVar2;
  uint uVar3;
  uint uVar4;
  int iVar5;
  int iVar6;
  undefined1 *puVar7;
  int iVar8;
  uint uVar9;
  undefined4 *puVar10;
  uint *puVar11;
  uint local_60;
  uint local_5c;
  undefined4 *local_54;
  int iStack_50;
  int iStack_48;
  uint uStack_44;
  undefined4 local_34 [13];
  
  FUN_005c1df0(&DAT_00658a58);
  FUN_00562450();
  puVar10 = local_34;
  for (iVar6 = 0xd; iVar6 != 0; iVar6 = iVar6 + -1) {
    *puVar10 = 0;
    puVar10 = puVar10 + 1;
  }
  iVar6 = DAT_0066c178 + *(int *)(param_1 + 0x1928) * 0x9c;
  local_5c = FUN_0058b5d0();
  iVar2 = *(int *)(iVar6 + 0x24);
  uVar9 = 0;
  local_60 = 0;
  if (iVar2 != 0xffff) {
    FUN_00585ee0(iVar2);
    iVar2 = FUN_005793d0();
    if (*(int *)(iVar2 + 0x5c) == *(int *)(param_1 + 0x1928)) {
      *(int *)(param_1 + 0x7310) = iVar2;
      if ((*(uint *)(param_1 + 0x7368) >> 7 & 1) != 0) {
        FUN_005bf8c0(1,1);
      }
      FUN_005bec80(0);
      *(int *)(param_1 + 0x9c00) = iVar2;
      if ((*(uint *)(param_1 + 0x9c58) >> 7 & 1) != 0) {
        FUN_005bf8c0(1,1);
      }
      FUN_005bec80(0);
      local_60 = 1;
      uVar9 = 1;
    }
  }
  while ((uVar9 < 10 && (local_5c < 0xd))) {
    local_54 = &DAT_0066b190;
    do {
      if (9 < uVar9) break;
      uVar3 = (**(code **)(*(int *)*local_54 + 0x78))(0);
      if (local_5c <= uVar3) {
        uVar3 = (**(code **)(*(int *)*local_54 + 0x4c))();
        uVar4 = FUN_0058df90(uVar3);
        uStack_44 = 0;
        if (uVar3 != 0) {
          do {
            if (9 < uVar9) break;
            uVar9 = FUN_0058df90(100);
            if (uVar9 < 0x32) {
              iStack_50 = (**(code **)(*(int *)*local_54 + 0x50))(uVar4);
              iVar2 = 0;
              iVar8 = 1;
            }
            else {
              iStack_50 = 1;
              iVar2 = (**(code **)(*(int *)*local_54 + 0x50))(uVar4);
              iVar2 = iVar2 + -1;
              iVar8 = -1;
            }
            iStack_48 = iVar8 * iVar2;
            if (iStack_48 < iStack_50) {
              puVar11 = (uint *)(param_1 + 0x9c58 + local_60 * 0x418);
              do {
                if (9 < local_60) break;
                uVar1 = (**(code **)(*(int *)*local_54 + 0x54))(uVar4,iVar2);
                FUN_00585ee0(uVar1);
                uVar9 = FUN_005793d0();
                iVar5 = FUN_005624d0(uVar9);
                if ((((iVar5 == 0) && (*(int *)(iVar6 + 0x24) != *(int *)(uVar9 + 0x10))) &&
                    (*(uint *)(uVar9 + 0x58) == local_5c)) && (*(int *)(uVar9 + 0x5c) == 0xffff)) {
                  puVar11[-0xa52] = uVar9;
                  if ((puVar11[-0xa3c] >> 7 & 1) != 0) {
                    FUN_005bf8c0(1,1);
                  }
                  FUN_005bec80(0);
                  puVar11[-0x16] = uVar9;
                  if ((*puVar11 >> 7 & 1) != 0) {
                    FUN_005bf8c0(1,1);
                  }
                  FUN_005bec80(0);
                  local_60 = local_60 + 1;
                  puVar11 = puVar11 + 0x106;
                }
                iStack_48 = iStack_48 + iVar8 * iVar8;
                iVar2 = iVar2 + iVar8;
              } while (iStack_48 < iStack_50);
            }
            uVar4 = (uVar4 + 1) % uVar3;
            uStack_44 = uStack_44 + 1;
            uVar9 = local_60;
          } while (uStack_44 < uVar3);
        }
      }
      local_54 = local_54 + 1;
    } while (local_54 < &DAT_0066b1a0);
    local_34[local_5c] = 1;
    local_5c = local_5c + 1;
    if (9 < uVar9) break;
    if (0xc < local_5c) {
      iVar2 = 0xd;
      puVar7 = (undefined1 *)register0x00000010;
      do {
        if (*(int *)(puVar7 + -4) == 0) break;
        iVar2 = iVar2 + -1;
        puVar7 = puVar7 + -4;
      } while (iVar2 != 0);
      if (iVar2 == 0) {
        local_5c = 0xd;
      }
      else {
        local_5c = iVar2 - 1;
      }
    }
  }
  FUN_005c1df0(&DAT_00666f70);
  return;
}


