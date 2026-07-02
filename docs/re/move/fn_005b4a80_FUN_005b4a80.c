// FUN_005b4a80  entry=005b4a80  size=1252 bytes

undefined4 __fastcall FUN_005b4a80(int param_1)

{
  char cVar1;
  uint uVar2;
  int iVar3;
  undefined4 uVar4;
  int *piVar5;
  int iVar6;
  uint uVar7;
  int iVar8;
  int iVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  int local_6c;
  int local_68;
  int local_64;
  int local_60;
  int local_5c;
  int local_58;
  int local_54;
  int local_50;
  int local_4c;
  int local_48;
  int local_44;
  int local_40;
  int local_3c;
  int local_38;
  int local_34;
  int local_30;
  int local_2c;
  int local_28;
  undefined1 local_18 [12];
  undefined1 local_c [12];
  
  iVar3 = *(int *)(*(int *)(param_1 + 400) + 0x40);
  if (iVar3 == 0) {
    piVar5 = (int *)FUN_005b3b20(local_c);
    local_60 = *piVar5;
    local_5c = piVar5[1];
    local_58 = piVar5[2];
    iVar3 = *(int *)(*(int *)(param_1 + 0x184) + 0x200);
  }
  else {
    if (iVar3 == 0) {
      iVar9 = 0xc80000;
    }
    else {
      uVar2 = *(int *)(iVar3 + 4) + *(int *)(iVar3 + 0x3a4);
      uVar7 = (int)uVar2 >> 0x1f;
      iVar9 = (uVar2 ^ uVar7) - uVar7;
    }
    iVar3 = MulDiv(iVar9,(int)(0x3200000 / (longlong)(*(int *)(iVar3 + 0x14c) + 100)),
                   *(int *)(*(int *)(param_1 + 0x18c) + 0x1820));
    if (iVar3 < 0x40001) {
      iVar3 = *(int *)(*(int *)(param_1 + 400) + 0x40);
      if (iVar3 == 0) {
        iVar9 = 0xc80000;
      }
      else {
        uVar2 = *(int *)(iVar3 + 4) + *(int *)(iVar3 + 0x3a4);
        uVar7 = (int)uVar2 >> 0x1f;
        iVar9 = (uVar2 ^ uVar7) - uVar7;
      }
      iVar3 = MulDiv(iVar9,(int)(0x3200000 / (longlong)(*(int *)(iVar3 + 0x14c) + 100)),
                     *(int *)(*(int *)(param_1 + 0x18c) + 0x1820));
    }
    else {
      iVar3 = 0x40000;
    }
    uVar11 = 0;
    uVar10 = 0;
    iVar9 = *(int *)(*(int *)(param_1 + 400) + 0x40);
    uVar4 = FUN_005a44f0(*(undefined4 *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar4,uVar10,uVar11);
    FUN_00590aa0(local_54 - *(int *)(iVar9 + 4),local_50 - *(int *)(iVar9 + 8),
                 local_4c - *(int *)(iVar9 + 0xc));
    uVar4 = FUN_005ee080(local_30,local_2c);
    iVar9 = *(int *)(*(int *)(param_1 + 400) + 0x40);
    piVar5 = (int *)FUN_005ee0f0(iVar3,uVar4);
    FUN_00590aa0(*(int *)(iVar9 + 4) + *piVar5,piVar5[1] + *(int *)(iVar9 + 8),
                 piVar5[2] + *(int *)(iVar9 + 0xc));
    iVar3 = *(int *)(param_1 + 0x218);
    iVar9 = iVar3;
    if (iVar3 <= local_40) {
      iVar9 = local_40;
    }
    local_6c = *(int *)(param_1 + 0x224);
    if ((iVar9 <= local_6c) && (local_6c = iVar3, iVar3 <= local_40)) {
      local_6c = local_40;
    }
    iVar3 = *(int *)(param_1 + 0x214);
    iVar9 = iVar3;
    if (iVar3 <= local_44) {
      iVar9 = local_44;
    }
    iVar6 = *(int *)(param_1 + 0x220);
    if ((iVar9 <= iVar6) && (iVar6 = iVar3, iVar3 <= local_44)) {
      iVar6 = local_44;
    }
    iVar3 = *(int *)(param_1 + 0x210);
    iVar9 = iVar3;
    if (iVar3 <= local_48) {
      iVar9 = local_48;
    }
    iVar8 = *(int *)(param_1 + 0x21c);
    if ((iVar9 <= *(int *)(param_1 + 0x21c)) && (iVar8 = iVar3, iVar3 <= local_48)) {
      iVar8 = local_48;
    }
    FUN_00590aa0(iVar8,iVar6,local_6c);
    local_60 = local_3c;
    local_5c = local_38;
    local_58 = local_34;
    cVar1 = FUN_005b04e0(*(int *)(*(int *)(param_1 + 400) + 0x40) + 4);
    if (cVar1 != '\0') {
LAB_005b4e65:
      FUN_00590aa0(local_60 - *(int *)(param_1 + 4),local_5c - *(int *)(param_1 + 8),
                   local_58 - *(int *)(param_1 + 0xc));
      uVar4 = FUN_005ee080(local_54,local_50);
      FUN_005a16c0(&local_6c,uVar4);
      iVar3 = FUN_005edfb0(local_54,local_6c,local_50,local_68);
      iVar9 = FUN_005b3c90(0,1000);
      if (iVar9 < 1000 - (iVar3 * 1000) / 0x30000) {
        FUN_005aafd0(0);
      }
      goto LAB_005b4f4c;
    }
    iVar3 = *(int *)(*(int *)(param_1 + 400) + 0x40);
    if (*(int *)(iVar3 + 0x154) == 0) {
      if (iVar3 == 0) {
        iVar3 = 0xc80000;
      }
      else {
        iVar3 = *(int *)(param_1 + 0xe4 +
                        (*(int *)(iVar3 + 0x2b8) * 0xb + *(int *)(iVar3 + 0x2c4)) * 4);
      }
      if (iVar3 < 0xc0000) {
        uVar11 = 0;
        uVar10 = 0;
        uVar4 = FUN_005a44f0(*(undefined4 *)(param_1 + 0x2b8));
        FUN_00590aa0(uVar4,uVar10,uVar11);
        FUN_00590ae0(&local_3c,*(int *)(*(int *)(param_1 + 400) + 0x40) + 4);
        iVar3 = FUN_005b1260();
        if (iVar3 < *(int *)(*(int *)(param_1 + 0x18c) + 0x1820) / 2) goto LAB_005b4e65;
      }
    }
    uVar11 = 0;
    uVar10 = 0;
    uVar4 = FUN_005a44f0(*(undefined4 *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar4,uVar10,uVar11);
    uVar11 = 0;
    uVar10 = 0;
    uVar4 = FUN_005a44f0(*(undefined4 *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar4,uVar10,uVar11);
    FUN_00590aa0(local_3c + local_48,local_38 + local_44,local_34 + local_40);
    FUN_00590aa0(local_60 + local_54,local_5c + local_50,local_58 + local_4c);
    piVar5 = (int *)FUN_005b3b20(local_18);
    FUN_00590aa0(local_6c + *piVar5,piVar5[1] + local_68,piVar5[2] + local_64);
    FUN_00590aa0((int)(local_30 + (local_30 >> 0x1f & 3U)) >> 2,
                 (int)(local_2c + (local_2c >> 0x1f & 3U)) >> 2,
                 (int)(local_28 + (local_28 >> 0x1f & 3U)) >> 2);
    piVar5 = (int *)FUN_005b1330(local_c,(int *)(param_1 + 0x210));
    local_60 = *piVar5;
    local_5c = piVar5[1];
    local_58 = piVar5[2];
    iVar3 = *(int *)(*(int *)(param_1 + 0x184) + 0x200);
  }
  if (param_1 != iVar3) {
    local_60 = *(int *)(iVar3 + 4);
  }
LAB_005b4f4c:
  FUN_005a89c0(&local_60,0x5a);
  return 1;
}


