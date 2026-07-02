// FUN_004fa840  entry=004fa840  size=886 bytes

int __thiscall FUN_004fa840(int param_1,undefined4 param_2,uint param_3,int param_4)

{
  bool bVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  char *_Format;
  uint uVar5;
  undefined1 *puVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  int local_1cc;
  uint local_1c4;
  int local_1c0;
  uint local_1bc;
  int local_1b8;
  undefined4 local_1b4;
  undefined4 local_1b0;
  undefined4 local_1ac;
  undefined4 local_1a8;
  undefined1 local_1a4 [20];
  uint local_190;
  int local_18c;
  undefined1 local_158 [76];
  char local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  int local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_006163e6;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_00436270(0xffffff);
  uVar8 = 0;
  uVar7 = 0x4008;
  puVar6 = &DAT_00666f70;
  uVar2 = CRect::CRect((CRect *)&local_1c4,0,0,0x280,0x1e0);
  iVar3 = FUN_005c55b0(param_2,uVar2,puVar6,uVar7,uVar8);
  if (iVar3 == 0) {
    ExceptionList = local_c;
    return 0;
  }
  uVar5 = 0xffff;
  local_1cc = 5;
  bVar1 = true;
  *(int *)(param_1 + 0x480) = param_4;
  if (param_3 < 0x39a) {
    if (0x397 < param_3) {
switchD_004fa934_caseD_3aa:
      uVar5 = 1;
      iVar4 = 4;
      goto LAB_004fa9e3;
    }
    if (param_3 == 0x392) {
      uVar5 = 1;
      iVar4 = 3;
      goto LAB_004fa9e3;
    }
switchD_004fa934_caseD_3a2:
    uVar5 = 1;
    iVar4 = 3;
    goto LAB_004fa9e1;
  }
  if (0x3de < param_3) {
    if (param_3 == 0x4e3e) {
      iVar4 = 7;
      goto LAB_004fa9e1;
    }
    goto switchD_004fa934_caseD_3a2;
  }
  if (param_3 == 0x3de) {
    iVar4 = 8;
    goto LAB_004fa9e3;
  }
  switch(param_3) {
  case 0x39a:
  case 0x3a3:
    uVar5 = 1;
  case 0x3a1:
    iVar4 = 2;
    goto LAB_004fa9e3;
  case 0x39b:
  case 0x39c:
  case 0x39d:
  case 0x3a4:
  case 0x3a5:
  case 0x3a6:
  case 0x3ac:
  case 0x3af:
    uVar5 = 1;
    iVar4 = 1;
    goto LAB_004fa9e3;
  case 0x39e:
  case 0x39f:
  case 0x3a0:
  case 0x3ab:
  case 0x3ad:
  case 0x3b0:
  case 0x3b6:
  case 0x3b7:
  case 0x3bf:
    uVar5 = 1;
    iVar4 = 0;
    goto LAB_004fa9e3;
  default:
    goto switchD_004fa934_caseD_3a2;
  case 0x3a7:
    uVar5 = 0;
    iVar4 = 0;
    goto LAB_004fa9e3;
  case 0x3a8:
    iVar4 = 5;
    break;
  case 0x3a9:
    uVar5 = 0;
    iVar4 = 0;
    break;
  case 0x3aa:
    goto switchD_004fa934_caseD_3aa;
  case 0x3ae:
    uVar5 = 1;
    iVar4 = 6;
    goto LAB_004fa9e3;
  case 0x3b1:
  case 0x3b2:
  case 0x3b3:
  case 0x3b4:
  case 0x3b5:
    uVar5 = 0;
    iVar4 = 1;
    break;
  case 0x3b8:
  case 0x3ba:
    uVar5 = 0;
    iVar4 = 8;
    break;
  case 0x3b9:
    uVar5 = 0;
    iVar4 = 6;
    break;
  case 0x3bb:
    iVar4 = 9;
    goto LAB_004fa9e3;
  case 0x3c0:
  case 0x3c1:
    uVar5 = 0;
    iVar4 = 0;
    local_1cc = 0;
    break;
  case 0x3c2:
    uVar5 = 0;
    iVar4 = 0x15;
  }
LAB_004fa9e1:
  bVar1 = false;
LAB_004fa9e3:
  _Format = s_RECURSOS_FONDO_u_bmp_00658c8c;
  if ((iVar4 == 3) || (iVar4 == 4)) {
    _Format = s_RECURSOS_PREMIER_FONDO_u_bmp_00658c44;
  }
  else if (iVar4 == 7) {
    _Format = s_RECURSOS_PREMIER_SININFO_FONDO_u_00658c64;
  }
  sprintf(local_10c,_Format,iVar4);
  FUN_005c9f60(local_10c,0,0xffffffff);
  if (uVar5 < 2) {
    FUN_005c9210();
    local_4 = 0;
    FUN_005c9210();
    local_4._0_1_ = 1;
    sprintf(local_10c,s_RECURSOS_BARRA_u_bmp_00658c2c,uVar5);
    FUN_005c9f60(local_10c,0,0xffffffff);
    sprintf(local_10c,s_RECURSOS_BARRAMASK_u_bmp_00658c10,uVar5);
    FUN_005c9f60(local_10c,0,0xffffffff);
    local_1ac = 0;
    local_1c4 = (0 < (int)local_190) - 1 & local_190;
    local_1bc = ((int)local_190 < 0) - 1 & local_190;
    local_1a8 = 0;
    local_18c = local_18c + local_1cc;
    local_1b4 = 0;
    local_1b0 = 0;
    local_1c0 = local_1cc;
    if (local_18c <= local_1cc) {
      local_1c0 = local_18c;
    }
    local_1b8 = local_1cc;
    if (local_1cc <= local_18c) {
      local_1b8 = local_18c;
    }
    FUN_005d5220(&local_1c4,local_158,&local_1b4,local_1a4,&local_1ac);
    local_4 = (uint)local_4._1_3_ << 8;
    thunk_FUN_005cb040();
    local_4 = 0xffffffff;
    thunk_FUN_005cb040();
  }
  uVar2 = 0;
  *(undefined4 *)(param_1 + 0x47c) = 1;
  FUN_005beb60(&DAT_00666f70);
  *(undefined4 *)(param_1 + 0x54) = 0;
  if ((bVar1) && (param_4 != 0)) {
    uVar2 = 1;
  }
  FUN_005715a0(param_1,0x29,3,uVar2);
  ExceptionList = local_c;
  return iVar3;
}


