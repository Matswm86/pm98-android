// FUN_005f3b80  entry=005f3b80  size=1147 bytes

char __thiscall
FUN_005f3b80(int *param_1,int *param_2,undefined4 param_3,int *param_4,undefined4 param_5)

{
  bool bVar1;
  char cVar2;
  int iVar3;
  undefined4 uVar4;
  uint uVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  undefined4 uVar9;
  uint uVar10;
  undefined2 extraout_var_01;
  undefined2 extraout_var_02;
  int iVar11;
  char local_49;
  int local_48;
  int local_44;
  int local_40;
  int local_3c;
  int local_38;
  int local_34;
  int local_30;
  int local_2c;
  int local_28;
  int local_24;
  int local_20;
  int local_1c;
  int local_18;
  int local_14;
  int local_10;
  int local_c;
  int local_8;
  int local_4;
  
  local_44 = param_2[1];
  local_48 = *param_2;
  local_40 = param_2[2];
  local_3c = *param_4;
  local_38 = param_4[1];
  local_34 = param_4[2];
  iVar3 = param_1[0x17];
  iVar6 = param_1[0x16];
  local_49 = '\0';
  iVar8 = iVar6;
  if (iVar3 <= iVar6) {
    iVar8 = iVar3;
  }
  iVar11 = param_1[0x15];
  if ((iVar8 <= iVar11) && (iVar11 = iVar6, iVar3 <= iVar6)) {
    iVar11 = iVar3;
  }
  iVar3 = FUN_005edf90(param_3,iVar11);
  local_28 = 0x70000000;
  local_2c = 0x70000000;
  local_30 = 0x70000000;
  local_1c = -0x70000000;
  local_20 = -0x70000000;
  local_24 = -0x70000000;
  local_44 = local_44 - param_1[0x11];
  local_48 = local_48 - param_1[0x10];
  local_40 = local_40 - param_1[0x12];
  uVar9 = CONCAT22((short)((uint)param_1[0x10] >> 0x10),-(short)param_1[0x14]);
  uVar4 = CONCAT22((short)((uint)param_1[0x11] >> 0x10),-*(short *)((int)param_1 + 0x4e));
  FUN_005ee670(CONCAT22((short)((uint)param_1[0x12] >> 0x10),-(short)param_1[0x13]));
  FUN_005ee6e0(uVar4);
  FUN_005ee750(uVar9);
  local_48 = FUN_005edf90(local_48,param_1[0x15]);
  local_44 = FUN_005edf90(local_44,param_1[0x16]);
  local_40 = FUN_005edf90(local_40,param_1[0x17]);
  uVar10 = (uint)(ushort)-(short)param_1[0x14];
  uVar5 = (uint)(ushort)-*(short *)((int)param_1 + 0x4e);
  FUN_005ee670(-(short)param_1[0x13]);
  FUN_005ee6e0(uVar5);
  FUN_005ee750(uVar10);
  local_3c = FUN_005edf90(local_3c,param_1[0x15]);
  local_38 = FUN_005edf90(local_38,param_1[0x16]);
  local_34 = FUN_005edf90(local_34,param_1[0x17]);
  if (local_48 < local_30) {
    local_30 = local_48;
  }
  if (local_44 < local_2c) {
    local_2c = local_44;
  }
  if (local_40 < local_28) {
    local_28 = local_40;
  }
  if (local_24 < local_48) {
    local_24 = local_48;
  }
  if (local_20 < local_44) {
    local_20 = local_44;
  }
  if (local_1c < local_40) {
    local_1c = local_40;
  }
  iVar6 = local_34 + local_40;
  iVar8 = local_48 + local_3c;
  iVar11 = local_44 + local_38;
  if (iVar8 < local_30) {
    local_30 = iVar8;
  }
  if (iVar11 < local_2c) {
    local_2c = iVar11;
  }
  if (iVar6 < local_28) {
    local_28 = iVar6;
  }
  if (local_24 < iVar8) {
    local_24 = iVar8;
  }
  if (local_20 < iVar11) {
    local_20 = iVar11;
  }
  if (local_1c < iVar6) {
    local_1c = iVar6;
  }
  local_30 = local_30 - iVar3;
  local_2c = local_2c - iVar3;
  local_28 = local_28 - iVar3;
  FUN_00590b10(iVar3);
  iVar6 = param_1[1];
  iVar8 = *param_1;
  do {
    if (iVar6 == 0) {
      if (local_49 != '\0') {
        local_48 = FUN_005edfa0(local_48,param_1[0x15]);
        local_44 = FUN_005edfa0(local_44,param_1[0x16]);
        local_40 = FUN_005edfa0(local_40,param_1[0x17]);
        uVar4 = CONCAT22(extraout_var,*(undefined2 *)((int)param_1 + 0x4e));
        uVar5 = (uint)*(ushort *)(param_1 + 0x13);
        FUN_005ee750(CONCAT22(extraout_var_01,(short)param_1[0x14]));
        FUN_005ee6e0(uVar4);
        FUN_005ee670(uVar5);
        local_48 = local_48 + param_1[0x10];
        local_44 = local_44 + param_1[0x11];
        local_40 = local_40 + param_1[0x12];
        local_3c = FUN_005edfa0(local_3c,param_1[0x15]);
        local_38 = FUN_005edfa0(local_38,param_1[0x16]);
        local_34 = FUN_005edfa0(local_34,param_1[0x17]);
        uVar4 = CONCAT22(extraout_var_00,*(undefined2 *)((int)param_1 + 0x4e));
        uVar5 = (uint)*(ushort *)(param_1 + 0x13);
        FUN_005ee750(CONCAT22(extraout_var_02,(short)param_1[0x14]));
        FUN_005ee6e0(uVar4);
        FUN_005ee670(uVar5);
        *param_2 = local_48;
        param_2[1] = local_44;
        param_2[2] = local_40;
        *param_4 = local_3c;
        param_4[1] = local_38;
        param_4[2] = local_34;
      }
      return local_49;
    }
    iVar6 = iVar6 + -1;
    iVar11 = *(int *)(*(int *)(iVar8 + 0x108) + param_1[2] * 0xc);
    local_18 = *(int *)(iVar11 + 0x1c + param_1[3] * 0x34);
    iVar11 = iVar11 + 0x1c + param_1[3] * 0x34;
    local_14 = *(int *)(iVar11 + 4);
    local_10 = *(int *)(iVar11 + 8);
    FUN_00590ac0(iVar11 + 0xc);
    iVar11 = local_30;
    if (local_30 <= local_18) {
      iVar11 = local_18;
    }
    iVar7 = local_24;
    if (local_c <= local_24) {
      iVar7 = local_c;
    }
    if (iVar11 < iVar7) {
      iVar11 = local_2c;
      if (local_2c <= local_14) {
        iVar11 = local_14;
      }
      iVar7 = local_20;
      if (local_8 <= local_20) {
        iVar7 = local_8;
      }
      if (iVar7 <= iVar11) goto LAB_005f3e80;
      iVar11 = local_28;
      if (local_28 <= local_10) {
        iVar11 = local_10;
      }
      iVar7 = local_1c;
      if (local_4 <= local_1c) {
        iVar7 = local_4;
      }
      if (iVar7 <= iVar11) goto LAB_005f3e80;
      bVar1 = true;
    }
    else {
LAB_005f3e80:
      bVar1 = false;
    }
    if ((bVar1) &&
       (cVar2 = FUN_005f3850(&local_48,iVar3,&local_3c,param_5,&local_30), cVar2 != '\0')) {
      local_49 = '\x01';
      iVar6 = 0;
    }
    iVar8 = iVar8 + 0x13c;
  } while( true );
}


