// FUN_0046a110  entry=0046a110  size=4796 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_0046a110(int param_1,int param_2)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  char *pcVar5;
  undefined1 **local_1b0;
  undefined1 *local_19c;
  undefined4 local_198;
  int local_194;
  int local_190;
  int local_18c;
  int local_188;
  undefined1 *local_184;
  undefined4 local_180;
  undefined1 *local_17c [19];
  undefined1 local_130 [76];
  undefined1 local_e4 [16];
  char local_d4 [200];
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0060ae38;
  local_c = ExceptionList;
  local_1b0 = (undefined1 **)(param_1 + 0x78);
  ExceptionList = &local_c;
  FUN_00437be0();
  local_1b0 = (undefined1 **)0x100;
  local_19c = &stack0xfffffe4c;
  FUN_00436270(0xffffff);
  FUN_0043ce50(local_e4);
  local_19c = (undefined1 *)&local_1b0;
  local_1b0 = (undefined1 **)0x0;
  FUN_0043ca50(local_e4);
  local_1b0 = (undefined1 **)s_Proman10_00652e9c;
  FUN_005d9d50();
  local_1b0 = (undefined1 **)0x100;
  local_19c = &stack0xfffffe4c;
  *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffff9f;
  FUN_004ac740(param_1 + 0x410);
  uVar1 = FUN_00436fb0(0xdf,0xc);
  uVar2 = FUN_00436fb0(2,8);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_1b0 = (undefined1 **)0x100;
  local_19c = &stack0xfffffe4c;
  FUN_004ac740(param_1 + 0x410);
  uVar1 = FUN_00436fb0(0xdf,0xc);
  uVar2 = FUN_00436fb0(2,0x78);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  FUN_0043ce50(uVar1);
  local_19c = (undefined1 *)&local_1b0;
  local_1b0 = (undefined1 **)0xffffff;
  FUN_005d9d30();
  if (*(int *)(param_1 + 0x3f4) == 0) {
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      local_1b0 = (undefined1 **)0x100;
      FUN_005d9d80(s_1ST_LEG_MATCH_00653e68,2,8,0xe1);
    }
    else {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(s_1ST_LEG_MATCH_00653e68,2,8,0xe1,0x14);
    }
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) != 0) {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(s_2ND_LEG_MATCH_00653e58,2,0x78,0xe1,0x84);
      goto LAB_0046a3da;
    }
    pcVar5 = s_2ND_LEG_MATCH_00653e58;
  }
  else {
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      local_1b0 = (undefined1 **)0x100;
      FUN_005d9d80(s_MATCH_RESULT_00653e48,2,8,0xe1);
    }
    else {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(s_MATCH_RESULT_00653e48,2,8,0xe1,0x14);
    }
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) != 0) {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(s_REPLAY_RESULT_00653e38,2,0x78,0xe1,0x84);
      goto LAB_0046a3da;
    }
    pcVar5 = s_REPLAY_RESULT_00653e38;
  }
  local_1b0 = (undefined1 **)0x100;
  FUN_005d9d80(pcVar5,2,0x78,0xe1);
