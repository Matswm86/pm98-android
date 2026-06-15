// FUN_005e81c0  entry=005e81c0  size=1490 bytes

bool __fastcall FUN_005e81c0(int *param_1)

{
  uint uVar1;
  int *piVar2;
  undefined4 uVar3;
  uint uVar4;
  int iVar5;
  DWORD DVar6;
  undefined4 uVar7;
  bool bVar8;
  byte local_ee;
  byte local_ed;
  int local_ec;
  undefined4 local_e8;
  int local_e4;
  undefined4 local_e0;
  undefined1 local_dc [20];
  byte local_c8 [2];
  undefined2 local_c6;
  undefined2 uStack_c4;
  undefined2 uStack_c2;
  undefined4 local_c0;
  undefined4 local_bc;
  undefined4 local_b8;
  undefined4 local_b4;
  undefined4 local_b0;
  undefined4 local_ac;
  undefined4 local_a8;
  int local_a4;
  uint local_a0;
  undefined1 local_9c [20];
  uint local_88;
  undefined4 local_84;
  undefined1 local_80 [16];
  HLOCAL local_70;
  undefined1 local_6c [16];
  HLOCAL local_5c;
  undefined1 local_58 [20];
  byte local_44;
  undefined2 local_42;
  undefined2 local_40;
  undefined4 local_3c;
  undefined4 local_38;
  undefined4 local_34;
  uint local_30;
  undefined1 local_2c [20];
  uint local_18;
  undefined4 local_14;
  uint local_10;
  void *local_c;
  undefined1 *puStack_8;
  uint local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00621f50;
  local_c = ExceptionList;
  local_ec = 0;
  local_ee = 0;
  ExceptionList = &local_c;
  FUN_005e6750();
  local_4 = 0;
  FUN_005e6750();
  local_4 = CONCAT31(local_4._1_3_,1);
  FUN_005e7df0();
  DAT_006dc4d0 = 0;
  do {
    piVar2 = param_1 + 0x32;
    iVar5 = FUN_005f9a70(&local_ee,1);
    if (iVar5 == 0) break;
    switch(local_ee & 7) {
    case 1:
      FUN_005e6450(&DAT_00666f70);
      local_88 = 0;
      local_84 = 0;
      if ((param_1[0x33] == 0) || (param_1[0x33] == -1)) {
        DVar6 = SetFilePointer((HANDLE)*piVar2,0,(PLONG)0x0,1);
      }
      else {
        DVar6 = param_1[0x36];
      }
      uVar1 = DVar6 - 1;
      if (param_1[0x44] == 0) {
        param_1[0x45] = uVar1;
        if ((uint)param_1[0x40] <= uVar1) {
          param_1[0x40] = uVar1;
          param_1[0x41] = DVar6 + 0xe7;
        }
        param_1[0x3f] = param_1[0x3f] + 1;
      }
      iVar5 = FUN_005e6490(piVar2);
      if ((iVar5 != 0) && (iVar5 = FUN_005f9a70(&local_88,4), iVar5 != 0)) {
        FUN_005f9a70(&local_84,4);
      }
      uVar7 = local_84;
      uVar4 = local_88;
      if ((uint)param_1[0x49] <= local_88) {
        param_1[0x49] = local_88 + 1;
      }
      if ((local_ee & 0x80) == 0) {
        FUN_005e6450(local_9c);
        local_18 = uVar4;
        local_14 = uVar7;
        local_10 = uVar1;
        uVar7 = FUN_005ea820(local_2c);
        FUN_005ea710(uVar7,local_2c,1);
        param_1[0x3d] = param_1[0x3d] + 1;
      }
      else {
        uVar7 = FUN_005ea3a0(uVar1);
        FUN_005ea2e0(uVar7,uVar1,1);
        param_1[0x38] = param_1[0x38] + 0x1d;
      }
      iVar5 = param_1[0x44];
      param_1[0x44] = iVar5 + 1U;
      if (7 < iVar5 + 1U) {
        param_1[0x44] = 0;
      }
      break;
    case 2:
      FUN_005e6450(&DAT_00666f70);
      local_c8[0] = 0;
      local_c6 = 0;
      uStack_c4 = 0;
      local_c0 = 0;
      local_bc = 0;
      local_b8 = 0;
      if ((param_1[0x33] == 0) || (param_1[0x33] == -1)) {
        DVar6 = SetFilePointer((HANDLE)*piVar2,0,(PLONG)0x0,1);
      }
      else {
        DVar6 = param_1[0x36];
      }
      uVar1 = DVar6 - 1;
      if (param_1[0x42] == 0) {
        param_1[0x43] = uVar1;
        if ((uint)param_1[0x40] <= uVar1) {
          param_1[0x40] = uVar1;
          param_1[0x41] = DVar6 + 0x4bf;
        }
        param_1[0x3f] = param_1[0x3f] + 1;
      }
      iVar5 = FUN_005e6490(piVar2);
      if ((((iVar5 != 0) && (iVar5 = FUN_005f9a70(local_c8,1), iVar5 != 0)) &&
          (iVar5 = FUN_005f9a70(&local_c6,2), iVar5 != 0)) &&
         ((iVar5 = FUN_005f9a70(&uStack_c4,2), iVar5 != 0 &&
          (iVar5 = FUN_005e87b0(piVar2), iVar5 != 0)))) {
        FUN_005f9a70(&local_b8,4);
      }
      uVar3 = local_b8;
      uVar7 = local_bc;
      if ((local_ee & 0x80) == 0) {
        if (*(byte *)(param_1 + 0x48) <= local_c8[0]) {
          *(byte *)(param_1 + 0x48) = local_c8[0];
        }
        local_b4 = CONCAT22(uStack_c2,uStack_c4);
        local_ac = local_c0;
        local_b0 = CONCAT22(uStack_c4,local_c6);
        local_ed = local_c8[0];
        FUN_005e6450(local_dc);
        local_42 = (undefined2)local_b0;
        local_44 = local_ed;
        local_40 = (undefined2)local_b4;
        local_3c = local_ac;
        local_38 = uVar7;
        local_34 = uVar3;
        local_30 = uVar1;
        uVar7 = FUN_005eaa20(local_58);
        FUN_005ea8e0(uVar7,local_58,1);
        param_1[0x3c] = param_1[0x3c] + 1;
      }
      else {
        uVar7 = FUN_005ea3a0(uVar1);
        FUN_005ea2e0(uVar7,uVar1,1);
        param_1[0x38] = param_1[0x38] + 0x26;
      }
      iVar5 = param_1[0x42];
      param_1[0x42] = iVar5 + 1U;
      if (0x1f < iVar5 + 1U) {
        param_1[0x42] = 0;
      }
      break;
    case 3:
      local_e8 = 0;
      local_e4 = 0;
      if ((param_1[0x33] == 0) || (param_1[0x33] == -1)) {
        DVar6 = SetFilePointer((HANDLE)*piVar2,0,(PLONG)0x0,1);
      }
      else {
        DVar6 = param_1[0x36];
      }
      uVar1 = DVar6 - 1;
      if (param_1[0x46] == 0) {
        param_1[0x47] = uVar1;
        if ((uint)param_1[0x40] <= uVar1) {
          param_1[0x40] = uVar1;
          param_1[0x41] = DVar6 + 0x8f;
        }
        param_1[0x3f] = param_1[0x3f] + 1;
      }
      iVar5 = FUN_005f9a70(&local_e8,4);
      if (iVar5 != 0) {
        FUN_005f9a70(&local_e4,4);
      }
      if ((local_ee & 0x80) == 0) {
        local_a8 = local_e8;
        local_a4 = local_e4;
        local_a0 = uVar1;
        uVar7 = FUN_005ea650(&local_a8);
        FUN_005ea450(uVar7,&local_a8,1);
        param_1[0x38] = param_1[0x38] + local_e4;
        param_1[0x3e] = param_1[0x3e] + 1;
      }
      else {
        uVar7 = FUN_005ea3a0(uVar1);
        FUN_005ea2e0(uVar7,uVar1,1);
        param_1[0x38] = param_1[0x38] + 9;
      }
      iVar5 = param_1[0x46];
      param_1[0x46] = iVar5 + 1U;
      if (0xf < iVar5 + 1U) {
        param_1[0x46] = 0;
      }
      break;
    case 4:
      FUN_005f9a70(&local_e0,4);
      FUN_005f9ae0(local_e0,0);
      break;
    default:
      DAT_006dc4d0 = 0xc;
      (**(code **)(*param_1 + 4))(0xc,param_1 + 1,0,0);
    case 5:
      local_ec = 1;
    }
  } while (local_ec == 0);
  FUN_005e7e60(local_6c,param_1 + 0x21);
  FUN_005e8020(local_80,param_1 + 0x21);
  bVar8 = DAT_006dc4d0 == 0;
  local_4 = local_4 & 0xffffff00;
  if (local_70 != (HLOCAL)0x0) {
    LocalFree(local_70);
    local_70 = (HLOCAL)0x0;
  }
  local_4 = 0xffffffff;
  if (local_5c != (HLOCAL)0x0) {
    LocalFree(local_5c);
  }
  ExceptionList = local_c;
  return bVar8;
}


