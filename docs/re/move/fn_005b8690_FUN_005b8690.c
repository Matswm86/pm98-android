// FUN_005b8690  entry=005b8690  size=964 bytes

void __fastcall FUN_005b8690(int *param_1)

{
  undefined4 uVar1;
  short sVar2;
  uint uVar3;
  undefined4 *puVar4;
  undefined4 uVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  uint uVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  int iVar13;
  int local_4c;
  short *local_48;
  int *local_44;
  int local_40;
  int local_3c;
  int local_38;
  int local_30;
  
  uVar3 = param_1[0xb8] + 1U & 7;
  param_1[0xb8] = uVar3;
  if (uVar3 == 0) {
    if (param_1[2] == 0) {
      iVar6 = *(int *)(param_1[0x4e] + 0x790);
      if (iVar6 != 0) {
        puVar4 = (undefined4 *)(*(int *)(param_1[0x4e] + 0x78c) + 0x17c);
        do {
          iVar6 = iVar6 + -1;
          puVar4[1] = 0x3e80000;
          *puVar4 = 0x3e80000;
          puVar4 = puVar4 + 0xef;
        } while (iVar6 != 0);
      }
    }
    iVar6 = param_1[1];
    local_40 = 0;
    if (0 < iVar6) {
      local_38 = 0xe4;
      local_30 = 0;
      local_3c = 0xb8;
      do {
        iVar11 = local_30 + *param_1;
        iVar7 = local_40 + 1;
        iVar13 = iVar7;
        iVar10 = local_30;
        if (iVar7 < iVar6) {
          do {
            iVar12 = iVar10 + 0x3bc + *param_1;
            iVar6 = *(int *)(iVar12 + 4) - *(int *)(iVar11 + 4);
            iVar8 = *(int *)(iVar12 + 8) - *(int *)(iVar11 + 8);
            sVar2 = FUN_005ee080(iVar6,iVar8);
            uVar5 = *(undefined4 *)(&DAT_006d31c8 + (sVar2 + 8 >> 4 & 0xfffU) * 4);
            uVar1 = *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar2 >> 4 & 0xfffU) * 4);
            *(short *)(iVar11 + 0xb8 + (iVar13 + param_1[2] * 0xb) * 2) =
                 sVar2 - *(short *)(iVar11 + 0x34);
            *(short *)(iVar12 + 0xb8 + (local_40 + param_1[2] * 0xb) * 2) =
                 (sVar2 - *(short *)(iVar12 + 0x34)) + -0x8000;
            uVar5 = FUN_005edfb0(iVar6,uVar5,iVar8,uVar1);
            *(undefined4 *)(iVar12 + 0xe4 + (local_40 + param_1[2] * 0xb) * 4) = uVar5;
            iVar6 = iVar13 + 1;
            *(undefined4 *)(iVar11 + 0xe4 + (iVar13 + param_1[2] * 0xb) * 4) = uVar5;
            iVar13 = iVar6;
            iVar10 = iVar10 + 0x3bc;
          } while (iVar6 < param_1[1]);
        }
        if (param_1[2] == 0) {
          local_4c = 0;
          *(undefined4 *)(iVar11 + 0x180) = 0x3e80000;
          *(undefined4 *)(iVar11 + 0x17c) = 0x3e80000;
          iVar6 = param_1[0x4e];
          if (0 < *(int *)(iVar6 + 0x790)) {
            local_40 = 0;
            local_44 = (int *)(iVar11 + 0x110);
            local_48 = (short *)(iVar11 + 0xce);
            do {
              iVar13 = *(int *)(iVar6 + 0x78c) + local_40;
              iVar10 = *(int *)(*(int *)(iVar6 + 0x78c) + 4 + local_40) - *(int *)(iVar11 + 4);
              iVar6 = *(int *)(iVar13 + 8) - *(int *)(iVar11 + 8);
              sVar2 = FUN_005ee080(iVar10,iVar6);
              uVar5 = *(undefined4 *)(&DAT_006d31c8 + (sVar2 + 8 >> 4 & 0xfffU) * 4);
              uVar1 = *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar2 >> 4 & 0xfffU) * 4);
              *local_48 = sVar2 - *(short *)(iVar11 + 0x34);
              *(short *)(local_3c + iVar13) = (sVar2 - *(short *)(iVar13 + 0x34)) + -0x8000;
              iVar10 = FUN_005edfb0(iVar10,uVar5,iVar6,uVar1);
              *(int *)(local_38 + iVar13) = iVar10;
              *local_44 = iVar10;
              iVar6 = *(int *)(iVar11 + 0x17c);
              if (iVar10 <= *(int *)(iVar11 + 0x17c)) {
                iVar6 = iVar10;
              }
              *(int *)(iVar11 + 0x17c) = iVar6;
              iVar6 = *(int *)(iVar13 + 0x17c);
              if (iVar10 <= *(int *)(iVar13 + 0x17c)) {
                iVar6 = iVar10;
              }
              *(int *)(iVar13 + 0x17c) = iVar6;
              uVar3 = (uint)*(short *)(iVar11 + 0xb8 +
                                      (*(int *)(iVar13 + 0x2c4) + *(int *)(iVar13 + 0x2b8) * 0xb) *
                                      2);
              uVar9 = (int)uVar3 >> 0x1f;
              if ((int)((uVar3 ^ uVar9) - uVar9) < 0x2e39) {
                iVar6 = *(int *)(iVar11 + 0x180);
                if (iVar10 <= *(int *)(iVar11 + 0x180)) {
                  iVar6 = iVar10;
                }
                *(int *)(iVar11 + 0x180) = iVar6;
              }
              uVar3 = (uint)*(short *)(iVar13 + 0xb8 +
                                      (*(int *)(iVar11 + 0x2b8) * 0xb + *(int *)(iVar11 + 0x2c4)) *
                                      2);
              uVar9 = (int)uVar3 >> 0x1f;
              if ((int)((uVar3 ^ uVar9) - uVar9) < 0x2e39) {
                iVar6 = *(int *)(iVar13 + 0x180);
                if (iVar10 <= *(int *)(iVar13 + 0x180)) {
                  iVar6 = iVar10;
                }
                *(int *)(iVar13 + 0x180) = iVar6;
              }
              local_48 = local_48 + 1;
              local_4c = local_4c + 1;
              iVar6 = param_1[0x4e];
              local_44 = local_44 + 1;
              local_40 = local_40 + 0x3bc;
            } while (local_4c < *(int *)(iVar6 + 0x790));
          }
        }
        iVar6 = param_1[1];
        local_38 = local_38 + 4;
        local_3c = local_3c + 2;
        local_30 = local_30 + 0x3bc;
        local_40 = iVar7;
      } while (iVar7 < iVar6);
    }
    FUN_005b8a60();
  }
  return;
}


