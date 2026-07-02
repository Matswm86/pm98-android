// FUN_005266c0  entry=005266c0  size=323 bytes

int __thiscall FUN_005266c0(int *param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 extraout_ECX;
  undefined *puVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined4 local_20;
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  
  iVar2 = FUN_005264d0(param_2,param_3,param_4);
  if (iVar2 != 0) {
    local_20 = 0x4c;
    local_18 = 0x234;
    local_1c = 0x79;
    local_14 = 0x167;
    (**(code **)(*param_1 + 0xcc))(&local_20,1);
    FUN_00526640();
    uStack_28 = 0x40;
    local_20 = 0x114;
    uStack_24 = 0x24;
    local_1c = 199;
    FUN_005262c0(param_1,&uStack_28,param_1[0x10d]);
    uStack_28 = 0x11e;
    local_20 = 0x1e1;
    uStack_24 = 0x2b;
    local_1c = 0xbf;
    FUN_005261f0(param_1,&uStack_28,param_1[0x10d]);
    uVar9 = 0xffffff;
    iVar1 = param_1[0x228];
    uVar8 = extraout_ECX;
    FUN_00437020(0xff,0xdf,0);
    uVar7 = 900;
    uVar6 = 0;
    puVar5 = &DAT_00652e60;
    uVar3 = FUN_00436fb0(0x4a,0x19);
    uVar4 = FUN_00436fb0(0xd8,0xce);
    uVar3 = FUN_00436fd0(uVar4,uVar3);
    (**(code **)(iVar1 + 0xc0))(param_1,uVar3,puVar5,uVar6,uVar7,uVar8,uVar9);
  }
  return iVar2;
}


