// FUN_005b5150  entry=005b5150  size=951 bytes

undefined4 __fastcall FUN_005b5150(int param_1)

{
  char cVar1;
  int iVar2;
  undefined4 uVar3;
  int iVar4;
  uint uVar5;
  uint uVar6;
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
  
  iVar2 = *(int *)(*(int *)(param_1 + 400) + 0x40);
  if (param_1 == iVar2) {
    cVar1 = FUN_005b3c10(0x14,0x118,700);
    if (cVar1 != '\0') {
      iVar2 = FUN_005b31a0(0,1);
      if (iVar2 != 0) {
        FUN_005b3a10(iVar2,0,0);
        return 1;
      }
    }
    iVar2 = FUN_005b3c90(0,1000);
    if (iVar2 < 0x32) {
      uVar8 = 0;
      uVar7 = 0;
      uVar3 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
      FUN_00590aa0(uVar3,uVar7,uVar8);
      FUN_00590ae0(&local_30,param_1 + 4);
      iVar2 = FUN_005b1260();
      if (*(int *)(*(int *)(param_1 + 0x18c) + 0x1820) / 3 < iVar2) {
        uVar3 = 0;
        iVar2 = *(int *)(*(int *)(param_1 + 0x184) + 0x304);
        iVar4 = FUN_005b3c90(0,1000,0);
        iVar2 = FUN_005b31a0((-(iVar4 < iVar2 * 10) & 2U) + 1,uVar3);
        if (iVar2 != 0) {
          FUN_005b3a10(iVar2,0,1);
          return 1;
        }
      }
    }
    uVar8 = 0;
    uVar7 = 0;
    uVar3 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar3,uVar7,uVar8);
    FUN_005a89c0(&local_24,0x5a);
    return 1;
  }
  if (iVar2 == 0) {
    uVar8 = 0;
    uVar7 = 0;
    uVar3 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar3,uVar7,uVar8);
    FUN_00590ae0(local_c,param_1 + 4);
    uVar8 = 0;
    uVar7 = 0;
    uVar3 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar3,uVar7,uVar8);
    iVar2 = *(int *)(param_1 + 400);
    FUN_00590aa0(*(int *)(iVar2 + 4) - local_24,*(int *)(iVar2 + 8) - local_20,
                 *(int *)(iVar2 + 0xc) - local_1c);
    uVar3 = FUN_005ee080(local_30,local_2c);
    FUN_005a16c0(&local_38,uVar3);
    iVar2 = FUN_005edfb0(local_30,local_38,local_2c,local_34);
    iVar4 = FUN_005b1260();
    if (iVar2 + -0x80000 < iVar4) {
      FUN_005a89c0(*(int *)(param_1 + 400) + 4,0x5a);
      return 1;
    }
  }
  if (*(int *)(param_1 + 0x17c) < 0x40000) {
    uVar8 = 0;
    uVar7 = 0;
    uVar3 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar3,uVar7,uVar8);
    FUN_00590ae0(local_18,param_1 + 4);
    iVar2 = *(int *)(param_1 + 400);
    iVar4 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
    if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
      iVar4 = -iVar4;
    }
    FUN_00590aa0(iVar4,0,0);
    iVar4 = FUN_005b1260();
    uVar5 = *(int *)(iVar2 + 4) - local_24;
    uVar6 = (int)uVar5 >> 0x1f;
    if ((int)(((uVar5 ^ uVar6) - uVar6) + -0xc0000) < iVar4) {
      FUN_005a89c0(param_1 + 0x1ec,0x5a);
      return 1;
    }
    FUN_005b2f30();
    return 1;
  }
  iVar2 = *(int *)(param_1 + 400);
  local_24 = (*(int *)(param_1 + 0x1ec) + *(int *)(iVar2 + 4)) / 2;
  local_1c = (*(int *)(iVar2 + 0xc) + *(int *)(param_1 + 500)) / 2;
  local_20 = (*(int *)(iVar2 + 8) + *(int *)(param_1 + 0x1f0)) / 2;
  uVar3 = FUN_005b1330(local_c,param_1 + 0x210);
  FUN_005a89c0(uVar3,0x5a);
  return 1;
}


