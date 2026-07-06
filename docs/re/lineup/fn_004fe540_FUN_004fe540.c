// FUN_004fe540  entry=004fe540  size=553 bytes

void __thiscall FUN_004fe540(int param_1,int param_2)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 *puVar3;
  uint uVar4;
  undefined4 *puVar5;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 *puVar6;
  int iVar7;
  int iVar8;
  undefined4 uVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined4 local_48;
  int local_44;
  undefined4 local_40;
  undefined4 local_3c;
  undefined4 local_38;
  undefined4 local_34;
  undefined1 local_30 [4];
  int local_2c;
  int local_24;
  undefined4 local_20;
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  
  FUN_00437be0(local_30,param_1 + 0x78);
  iVar1 = FUN_005c12b0(0xffffffff);
  uVar9 = 0x100;
  uVar2 = extraout_ECX;
  FUN_00436270(0);
  FUN_00468c90(local_30,uVar2,uVar9);
  uVar10 = 0x80;
  uVar2 = extraout_ECX_00;
  FUN_00436270(0);
  uVar9 = FUN_00468be0(&local_20,1);
  FUN_0043ce50(uVar9,uVar2,uVar10);
  uVar11 = 0x100;
  local_44 = ((local_24 - *(int *)(iVar1 + 0x18)) - local_2c) / 2 + 1;
  uVar10 = 0;
  uVar9 = 0;
  local_48 = 4;
  uVar2 = FUN_004b7f40(&local_38);
  puVar3 = (undefined4 *)FUN_00436fd0(&local_48,uVar2);
  FUN_004b7f60(0x20,0x30,0xff,*puVar3,puVar3[1],puVar3[2],puVar3[3],iVar1,uVar9,uVar10,uVar11);
  FUN_005d9d30(0xc8a0a0);
  if ((*(uint *)(param_2 + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80(s_TEAM_RATING_00659364,0x1d,2,0x97,0xe,0x100);
  }
  else {
    FUN_005da180(s_TEAM_RATING_00659364,0x1d,2,0x97,0xe,0x100,1);
  }
  local_40 = *(undefined4 *)(param_1 + 0x408);
  local_3c = *(undefined4 *)(param_1 + 0x40c);
  local_20 = 0x66;
  local_18 = 0x99;
  local_1c = 0x11;
  local_14 = 0x1e;
  local_48 = 0xf;
  local_44 = 0;
  local_38 = 0x23;
  local_34 = 0x11;
  uVar4 = FUN_0057a3a0();
  uVar4 = uVar4 / 0xb;
  puVar3 = &local_20;
  iVar1 = param_1 + 0x4d8;
  iVar8 = param_1 + 0x440;
  iVar7 = param_1 + 0x48c;
  param_1 = param_1 + 0x3f4;
  puVar6 = &local_48;
  puVar5 = (undefined4 *)FUN_00436fd0(&local_38,&local_40);
  FUN_004f79b0(param_2,*puVar5,puVar5[1],puVar5[2],puVar5[3],puVar6,param_1,iVar7,iVar8,iVar1,puVar3
               ,uVar4);
  return;
}