LAB_0046a3da:
  if ((((*(int *)(param_1 + 0x408) != 0) && (iVar3 = *(int *)(param_1 + 0x400), iVar3 != 0)) &&
      (*(short *)(iVar3 + 0x38) != 0)) && (*(short *)(iVar3 + 0x3a) != 0)) {
    local_1b0 = (undefined1 **)s_Proman12_00652eb0;
    FUN_005d9d50();
    local_19c = (undefined1 *)&local_1b0;
    *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffff9f;
    local_1b0 = *(undefined1 ***)(param_1 + 0x414);
    FUN_005d9d30();
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      local_1b0 = (undefined1 **)0x100;
      FUN_005d9d80(s_STADIUM_00653e30,0,0x19,0xe3);
    }
    else {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(s_STADIUM_00653e30,0,0x19,0xe3,0x26);
    }
    local_1b0 = *(undefined1 ***)(param_1 + 0x418);
    local_19c = (undefined1 *)&local_1b0;
    FUN_005d9d30();
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      local_1b0 = (undefined1 **)0x100;
      FUN_005d9d80(*(undefined4 *)(param_1 + 0x408),0,0x25,0xe3);
    }
    else {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(*(undefined4 *)(param_1 + 0x408),0,0x25,0xe3,0x32);
    }
  }
  if (((*(int *)(param_1 + 0x40c) != 0) && (iVar3 = *(int *)(param_1 + 0x404), iVar3 != 0)) &&
     ((*(short *)(iVar3 + 0x38) != 0 && (*(short *)(iVar3 + 0x3a) != 0)))) {
    local_1b0 = (undefined1 **)s_Proman12_00652eb0;
    FUN_005d9d50();
    local_19c = (undefined1 *)&local_1b0;
    *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffff9f;
    local_1b0 = *(undefined1 ***)(param_1 + 0x414);
    FUN_005d9d30();
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      local_1b0 = (undefined1 **)0x100;
      FUN_005d9d80(s_STADIUM_00653e30,0,0x8a,0xe3);
    }
    else {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(s_STADIUM_00653e30,0,0x8a,0xe3,0x97);
    }
    local_1b0 = *(undefined1 ***)(param_1 + 0x418);
    local_19c = (undefined1 *)&local_1b0;
    FUN_005d9d30();
    if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
      local_1b0 = (undefined1 **)0x100;
      FUN_005d9d80(*(undefined4 *)(param_1 + 0x40c),0,0x96,0xe3);
    }
    else {
      local_1b0 = (undefined1 **)0x1;
      FUN_005da180(*(undefined4 *)(param_1 + 0x40c),0,0x96,0xe3,0xa3);
    }
  }
  if (*(int *)(param_1 + 0x400) != 0) {
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_00436270(0);
    uVar1 = FUN_00436fb0(0xd9,0x2e);
    uVar2 = FUN_00436fb0(5,0x34);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_004ac740(param_1 + 0x41c);
    uVar1 = FUN_00436fb0(0xaf,0x14);
    uVar2 = FUN_00436fb0(7,0x36);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_004ac740(param_1 + 0x42c);
    uVar1 = FUN_00436fb0(0x24,0x14);
    uVar2 = FUN_00436fb0(0xb8,0x36);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_004ac740(param_1 + 0x424);
    uVar1 = FUN_00436fb0(0xaf,0x14);
    uVar2 = FUN_00436fb0(7,0x4c);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_004ac740(param_1 + 0x434);
    uVar1 = FUN_00436fb0(0x24,0x14);
    uVar2 = FUN_00436fb0(0xb8,0x4c);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    if (*(short *)(*(int *)(param_1 + 0x400) + 0x38) != 0) {
      local_1b0 = (undefined1 **)s_Proman12_00652eb0;
      FUN_005d9d50();
      local_19c = (undefined1 *)&local_1b0;
      *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffffbf | 0x20;
      local_1b0 = *(undefined1 ***)(param_1 + 0x420);
      FUN_005d9d30();
      local_1b0 = (undefined1 **)(uint)*(ushort *)(*(int *)(param_1 + 0x400) + 0x38);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x46a846;
      uVar1 = FUN_00579390();
      if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
        local_1b0 = (undefined1 **)0x100;
        FUN_005d9d80(uVar1,0x1e,0x36,0xb7);
      }
      else {
        local_1b0 = (undefined1 **)0x1;
        FUN_005da180(uVar1,0x1e,0x36,0xb7,0x4a);
      }
      if (*(int *)(param_1 + 0x3f8) != 0) {
        local_1b0 = (undefined1 **)(uint)*(byte *)(*(int *)(param_1 + 0x400) + 0x3c);
        sprintf(local_d4,&DAT_00653bc4);
        local_1b0 = (undefined1 **)s_Proman14_00652ebc;
        FUN_005d9d50();
        local_19c = (undefined1 *)&local_1b0;
        local_1b0 = *(undefined1 ***)(param_1 + 0x430);
        FUN_005d9d30();
        local_1b0 = (undefined1 **)0x1;
        *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffff9f;
        FUN_005da180(local_d4,0xb8,0x36,0xdc,0x4a);
      }
    }
    if (*(short *)(*(int *)(param_1 + 0x400) + 0x3a) != 0) {
      local_1b0 = (undefined1 **)s_Proman12_00652eb0;
      FUN_005d9d50();
      local_19c = (undefined1 *)&local_1b0;
      *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffffbf | 0x20;
      local_1b0 = *(undefined1 ***)(param_1 + 0x428);
      FUN_005d9d30();
      local_1b0 = (undefined1 **)(uint)*(ushort *)(*(int *)(param_1 + 0x400) + 0x3a);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x46a9ae;
      uVar1 = FUN_00579390();
      if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
        local_1b0 = (undefined1 **)0x100;
        FUN_005d9d80(uVar1,0x1e,0x4c,0xb7);
      }
      else {
        local_1b0 = (undefined1 **)0x1;
        FUN_005da180(uVar1,0x1e,0x4c,0xb7,0x60);
      }
      if (*(int *)(param_1 + 0x3f8) != 0) {
        local_1b0 = (undefined1 **)(uint)*(byte *)(*(int *)(param_1 + 0x400) + 0x3d);
        sprintf(local_d4,&DAT_00653bc4);
        local_1b0 = (undefined1 **)s_Proman14_00652ebc;
        FUN_005d9d50();
        local_19c = (undefined1 *)&local_1b0;
        local_1b0 = *(undefined1 ***)(param_1 + 0x438);
        FUN_005d9d30();
        local_1b0 = (undefined1 **)0x1;
        *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffff9f;
        FUN_005da180(local_d4,0xb8,0x4c,0xdc,0x60);
      }
    }
  }
  if (*(int *)(param_1 + 0x404) != 0) {
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_00436270(0);
    uVar1 = FUN_00436fb0(0xd9,0x2e);
    uVar2 = FUN_00436fb0(5,0xa4);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_004ac740(param_1 + 0x41c);
    uVar1 = FUN_00436fb0(0xaf,0x14);
    uVar2 = FUN_00436fb0(7,0xa6);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_004ac740(param_1 + 0x42c);
    uVar1 = FUN_00436fb0(0x24,0x14);
    uVar2 = FUN_00436fb0(0xb8,0xa6);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_004ac740(param_1 + 0x424);
    uVar1 = FUN_00436fb0(0xaf,0x14);
    uVar2 = FUN_00436fb0(7,0xbc);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    local_1b0 = (undefined1 **)0x100;
    local_19c = &stack0xfffffe4c;
    FUN_004ac740(param_1 + 0x434);
    uVar1 = FUN_00436fb0(0x24,0x14);
    uVar2 = FUN_00436fb0(0xb8,0xbc);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    FUN_0043ce50(uVar1);
    if (*(short *)(*(int *)(param_1 + 0x404) + 0x38) != 0) {
      local_1b0 = (undefined1 **)s_Proman12_00652eb0;
      FUN_005d9d50();
      local_19c = (undefined1 *)&local_1b0;
      *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffffbf | 0x20;
      local_1b0 = *(undefined1 ***)(param_1 + 0x420);
      FUN_005d9d30();
      local_1b0 = (undefined1 **)(uint)*(ushort *)(*(int *)(param_1 + 0x404) + 0x38);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x46ac96;
      uVar1 = FUN_00579390();
      if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
        local_1b0 = (undefined1 **)0x100;
        FUN_005d9d80(uVar1,0x1e,0xa6,0xb7);
      }
      else {
        local_1b0 = (undefined1 **)0x1;
        FUN_005da180(uVar1,0x1e,0xa6,0xb7,0xba);
      }
      if (*(int *)(param_1 + 0x3fc) != 0) {
        local_1b0 = (undefined1 **)(uint)*(byte *)(*(int *)(param_1 + 0x404) + 0x3c);
        sprintf(local_d4,&DAT_00653bc4);
        local_1b0 = (undefined1 **)s_Proman14_00652ebc;
        FUN_005d9d50();
        local_19c = (undefined1 *)&local_1b0;
        local_1b0 = *(undefined1 ***)(param_1 + 0x430);
        FUN_005d9d30();
        local_1b0 = (undefined1 **)0x1;
        *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffff9f;
        FUN_005da180(local_d4,0xb8,0xa6,0xdc,0xba);
      }
    }
    if (*(short *)(*(int *)(param_1 + 0x404) + 0x3a) != 0) {
      local_1b0 = (undefined1 **)s_Proman12_00652eb0;
      FUN_005d9d50();
      local_19c = (undefined1 *)&local_1b0;
      *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffffbf | 0x20;
      local_1b0 = *(undefined1 ***)(param_1 + 0x428);
      FUN_005d9d30();
      local_1b0 = (undefined1 **)(uint)*(ushort *)(*(int *)(param_1 + 0x404) + 0x3a);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x46adfe;
      uVar1 = FUN_00579390();
      if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
        local_1b0 = (undefined1 **)0x100;
        FUN_005d9d80(uVar1,0x1e,0xbc,0xb7);
      }
      else {
        local_1b0 = (undefined1 **)0x1;
        FUN_005da180(uVar1,0x1e,0xbc,0xb7,0xd0);
      }
      if (*(int *)(param_1 + 0x3fc) != 0) {
        local_1b0 = (undefined1 **)(uint)*(byte *)(*(int *)(param_1 + 0x404) + 0x3d);
        sprintf(local_d4,&DAT_00653bc4);
        local_1b0 = (undefined1 **)s_Proman14_00652ebc;
        FUN_005d9d50();
        local_19c = (undefined1 *)&local_1b0;
        local_1b0 = *(undefined1 ***)(param_1 + 0x438);
        FUN_005d9d30();
        local_1b0 = (undefined1 **)0x1;
        *(uint *)(param_2 + 0x144) = *(uint *)(param_2 + 0x144) & 0xffffff9f;
        FUN_005da180(local_d4,0xb8,0xbc,0xdc,0xd0);
      }
    }
  }
  iVar3 = *(int *)(param_1 + 0x400);
  if (iVar3 != 0) {
    if (*(short *)(iVar3 + 0x38) != 0) {
      local_1b0 = (undefined1 **)(uint)*(ushort *)(iVar3 + 0x38);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x46af2a;
      iVar3 = FUN_00579730();
      local_1b0 = (undefined1 **)0x46af35;
      FUN_005c9210();
      local_4 = 0;
      local_1b0 = (undefined1 **)0x46af47;
      FUN_005c9210();
      local_1b0 = (undefined1 **)0x100;
      local_4._0_1_ = 1;
      FUN_005d66f0();
      local_1b0 = (undefined1 **)0x100;
      FUN_005d6590(local_17c,0x20);
      local_19c = (undefined1 *)0x0;
      local_198 = 0;
      local_184 = (undefined1 *)0x0;
      local_180 = 0;
      local_18c = 0x10 - *(int *)(iVar3 + 0x14) / 2;
      iVar4 = *(int *)(iVar3 + 0x14) + local_18c;
      local_188 = 0x40 - *(int *)(iVar3 + 0x18) / 2;
      local_194 = local_18c;
      if (iVar4 <= local_18c) {
        local_194 = iVar4;
      }
      if (local_18c <= iVar4) {
        local_18c = iVar4;
      }
      iVar3 = *(int *)(iVar3 + 0x18) + local_188;
      local_190 = local_188;
      if (iVar3 <= local_188) {
        local_190 = iVar3;
      }
      if (local_188 <= iVar3) {
        local_188 = iVar3;
      }
      local_1b0 = &local_19c;
      FUN_005d5220(&local_194,local_130,&local_184);
      local_4 = (uint)local_4._1_3_ << 8;
      local_1b0 = (undefined1 **)0x46b014;
      thunk_FUN_005cb040();
      local_4 = 0xffffffff;
      local_1b0 = (undefined1 **)0x46b028;
      thunk_FUN_005cb040();
    }
    if (*(short *)(*(int *)(param_1 + 0x400) + 0x3a) != 0) {
      local_1b0 = (undefined1 **)(uint)*(ushort *)(*(int *)(param_1 + 0x400) + 0x3a);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x46b051;
      iVar3 = FUN_00579730();
      local_1b0 = (undefined1 **)0x46b05c;
      FUN_005c9210();
      local_4 = 2;
      local_1b0 = (undefined1 **)0x46b070;
      FUN_005c9210();
      local_1b0 = (undefined1 **)0x100;
      local_4._0_1_ = 3;
      FUN_005d66f0();
      local_1b0 = (undefined1 **)0x100;
      FUN_005d6590(local_130,0x20);
      local_184 = (undefined1 *)0x0;
      local_180 = 0;
      local_19c = (undefined1 *)0x0;
      local_198 = 0;
      local_18c = 0x10 - *(int *)(iVar3 + 0x14) / 2;
      iVar4 = *(int *)(iVar3 + 0x14) + local_18c;
      local_188 = 0x55 - *(int *)(iVar3 + 0x18) / 2;
      local_194 = local_18c;
      if (iVar4 <= local_18c) {
        local_194 = iVar4;
      }
      if (local_18c <= iVar4) {
        local_18c = iVar4;
      }
      iVar3 = *(int *)(iVar3 + 0x18) + local_188;
      local_190 = local_188;
      if (iVar3 <= local_188) {
        local_190 = iVar3;
      }
      if (local_188 <= iVar3) {
        local_188 = iVar3;
      }
      local_1b0 = &local_184;
      FUN_005d5220(&local_194,local_17c,&local_19c);
      local_4 = CONCAT31(local_4._1_3_,2);
      local_1b0 = (undefined1 **)0x46b13f;
      thunk_FUN_005cb040();
      local_4 = 0xffffffff;
      local_1b0 = (undefined1 **)0x46b153;
      thunk_FUN_005cb040();
    }
  }
  iVar3 = *(int *)(param_1 + 0x404);
  if (iVar3 != 0) {
    if (*(short *)(iVar3 + 0x38) != 0) {
      local_1b0 = (undefined1 **)(uint)*(ushort *)(iVar3 + 0x38);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x46b184;
      iVar3 = FUN_00579730();
      local_1b0 = (undefined1 **)0x46b18f;
      FUN_005c9210();
      local_4 = 4;
      local_1b0 = (undefined1 **)0x46b1a3;
      FUN_005c9210();
      local_1b0 = (undefined1 **)0x100;
      local_4._0_1_ = 5;
      FUN_005d66f0();
      local_1b0 = (undefined1 **)0x100;
      FUN_005d6590(local_130,0x20);
      local_184 = (undefined1 *)0x0;
      local_180 = 0;
      local_19c = (undefined1 *)0x0;
      local_198 = 0;
      local_18c = 0x10 - *(int *)(iVar3 + 0x14) / 2;
      iVar4 = *(int *)(iVar3 + 0x14) + local_18c;
      local_188 = 0xb0 - *(int *)(iVar3 + 0x18) / 2;
      local_194 = local_18c;
      if (iVar4 <= local_18c) {
        local_194 = iVar4;
      }
      if (local_18c <= iVar4) {
        local_18c = iVar4;
      }
      iVar3 = *(int *)(iVar3 + 0x18) + local_188;
      local_190 = local_188;
      if (iVar3 <= local_188) {
        local_190 = iVar3;
      }
      if (local_188 <= iVar3) {
        local_188 = iVar3;
      }
      local_1b0 = &local_184;
      FUN_005d5220(&local_194,local_17c,&local_19c);
      local_4 = CONCAT31(local_4._1_3_,4);
      local_1b0 = (undefined1 **)0x46b272;
      thunk_FUN_005cb040();
      local_4 = 0xffffffff;
      local_1b0 = (undefined1 **)0x46b286;
      thunk_FUN_005cb040();
    }
    if (*(short *)(*(int *)(param_1 + 0x404) + 0x3a) != 0) {
      local_1b0 = (undefined1 **)(uint)*(ushort *)(*(int *)(param_1 + 0x404) + 0x3a);
      FUN_00585ee0();
      local_1b0 = (undefined1 **)0x46b2af;
      iVar3 = FUN_00579730();
      local_1b0 = (undefined1 **)0x46b2ba;
      FUN_005c9210();
      local_4 = 6;
      local_1b0 = (undefined1 **)0x46b2ce;
      FUN_005c9210();
      local_1b0 = (undefined1 **)0x100;
      local_4._0_1_ = 7;
      FUN_005d66f0();
      local_1b0 = (undefined1 **)0x100;
      FUN_005d6590(local_130,0x20);
      local_184 = (undefined1 *)0x0;
      local_180 = 0;
      local_19c = (undefined1 *)0x0;
      local_198 = 0;
      local_18c = 0x10 - *(int *)(iVar3 + 0x14) / 2;
      iVar4 = *(int *)(iVar3 + 0x14) + local_18c;
      local_188 = 0xc6 - *(int *)(iVar3 + 0x18) / 2;
      local_194 = local_18c;
      if (iVar4 <= local_18c) {
        local_194 = iVar4;
      }
      if (local_18c <= iVar4) {
        local_18c = iVar4;
      }
      iVar3 = local_188 + *(int *)(iVar3 + 0x18);
      local_190 = local_188;
      if (iVar3 <= local_188) {
        local_190 = iVar3;
      }
      if (local_188 <= iVar3) {
        local_188 = iVar3;
      }
      local_1b0 = &local_184;
      FUN_005d5220(&local_194,local_17c,&local_19c);
      local_4 = CONCAT31(local_4._1_3_,6);
      local_1b0 = (undefined1 **)0x46b39d;
      thunk_FUN_005cb040();
      local_4 = 0xffffffff;
      local_1b0 = (undefined1 **)0x46b3b1;
      thunk_FUN_005cb040();
    }
  }
  ExceptionList = local_c;
  return;
}


