// FUN_005b3e50  entry=005b3e50  size=833 bytes

undefined4 __fastcall FUN_005b3e50(int param_1)

{
  int iVar1;
  undefined4 uVar2;
  int iVar3;
  uint uVar4;
  uint uVar5;
  int iVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  undefined4 local_38;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  int local_24;
  int local_20;
  int local_1c;
  undefined1 local_18 [12];
  undefined1 local_c [12];
  
  iVar6 = 0;
  iVar3 = *(int *)(*(int *)(param_1 + 400) + 0x40);
  if (param_1 == iVar3) {
    if (0x1ffff < *(int *)(param_1 + 0x180)) {
      uVar8 = 0;
      uVar7 = 0;
      uVar2 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
      FUN_00590aa0(uVar2,uVar7,uVar8);
      FUN_005a89c0(&local_24,0x5a);
      return 1;
    }
    iVar3 = *(int *)(*(int *)(param_1 + 0x184) + 0x304);
    iVar1 = FUN_005b3c90(0,1000);
    if (iVar1 < (100 - iVar3) * 10) {
      iVar6 = FUN_005b31a0(1,0);
    }
    if (((iVar6 == 0) && (iVar6 = FUN_005b31a0(2,1), iVar6 == 0)) &&
       (iVar6 = FUN_005b31a0(0,1), iVar6 == 0)) {
      return 1;
    }
    FUN_005b3a10(iVar6,0,0);
    return 1;
  }
  if (iVar3 == 0) {
    uVar8 = 0;
    uVar7 = 0;
    uVar2 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar2,uVar7,uVar8);
    FUN_00590ae0(local_c,param_1 + 4);
    uVar8 = 0;
    uVar7 = 0;
    uVar2 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar2,uVar7,uVar8);
    iVar3 = *(int *)(param_1 + 400);
    FUN_00590aa0(*(int *)(iVar3 + 4) - local_24,*(int *)(iVar3 + 8) - local_20,
                 *(int *)(iVar3 + 0xc) - local_1c);
    uVar2 = FUN_005ee080(local_30,local_2c);
    FUN_005a16c0(&local_38,uVar2);
    iVar3 = FUN_005edfb0(local_30,local_38,local_2c,local_34);
    iVar6 = FUN_005b1260();
    if (iVar3 + -0x80000 < iVar6) {
      FUN_005a89c0(*(int *)(param_1 + 400) + 4,0x5a);
      return 1;
    }
  }
  if (0x3ffff < *(int *)(param_1 + 0x17c)) {
    iVar3 = *(int *)(param_1 + 400);
    local_24 = (*(int *)(param_1 + 0x1ec) + *(int *)(iVar3 + 4)) / 2;
    local_1c = (*(int *)(iVar3 + 0xc) + *(int *)(param_1 + 500)) / 2;
    local_20 = (*(int *)(iVar3 + 8) + *(int *)(param_1 + 0x1f0)) / 2;
    uVar2 = FUN_005b1330(local_c,param_1 + 0x210);
    FUN_005a89c0(uVar2,0x5a);
    return 1;
  }
  iVar3 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
  if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
    iVar3 = -iVar3;
  }
  FUN_00590aa0(iVar3,0,0);
  FUN_00590ae0(local_18,param_1 + 4);
  iVar3 = *(int *)(param_1 + 400);
  iVar6 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
  if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
    iVar6 = -iVar6;
  }
  FUN_00590aa0(iVar6,0,0);
  iVar6 = FUN_005b1260();
  uVar4 = *(int *)(iVar3 + 4) - local_24;
  uVar5 = (int)uVar4 >> 0x1f;
  if (iVar6 <= (int)(((uVar4 ^ uVar5) - uVar5) + -0xc0000)) {
    FUN_005b2f30();
    return 1;
  }
  FUN_005a89c0(param_1 + 0x1ec,0x5a);
  return 1;
}


