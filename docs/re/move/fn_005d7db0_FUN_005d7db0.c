// FUN_005d7db0  entry=005d7db0  size=1269 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __thiscall
FUN_005d7db0(int *param_1,int *param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5,
            int param_6)

{
  float fVar1;
  undefined4 uVar2;
  int iVar3;
  int *piVar4;
  int *piVar5;
  int iVar6;
  int *piVar7;
  float local_ac;
  float local_a8;
  float local_a4;
  float local_a0;
  float local_9c;
  float local_98;
  float local_94;
  float local_90;
  float local_8c;
  float local_88;
  float local_84;
  float local_80;
  float local_7c;
  float local_78;
  float local_74;
  float local_70;
  float local_6c;
  float local_68;
  float local_64;
  int local_60 [4];
  int iStack_50;
  int iStack_4c;
  int iStack_48;
  int iStack_44;
  int iStack_40;
  undefined4 local_30;
  int iStack_2c;
  int iStack_28;
  int iStack_24;
  int iStack_20;
  undefined4 uStack_1c;
  float fStack_18;
  undefined4 uStack_14;
  float fStack_10;
  undefined4 uStack_c;
  undefined4 uStack_8;
  
  *(short *)(param_1 + 0x37) = (short)param_3;
  *(short *)((int)param_1 + 0xde) = (short)param_4;
  *(short *)(param_1 + 0x38) = (short)param_5;
  param_1[0x40] = param_6;
  param_1[0x39] = *param_2;
  param_1[0x3a] = param_2[1];
  param_1[0x3b] = param_2[2];
  FUN_00436fb0((param_1[0x44] + param_1[0x42]) / 2,(param_1[0x43] + param_1[0x45]) / 2);
  param_1[0x3c] = (int)local_ac;
  param_1[0x3d] = (int)local_a8;
  FUN_005eeba0(param_2,param_3,param_4,param_5);
  local_ac = (float)(param_1[0x44] - param_1[0x42]);
  uVar2 = ftol(param_1[0x40]);
  iVar3 = FUN_005edfa0(uVar2);
  piVar5 = param_1 + 0x1f;
  piVar4 = local_60;
  piVar7 = piVar5;
  for (iVar6 = 0xc; iVar6 != 0; iVar6 = iVar6 + -1) {
    *piVar7 = *piVar4;
    piVar4 = piVar4 + 1;
    piVar7 = piVar7 + 1;
  }
  param_1[0x3f] = iVar3;
  param_1[0x3e] = iVar3;
  uVar2 = FUN_005eea50(0x10000,iVar3,iVar3);
  piVar4 = (int *)FUN_005ee800(&local_a0,uVar2);
  piVar7 = piVar5;
  for (iVar3 = 0xc; iVar3 != 0; iVar3 = iVar3 + -1) {
    *piVar7 = *piVar4;
    piVar4 = piVar4 + 1;
    piVar7 = piVar7 + 1;
  }
  piVar4 = param_1 + 0x2b;
  piVar7 = param_1 + 0x13;
  for (iVar3 = 0xc; iVar3 != 0; iVar3 = iVar3 + -1) {
    *piVar7 = *piVar4;
    piVar4 = piVar4 + 1;
    piVar7 = piVar7 + 1;
  }
  piVar5 = (int *)FUN_005ee800(&local_a0,piVar5);
  piVar4 = param_1 + 0x13;
  for (iVar3 = 0xc; iVar3 != 0; iVar3 = iVar3 + -1) {
    *piVar4 = *piVar5;
    piVar5 = piVar5 + 1;
    piVar4 = piVar4 + 1;
  }
  *(undefined1 *)((int)param_1 + 0x186) = 1;
  if (param_1[0x5c] != 0) {
    fVar1 = (float)param_1[0x41] * (float)_DAT_00639ae8;
    local_a4 = (float)param_1[0x40] * (float)_DAT_00639ae8;
    local_ac = fVar1 - local_a4;
    local_a0 = local_a4 + local_a4;
    local_78 = fVar1 / local_ac;
    local_68 = -(fVar1 * local_a4) / local_ac;
    local_74 = (float)_DAT_00639adc;
    local_64 = _DAT_00639ad8;
    local_6c = _DAT_00639ad8;
    local_70 = _DAT_00639ad8;
    local_7c = _DAT_00639ad8;
    local_80 = _DAT_00639ad8;
    local_84 = _DAT_00639ad8;
    local_88 = _DAT_00639ad8;
    local_90 = _DAT_00639ad8;
    local_94 = _DAT_00639ad8;
    local_98 = _DAT_00639ad8;
    local_9c = _DAT_00639ad8;
    local_8c = local_a0;
    if ((*param_1 != 0) || (param_1[0x10] != 0)) {
      FUN_005cb320();
    }
    (**(code **)(*(int *)param_1[0x5c] + 0x68))((int *)param_1[0x5c],3,&local_a0);
    local_ac = (float)-(int)local_68 * (float)_DAT_00639ae8;
    local_a8 = (float)(int)local_64 * (float)_DAT_00639ae8;
    local_a4 = (float)(int)local_6c * (float)_DAT_00639ae8;
    local_9c = (float)-local_60[1] * (float)_DAT_00639ae8;
    local_98 = (float)local_60[2] * (float)_DAT_00639ae8;
    local_94 = (float)local_60[0] * (float)_DAT_00639ae8;
    local_8c = (float)-iStack_50 * (float)_DAT_00639ae8;
    local_88 = (float)iStack_4c * (float)_DAT_00639ae8;
    local_84 = (float)local_60[3] * (float)_DAT_00639ae8;
    local_7c = (float)-iStack_44 * (float)_DAT_00639ae8;
    local_78 = (float)iStack_40 * (float)_DAT_00639ae8;
    local_74 = (float)iStack_48 * (float)_DAT_00639ae8;
    local_80 = _DAT_00639ad8;
    local_90 = _DAT_00639ad8;
    local_a0 = _DAT_00639ad8;
    local_70 = (float)_DAT_00639adc;
    (**(code **)(*(int *)param_1[0x5c] + 0x68))((int *)param_1[0x5c],2,&local_ac);
  }
  piVar5 = (int *)param_1[0x5d];
  if (piVar5 != (int *)0x0) {
    iStack_20 = param_1[0x43];
    iStack_24 = param_1[0x42];
    local_ac = (float)(param_1[0x44] - iStack_24);
    iStack_2c = param_1[0xe] + iStack_24;
    fStack_18 = (float)(param_1[0x45] - iStack_20) / (float)(int)local_ac;
    iStack_28 = iStack_20 + param_1[0xf];
    iStack_20 = param_1[0x45] - iStack_20;
    iStack_24 = param_1[0x44] - iStack_24;
    local_30 = 0x2c;
    uStack_1c = 0xbf800000;
    uStack_14 = 0x40000000;
    uStack_c = 0;
    uStack_8 = 0x3f800000;
    fStack_10 = fStack_18 + fStack_18;
    (**(code **)(*piVar5 + 0x44))(piVar5,&local_30);
  }
  return;
}


