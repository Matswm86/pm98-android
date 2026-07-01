// FUN_00594310  entry=00594310  size=112 bytes

bool __fastcall FUN_00594310(int *param_1)

{
  undefined4 uVar1;
  int iVar2;
  undefined4 extraout_ECX;
  undefined1 *puVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined1 local_10 [16];
  
  FUN_00596440();
  iVar2 = param_1[0x119];
  if (param_1[0x119] == 0) {
    iVar2 = DAT_00674ea0;
  }
  param_1[0x119] = iVar2;
  uVar7 = 0;
  iVar2 = *param_1;
  uVar6 = extraout_ECX;
  FUN_00436270(0xffffff);
  uVar5 = 0;
  uVar4 = 0x4000;
  puVar3 = &DAT_00666f70;
  uVar1 = FUN_00468c10(local_10);
  iVar2 = (**(code **)(iVar2 + 0xc0))(param_1[0x119],uVar1,puVar3,uVar4,uVar5,uVar6,uVar7);
  return iVar2 != 0;
}


