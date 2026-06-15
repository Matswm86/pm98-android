// FUN_00470b70  entry=00470b70  size=2763 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_00470b70(int param_1,int param_2)

{
  ushort uVar1;
  undefined1 *puVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  int iVar5;
  undefined1 *puVar6;
  undefined1 *puVar7;
  undefined1 **local_1b0;
  undefined1 *local_19c;
  undefined4 local_198;
  undefined1 *local_194;
  undefined4 local_190;
  undefined1 *local_18c;
  int local_188;
  undefined1 *local_184;
  int local_180;
  undefined1 local_17c [16];
  undefined1 local_16c [76];
  undefined1 local_120 [76];
  undefined1 *local_d4 [50];
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0060b71c;
  local_c = ExceptionList;
  local_1b0 = (undefined1 **)(param_1 + 0x78);
  ExceptionList = &local_c;
  FUN_00437be0();
  local_1b0 = (undefined1 **)0x100;
  local_19c = &stack0xfffffe4c;
  FUN_00436270(0xffffff);
  FUN_0043ce50(local_17c);
  local_19c = (undefined1 *)&local_1b0;
  local_1b0 = (undefined1 **)0x0;
  FUN_0043ca50(local_17c);
  if (*(int *)(param_1 + 0x3fc) != 0) {
    local_1b0 = (undefined1 **)s_Proman12_00652eb0;
    FUN_005d9d50();
    local_19c = (undefined1 *)&local_1b0;
    *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffff9f;
    local_1b0 = *(undefined1 ***)(param_1 + 0x400);
    FUN_005d9d30();
    local_1b0 = (undefined1 **)s_STADIUM_00653e30;
    FUN_005e3c30();
    puVar2 = (undefined1 *)(0x6a - (int)local_194 / 2);
    puVar6 = local_194 + (int)puVar2;
    local_18c = puVar2;
    if ((int)puVar6 <= (int)puVar2) {
      local_18c = puVar6;
    }
    if ((int)puVar2 <= (int)puVar6) {
      puVar2 = puVar6;
    }
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      local_1b0 = (undefined1 **)0x100;
      FUN_005d9d80(s_STADIUM_00653e30,local_18c,0x47,puVar2);
    }
    else {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(s_STADIUM_00653e30,local_18c,0x47,puVar2,0x54);
    }
    local_19c = (undefined1 *)&local_1b0;
    local_1b0 = *(undefined1 ***)(param_1 + 0x404);
    FUN_005d9d30();
    local_1b0 = *(undefined1 ***)(param_1 + 0x3fc);
    FUN_005e3c30();
    local_184 = (undefined1 *)(0x6a - (int)local_194 / 2);
    puVar6 = local_194 + (int)local_184;
    puVar2 = local_184;
    if ((int)puVar6 <= (int)local_184) {
      puVar2 = puVar6;
    }
    if ((int)local_184 <= (int)puVar6) {
      local_184 = puVar6;
    }
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      local_1b0 = (undefined1 **)0x100;
      FUN_005d9d80(*(undefined4 *)(param_1 + 0x3fc),puVar2,0x54,local_184);
    }
    else {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(*(undefined4 *)(param_1 + 0x3fc),puVar2,0x54,local_184,99);
    }
  }
  if (*(int *)(param_1 + 0x3f8) != 0) {
    if (*(short *)(*(int *)(param_1 + 0x3f8) + 0x38) != 0) {
      local_1b0 = (undefined1 **)s_Proman12_00652eb0;
      FUN_005d9d50();
      local_1b0 = (undefined1 **)0x100;
      local_19c = &stack0xfffffe4c;
      FUN_00436270(0);
      uVar3 = FUN_00436fb0(0xc5,0x18);
      uVar4 = FUN_00436fb0(0xb,0x6e);
      uVar3 = FUN_00436fd0(uVar4,uVar3);
      FUN_0043ce50(uVar3);
      local_1b0 = (undefined1 **)0x100;
      local_19c = &stack0xfffffe4c;
      FUN_004ac740(param_1 + 0x408);
      uVar3 = FUN_00436fb0(0x9b,0x14);
      uVar4 = FUN_00436fb0(0xd,0x70);
      uVar3 = FUN_00436fd0(uVar4,uVar3);
      FUN_0043ce50(uVar3);
      local_1b0 = (undefined1 **)0x100;
      local_19c = &stack0xfffffe4c;
      FUN_004ac740(param_1 + 0x418);
      uVar3 = FUN_00436fb0(0x24,0x14);
      uVar4 = FUN_00436fb0(0xaa,0x70);
      uVar3 = FUN_00436fd0(uVar4,uVar3);
      FUN_0043ce50(uVar3);
      local_19c = (undefined1 *)&local_1b0;
      *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffffbf | 0x20;
      local_1b0 = *(undefined1 ***)(param_1 + 0x40c);
      FUN_005d9d30();
      local_1b0 = (undefined1 **)(uint)*(ushort *)(*(int *)(param_1 + 0x3f8) + 0x38);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x470ec8;
      uVar3 = FUN_00579390();
      if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
        local_1b0 = (undefined1 **)0x100;
        FUN_005d9d80(uVar3,0x12,0x70,0xa8);
      }
      else {
        local_1b0 = (undefined1 **)0x1;
        FUN_005da180(uVar3,0x12,0x70,0xa8,0x84);
      }
      if (*(int *)(param_1 + 0x3f4) != 0) {
        local_1b0 = (undefined1 **)(uint)*(byte *)(*(int *)(param_1 + 0x3f8) + 0x3c);
        sprintf((char *)local_d4,&DAT_00653bc4);
        local_1b0 = (undefined1 **)s_Proman14_00652ebc;
        FUN_005d9d50();
        local_1b0 = local_d4;
        FUN_005e3c30();
        local_1b0 = *(undefined1 ***)(param_1 + 0x41c);
        local_19c = (undefined1 *)&local_1b0;
        FUN_005d9d30();
        puVar2 = (undefined1 *)(0xbc - (int)local_194 / 2);
        puVar7 = local_194 + (int)puVar2;
        puVar6 = puVar2;
        if ((int)puVar7 <= (int)puVar2) {
          puVar6 = puVar7;
        }
        if ((int)puVar2 <= (int)puVar7) {
          puVar2 = puVar7;
        }
        local_1b0 = (undefined1 **)0x1;
        FUN_005da180(local_d4,puVar6,0x70,puVar2,0x84);
      }
    }
    if (*(short *)(*(int *)(param_1 + 0x3f8) + 0x3a) != 0) {
      local_1b0 = (undefined1 **)s_Proman12_00652eb0;
      FUN_005d9d50();
      local_1b0 = (undefined1 **)0x100;
      local_19c = &stack0xfffffe4c;
      FUN_00436270(0);
      uVar3 = FUN_00436fb0(0xc5,0x18);
      uVar4 = FUN_00436fb0(0xb,0x8d);
      uVar3 = FUN_00436fd0(uVar4,uVar3);
      FUN_0043ce50(uVar3);
      local_1b0 = (undefined1 **)0x100;
      local_19c = &stack0xfffffe4c;
      FUN_004ac740(param_1 + 0x410);
      uVar3 = FUN_00436fb0(0x9b,0x14);
      uVar4 = FUN_00436fb0(0xd,0x8f);
      uVar3 = FUN_00436fd0(uVar4,uVar3);
      FUN_0043ce50(uVar3);
      local_1b0 = (undefined1 **)0x100;
      local_19c = &stack0xfffffe4c;
      FUN_004ac740(param_1 + 0x420);
      uVar3 = FUN_00436fb0(0x24,0x14);
      uVar4 = FUN_00436fb0(0xaa,0x8f);
      uVar3 = FUN_00436fd0(uVar4,uVar3);
      FUN_0043ce50(uVar3);
      local_19c = (undefined1 *)&local_1b0;
      *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffffbf | 0x20;
      local_1b0 = *(undefined1 ***)(param_1 + 0x414);
      FUN_005d9d30();
      local_1b0 = (undefined1 **)(uint)*(ushort *)(*(int *)(param_1 + 0x3f8) + 0x3a);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x47112f;
      uVar3 = FUN_00579390();
      if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
        local_1b0 = (undefined1 **)0x100;
        FUN_005d9d80(uVar3,0x12,0x8f,0xa8);
      }
      else {
        local_1b0 = (undefined1 **)0x1;
        FUN_005da180(uVar3,0x12,0x8f,0xa8,0xa3);
      }
      if (*(int *)(param_1 + 0x3f4) != 0) {
        local_1b0 = (undefined1 **)(uint)*(byte *)(*(int *)(param_1 + 0x3f8) + 0x3d);
        sprintf((char *)local_d4,&DAT_00653bc4);
        local_1b0 = (undefined1 **)s_Proman14_00652ebc;
        FUN_005d9d50();
        local_1b0 = local_d4;
        FUN_005e3c30();
        local_1b0 = *(undefined1 ***)(param_1 + 0x424);
        local_19c = (undefined1 *)&local_1b0;
        FUN_005d9d30();
        puVar2 = (undefined1 *)(0xbc - (int)local_194 / 2);
        puVar7 = local_194 + (int)puVar2;
        puVar6 = puVar2;
        if ((int)puVar7 <= (int)puVar2) {
          puVar6 = puVar7;
        }
        if ((int)puVar2 <= (int)puVar7) {
          puVar2 = puVar7;
        }
        local_1b0 = (undefined1 **)0x1;
        FUN_005da180(local_d4,puVar6,0x8f,puVar2,0xa3);
      }
    }
  }
  iVar5 = *(int *)(param_1 + 0x3f8);
  if (iVar5 != 0) {
    if (*(short *)(iVar5 + 0x38) != 0) {
      local_1b0 = (undefined1 **)(uint)*(ushort *)(iVar5 + 0x38);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x47127f;
      iVar5 = FUN_005796f0();
      local_1b0 = (undefined1 **)0x47128a;
      FUN_005c9210();
      local_4 = 0;
      local_1b0 = (undefined1 **)0x47129d;
      FUN_005c9210();
      local_1b0 = (undefined1 **)0x100;
      local_4._0_1_ = 1;
      FUN_005d66f0();
      local_1b0 = (undefined1 **)0x100;
      FUN_005d6590(local_16c,0x20);
      local_19c = (undefined1 *)0x0;
      local_198 = 0;
      local_194 = (undefined1 *)0x0;
      local_190 = 0;
      local_184 = (undefined1 *)(0x21 - *(int *)(iVar5 + 0x14) / 2);
      puVar2 = local_184 + *(int *)(iVar5 + 0x14);
      local_180 = 0x20 - *(int *)(iVar5 + 0x18) / 2;
      local_18c = local_184;
      if ((int)puVar2 <= (int)local_184) {
        local_18c = puVar2;
      }
      if ((int)local_184 <= (int)puVar2) {
        local_184 = puVar2;
      }
      iVar5 = *(int *)(iVar5 + 0x18) + local_180;
      local_188 = local_180;
      if (iVar5 <= local_180) {
        local_188 = iVar5;
      }
      if (local_180 <= iVar5) {
        local_180 = iVar5;
      }
      local_1b0 = &local_19c;
      FUN_005d5220(&local_18c,local_120,&local_194);
      local_4 = (uint)local_4._1_3_ << 8;
      local_1b0 = (undefined1 **)0x47136d;
      thunk_FUN_005cb040();
      local_4 = 0xffffffff;
      local_1b0 = (undefined1 **)0x471381;
      thunk_FUN_005cb040();
    }
    if (*(short *)(*(int *)(param_1 + 0x3f8) + 0x3a) != 0) {
      local_1b0 = (undefined1 **)(uint)*(ushort *)(*(int *)(param_1 + 0x3f8) + 0x3a);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x4713ab;
      iVar5 = FUN_005796f0();
      local_1b0 = (undefined1 **)0x4713b9;
      FUN_005c9210();
      local_4 = 2;
      local_1b0 = (undefined1 **)0x4713cd;
      FUN_005c9210();
      local_1b0 = (undefined1 **)0x100;
      local_4._0_1_ = 3;
      FUN_005d66f0();
      local_1b0 = (undefined1 **)0x100;
      FUN_005d6590(local_120,0x20);
      local_194 = (undefined1 *)0x0;
      local_190 = 0;
      local_19c = (undefined1 *)0x0;
      local_198 = 0;
      local_184 = (undefined1 *)(0xc1 - *(int *)(iVar5 + 0x14) / 2);
      puVar2 = local_184 + *(int *)(iVar5 + 0x14);
      local_180 = 0x20 - *(int *)(iVar5 + 0x18) / 2;
      local_18c = local_184;
      if ((int)puVar2 <= (int)local_184) {
        local_18c = puVar2;
      }
      if ((int)local_184 <= (int)puVar2) {
        local_184 = puVar2;
      }
      iVar5 = *(int *)(iVar5 + 0x18) + local_180;
      local_188 = local_180;
      if (iVar5 <= local_180) {
        local_188 = iVar5;
      }
      if (local_180 <= iVar5) {
        local_180 = iVar5;
      }
      local_1b0 = &local_194;
      FUN_005d5220(&local_18c,local_16c,&local_19c);
      local_4 = CONCAT31(local_4._1_3_,2);
      local_1b0 = (undefined1 **)0x47149a;
      thunk_FUN_005cb040();
      local_4 = 0xffffffff;
      local_1b0 = (undefined1 **)0x4714b1;
      thunk_FUN_005cb040();
    }
  }
  if (*(int *)(param_1 + 0x3f8) != 0) {
    uVar1 = *(ushort *)(*(int *)(param_1 + 0x3f8) + 0x38);
    if (uVar1 != 0) {
      local_1b0 = (undefined1 **)(uint)uVar1;
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x4714e3;
      iVar5 = FUN_005793d0();
      if (iVar5 != 0) {
        local_1b0 = *(undefined1 ***)(iVar5 + 0x14);
        uVar3 = FUN_0058d240();
        local_1b0 = (undefined1 **)0x0;
        FUN_005cba50(0x3e,8,0x5c,0x1c,uVar3);
        local_1b0 = (undefined1 **)0x100;
        local_19c = &stack0xfffffe4c;
        FUN_00436270(0);
        uVar3 = FUN_00436fb0(0x20,0x16);
        uVar4 = FUN_00436fb0(0x3d,7);
        uVar3 = FUN_00436fd0(uVar4,uVar3);
        FUN_00468c90(uVar3);
      }
    }
    uVar1 = *(ushort *)(*(int *)(param_1 + 0x3f8) + 0x3a);
    if (uVar1 != 0) {
      local_1b0 = (undefined1 **)(uint)uVar1;
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x471595;
      iVar5 = FUN_005793d0();
      if (iVar5 != 0) {
        local_1b0 = *(undefined1 ***)(iVar5 + 0x14);
        uVar3 = FUN_0058d240();
        local_1b0 = (undefined1 **)0x0;
        FUN_005cba50(0x85,8,0xa3,0x1c,uVar3);
        local_1b0 = (undefined1 **)0x100;
        local_19c = &stack0xfffffe4c;
        FUN_00436270(0);
        uVar3 = FUN_00436fb0(0x20,0x16);
        uVar4 = FUN_00436fb0(0x84,7);
        uVar3 = FUN_00436fd0(uVar4,uVar3);
        FUN_00468c90(uVar3);
      }
    }
  }
  ExceptionList = local_c;
  return;
}


