// FUN_00492d10  entry=00492d10  size=822 bytes
// callers/callees expanded one level from seeds

undefined4 __thiscall
FUN_00492d10(int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,ushort param_5,
            undefined4 param_6)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  int *piVar10;
  uint uVar11;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  undefined4 extraout_ECX_02;
  undefined4 extraout_ECX_03;
  undefined4 extraout_ECX_04;
  undefined4 extraout_ECX_05;
  undefined4 extraout_ECX_06;
  undefined1 *puVar12;
  undefined4 uVar13;
  undefined4 uVar14;
  undefined4 uVar15;
  undefined4 uVar16;
  undefined4 uVar17;
  undefined4 uVar18;
  undefined4 local_20;
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  
  uVar11 = (uint)param_5;
  *(undefined4 *)(param_1 + 0x430) = param_6;
  *(ushort *)(param_1 + 0x434) = param_5;
  uVar18 = 0;
  FUN_00436270(0);
  uVar15 = 0;
  uVar13 = 0;
  puVar12 = &DAT_00666f70;
  uVar1 = FUN_00436fb0(0x1e8,0x101);
  uVar1 = FUN_00436fd0(&param_3,uVar1);
  iVar2 = FUN_005bc780(param_2,uVar1,puVar12,uVar13,uVar15,uVar11,uVar18);
  if (iVar2 == 0) {
    return 0;
  }
  local_20 = 8;
  local_18 = 0x1de;
  local_1c = 0xb;
  local_14 = 0x23;
  iVar2 = FUN_0048ee60(param_1,&local_20,1,*(undefined4 *)(param_1 + 0x430));
  local_20 = 8;
  local_18 = 0x1de;
  local_1c = 0x29;
  local_14 = 0x41;
  iVar3 = FUN_0048ee60(param_1,&local_20,1,*(undefined4 *)(param_1 + 0x430));
  local_20 = 8;
  local_18 = 0x1de;
  local_1c = 0x47;
  local_14 = 0x5f;
  iVar4 = FUN_0048ee60(param_1,&local_20,1,*(undefined4 *)(param_1 + 0x430));
  local_20 = 8;
  local_18 = 0x1de;
  local_1c = 0x65;
  local_14 = 0x7d;
  iVar5 = FUN_0048ee60(param_1,&local_20,1,*(undefined4 *)(param_1 + 0x430));
  local_20 = 8;
  local_18 = 0x1de;
  local_1c = 0x83;
  local_14 = 0x9b;
  iVar6 = FUN_0048ee60(param_1,&local_20,1,*(undefined4 *)(param_1 + 0x430));
  local_20 = 8;
  local_18 = 0x1de;
  local_1c = 0xa1;
  local_14 = 0xb9;
  iVar7 = FUN_0048ee60(param_1,&local_20,1,*(undefined4 *)(param_1 + 0x430));
  local_20 = 8;
  local_18 = 0x1de;
  local_1c = 0xbf;
  local_14 = 0xd7;
  iVar8 = FUN_0048ee60(param_1,&local_20,1,*(undefined4 *)(param_1 + 0x430));
  local_20 = 8;
  local_18 = 0x1de;
  local_1c = 0xdd;
  local_14 = 0xf5;
  iVar9 = FUN_0048ee60(param_1,&local_20,1,*(undefined4 *)(param_1 + 0x430));
  if (iVar9 == 0 ||
      (iVar8 == 0 ||
      (iVar7 == 0 || (iVar6 == 0 || (iVar5 == 0 || (iVar4 == 0 || (iVar3 == 0 || iVar2 == 0))))))) {
    return 0;
  }
  iVar2 = 8;
  uVar1 = extraout_ECX;
  do {
    FUN_00437020(100,100,0x8c);
    uVar17 = extraout_ECX_00;
    FUN_00437020(0x78,0x78,0xa0);
    uVar16 = extraout_ECX_01;
    FUN_00437020(0x78,0x78,0xa0);
    uVar14 = extraout_ECX_02;
    FUN_00437020(0xff,0xdf,0);
    uVar18 = extraout_ECX_03;
    FUN_00437020(0x2a,0x3f,0x55);
    uVar15 = extraout_ECX_04;
    FUN_00437020(100,0x78,0x8c);
    uVar13 = extraout_ECX_05;
    FUN_00437020(0x8c,0xa0,0xb4);
    FUN_00493050(uVar13,uVar15,uVar18,uVar14,uVar16,uVar17,uVar1);
    iVar2 = iVar2 + -1;
    uVar1 = extraout_ECX_06;
  } while (iVar2 != 0);
  piVar10 = (int *)(param_1 + 0x35b8);
  iVar2 = 8;
  do {
    piVar10[8] = param_1 + 0x35f8;
    *piVar10 = param_1 + 0x35f8;
    piVar10 = piVar10 + 1;
    iVar2 = iVar2 + -1;
  } while (iVar2 != 0);
  return 1;
}


