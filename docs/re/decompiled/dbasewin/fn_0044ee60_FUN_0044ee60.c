// FUN_0044ee60  entry=0044ee60  size=783 bytes

undefined1 __thiscall
FUN_0044ee60(void *this,int param_1,int param_2,int param_3,int param_4,int *param_5,int param_6,
            int param_7)

{
  byte bVar1;
  bool bVar2;
  uint uVar3;
  int *piVar4;
  int *piVar5;
  undefined4 uVar6;
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
  
  piVar4 = param_5;
  param_6 = param_6 + param_5[0xe];
  param_7 = param_7 + param_5[0xf];
  local_4 = this;
  FUN_004063b0(&param_6,param_5 + 10);
  piVar5 = (int *)FUN_0044f9d0(&param_1,(int *)((int)this + 0x38));
  local_14 = *piVar5;
  local_10 = piVar5[1];
  FUN_0044f980(&param_1,(int *)((int)this + 0x28));
  local_14 = local_14 - param_1;
  local_10 = local_10 - param_2;
  FUN_0044f940(&param_6,&local_14);
  uVar6 = FUN_0044f960(&param_1);
  if ((char)uVar6 != '\0') {
    if (*(int *)((int)this + 0x20) == piVar4[8]) {
      if (((*(int *)this == 0) && (*(int *)((int)this + 0x40) == 0)) ||
         (uVar6 = FUN_0044e8b0(this), (char)uVar6 != '\0')) {
        bVar2 = true;
      }
      else {
        bVar2 = false;
      }
      if (bVar2) {
        if (((*piVar4 == 0) && (piVar4[0x10] == 0)) ||
           (uVar6 = FUN_0044e8b0(piVar4), (char)uVar6 != '\0')) {
          bVar2 = true;
        }
        else {
          bVar2 = false;
        }
        if (bVar2) {
          iVar7 = (param_3 - param_1) + param_6;
          local_14 = param_6;
          if (iVar7 <= param_6) {
            local_14 = iVar7;
          }
          local_c = param_6;
          if (param_6 <= iVar7) {
            local_c = iVar7;
          }
          iVar7 = (param_4 - param_2) + param_7;
          local_10 = param_7;
          if (iVar7 <= param_7) {
            local_10 = iVar7;
          }
          local_8 = param_7;
          if (param_7 <= iVar7) {
            local_8 = iVar7;
          }
          iVar7 = (**(code **)(**(int **)((int)this + 4) + 0x14))
                            (*(int **)((int)this + 4),&param_1,piVar4[1],&local_14,
                             -(uint)(piVar4[9] != -1) & 0x8000 | 0x1000000,0);
          if (-1 < iVar7) {
            return 1;
          }
        }
      }
      return 0;
    }
    if (piVar4[8] == 8) {
      if (*(int *)this == 0) {
        FUN_0044e840(this);
      }
      if (*piVar4 == 0) {
        FUN_0044e840(piVar4);
      }
      puVar12 = (undefined2 *)(param_2 * *(int *)((int)this + 0x1c) + param_1 * 2 + *(int *)this);
      pbVar11 = (byte *)(param_7 * piVar4[7] + *piVar4 + param_6);
      local_14 = *(int *)(&DAT_00495820 + *(int *)((int)this + 0x20) * 4);
      if (piVar4[9] == -1) {
        for (iVar7 = param_4 - param_2; iVar7 != 0; iVar7 = iVar7 + -1) {
          pbVar10 = pbVar11;
          puVar9 = puVar12;
          for (iVar8 = param_3 - param_1; iVar8 != 0; iVar8 = iVar8 + -1) {
            bVar1 = *pbVar10;
            pbVar10 = pbVar10 + 1;
            *puVar9 = *(undefined2 *)(local_14 + (uint)bVar1 * 2);
            this = local_4;
            puVar9 = puVar9 + 1;
          }
          puVar12 = (undefined2 *)((int)puVar12 + *(int *)((int)this + 0x1c));
          pbVar11 = pbVar11 + param_5[7];
        }
      }
      else {
        for (iVar7 = param_4 - param_2; iVar7 != 0; iVar7 = iVar7 + -1) {
          pbVar10 = pbVar11;
          puVar9 = puVar12;
          for (iVar8 = param_3 - param_1; iVar8 != 0; iVar8 = iVar8 + -1) {
            bVar1 = *pbVar10;
            pbVar10 = pbVar10 + 1;
            uVar3 = (uint)local_4 >> 8;
            local_4 = (int *)CONCAT31((int3)uVar3,bVar1);
            if (bVar1 != 0) {
              *puVar9 = *(undefined2 *)(local_14 + (uint)bVar1 * 2);
            }
            puVar9 = puVar9 + 1;
          }
          puVar12 = (undefined2 *)((int)puVar12 + *(int *)((int)this + 0x1c));
          pbVar11 = pbVar11 + param_5[7];
        }
      }
      if ((*(int *)this != 0) || (*(int *)((int)this + 0x40) != 0)) {
        FUN_0044e8b0(this);
      }
    }
  }
  return 1;
}


