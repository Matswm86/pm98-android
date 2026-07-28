// FUN_005cba50  entry=005cba50  size=783 bytes

undefined4 __thiscall
FUN_005cba50(int *param_1,int param_2,int param_3,int param_4,int param_5,int *param_6,int param_7,
            int param_8)

{
  byte bVar1;
  uint uVar2;
  int *piVar3;
  char cVar4;
  bool bVar5;
  int *piVar6;
  int iVar7;
  int iVar8;
  undefined2 *puVar9;
  byte *pbVar10;
  byte *pbVar11;
  undefined2 *puVar12;
  int local_14;
  int local_10;
  int local_c;
  int local_8;
  int *local_4;
  
  piVar3 = param_6;
  param_7 = param_7 + param_6[0xe];
  param_8 = param_8 + param_6[0xf];
  local_4 = param_1;
  FUN_005d41f0(param_6 + 10);
  piVar6 = (int *)FUN_00495f20(param_1 + 0xe);
  local_14 = *piVar6;
  local_10 = piVar6[1];
  FUN_005c3410(param_1 + 10);
  local_14 = local_14 - param_2;
  local_10 = local_10 - param_3;
  FUN_005d4220(&local_14);
  cVar4 = FUN_005d4240();
  if (cVar4 != '\0') {
    if (param_1[8] == piVar3[8]) {
      if (((*param_1 == 0) && (param_1[0x10] == 0)) || (cVar4 = FUN_005cb320(), cVar4 != '\0')) {
        bVar5 = true;
      }
      else {
        bVar5 = false;
      }
      if (bVar5) {
        if (((*piVar3 == 0) && (piVar3[0x10] == 0)) || (cVar4 = FUN_005cb320(), cVar4 != '\0')) {
          bVar5 = true;
        }
        else {
          bVar5 = false;
        }
        if (bVar5) {
          iVar7 = (param_4 - param_2) + param_7;
          local_14 = param_7;
          if (iVar7 <= param_7) {
            local_14 = iVar7;
          }
          local_c = param_7;
          if (param_7 <= iVar7) {
            local_c = iVar7;
          }
          iVar7 = (param_5 - param_3) + param_8;
          local_10 = param_8;
          if (iVar7 <= param_8) {
            local_10 = iVar7;
          }
          local_8 = param_8;
          if (param_8 <= iVar7) {
            local_8 = iVar7;
          }
          iVar7 = (**(code **)(*(int *)param_1[1] + 0x14))
                            ((int *)param_1[1],&param_2,piVar3[1],&local_14,
                             -(uint)(piVar3[9] != -1) & 0x8000 | 0x1000000,0);
          if (-1 < iVar7) {
            return 1;
          }
        }
      }
      return 0;
    }
    if (piVar3[8] == 8) {
      if (*param_1 == 0) {
        FUN_005cb2b0();
      }
      if (*piVar3 == 0) {
        FUN_005cb2b0();
      }
      puVar12 = (undefined2 *)(param_3 * param_1[7] + param_2 * 2 + *param_1);
      pbVar11 = (byte *)(param_8 * piVar3[7] + param_7 + *piVar3);
      local_14 = *(int *)(&DAT_00665b00 + param_1[8] * 4);
      if (piVar3[9] == -1) {
        for (iVar7 = param_5 - param_3; iVar7 != 0; iVar7 = iVar7 + -1) {
          pbVar10 = pbVar11;
          puVar9 = puVar12;
          for (iVar8 = param_4 - param_2; iVar8 != 0; iVar8 = iVar8 + -1) {
            bVar1 = *pbVar10;
            pbVar10 = pbVar10 + 1;
            *puVar9 = *(undefined2 *)(local_14 + (uint)bVar1 * 2);
            param_1 = local_4;
            puVar9 = puVar9 + 1;
          }
          puVar12 = (undefined2 *)((int)puVar12 + param_1[7]);
          pbVar11 = pbVar11 + param_6[7];
        }
      }
      else {
        for (iVar7 = param_5 - param_3; iVar7 != 0; iVar7 = iVar7 + -1) {
          pbVar10 = pbVar11;
          puVar9 = puVar12;
          for (iVar8 = param_4 - param_2; iVar8 != 0; iVar8 = iVar8 + -1) {
            bVar1 = *pbVar10;
            pbVar10 = pbVar10 + 1;
            uVar2 = (uint)local_4 >> 8;
            local_4 = (int *)CONCAT31((int3)uVar2,bVar1);
            if (bVar1 != 0) {
              *puVar9 = *(undefined2 *)(local_14 + (uint)bVar1 * 2);
            }
            puVar9 = puVar9 + 1;
          }
          puVar12 = (undefined2 *)((int)puVar12 + param_1[7]);
          pbVar11 = pbVar11 + param_6[7];
        }
      }
      if ((*param_1 != 0) || (param_1[0x10] != 0)) {
        FUN_005cb320();
      }
    }
  }
  return 1;
}


