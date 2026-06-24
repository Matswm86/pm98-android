// FUN_005aa870  entry=005aa870  size=908 bytes

void __thiscall FUN_005aa870(int param_1,char param_2)

{
  int iVar1;
  int iVar2;
  int iVar3;
  short sVar4;
  short sVar5;
  short sVar6;
  undefined4 uVar7;
  int iVar8;
  int *piVar9;
  int iVar10;
  short sVar11;
  uint uVar12;
  int iVar13;
  short sVar14;
  undefined4 uVar15;
  undefined4 uVar16;
  int local_54;
  int local_50;
  int local_4c;
  int local_48;
  int local_44;
  int local_40;
  undefined4 local_3c;
  int local_38;
  undefined4 local_34;
  int local_30;
  int local_2c;
  int local_28;
  int local_24;
  int local_20;
  int local_1c;
  undefined4 local_18;
  int local_14;
  undefined4 local_10;
  undefined4 local_c;
  int local_8;
  undefined4 local_4;
  
  *(undefined4 *)(param_1 + 0x48) = 0;
  if (((*(int *)(param_1 + 0x40) != 0x13) && (*(int *)(param_1 + 0x40) != 0x1d)) &&
     ((param_2 != '\0' || (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40))))) {
    FUN_00590aa0(*(int *)(param_1 + 0x20) << 3,*(int *)(param_1 + 0x24) << 3,
                 *(int *)(param_1 + 0x28) << 3);
    iVar10 = *(int *)(param_1 + 400);
    FUN_00590aa0(*(int *)(iVar10 + 0x20) * 6,*(int *)(iVar10 + 0x24) * 6,*(int *)(iVar10 + 0x28) * 6
                );
    FUN_00590aa0(local_30 + local_54,local_2c + local_50,local_28 + local_4c);
    FUN_00590aa0(local_24 / 2,local_20 / 2,local_1c / 2);
    uVar16 = 0;
    uVar15 = 0;
    uVar7 = FUN_005a44f0(1 - *(int *)(param_1 + 0x2b8));
    FUN_00590aa0(uVar7,uVar15,uVar16);
    local_18 = local_3c;
    local_c = local_3c;
    local_14 = local_38 + 0x39999;
    local_8 = local_38 + -0x39999;
    local_10 = local_34;
    local_4 = local_34;
    sVar4 = FUN_005aac00(&local_3c);
    sVar11 = *(short *)(param_1 + 0xb8 +
                       (*(int *)(**(int **)(param_1 + 0x188) + 0x2c4) +
                       *(int *)(**(int **)(param_1 + 0x188) + 0x2b8) * 0xb) * 2);
    sVar5 = FUN_005aac00(&local_18);
    sVar6 = FUN_005aac00(&local_c);
    sVar14 = sVar6;
    if (sVar6 < sVar5) {
      sVar14 = sVar5;
      sVar5 = sVar6;
    }
    if (sVar11 < sVar4) {
      sVar11 = (short)(((int)(short)(sVar14 - sVar4) << 1) / 3);
    }
    else {
      sVar11 = (short)(((int)(short)(sVar5 - sVar4) << 1) / 3);
    }
    sVar4 = sVar4 + sVar11;
    uVar12 = (int)sVar4 >> 0x1f;
    if (0x3c72 < (int)(((int)sVar4 ^ uVar12) - uVar12)) {
      sVar4 = 0;
    }
    if (*(int *)(*(int *)(param_1 + 0x18c) + 0x448) == 4) {
      sVar4 = 0;
    }
    iVar10 = *(int *)(param_1 + 0x3a0);
    iVar13 = 100 - iVar10;
    if (iVar13 < 0x8000) {
      iVar8 = FUN_005ec250();
      iVar13 = (int)(iVar8 * iVar13 + (iVar8 * iVar13 >> 0x1f & 0x7fffU)) >> 0xf;
    }
    else {
      iVar8 = FUN_005ec250();
      iVar8 = ((int)(iVar13 + (iVar13 >> 0x1f & 0xffU)) >> 8) * iVar8;
      iVar13 = (int)(iVar8 + (iVar8 >> 0x1f & 0x7fU)) >> 7;
    }
    iVar10 = (iVar10 + iVar13) * (int)sVar4;
    sVar11 = (short)((uint)iVar10 >> 0x10);
    sVar14 = ((short)(iVar10 / 100) + (sVar11 >> 0xf)) -
             (short)((longlong)iVar10 * 0x51eb851f >> 0x3f);
    piVar9 = (int *)FUN_005ee0f0(0x410000,CONCAT22(sVar11,sVar14 + *(short *)(param_1 + 0x34)));
    iVar10 = piVar9[1];
    iVar13 = piVar9[2];
    *(int *)(param_1 + 0xa0) = *piVar9 + *(int *)(param_1 + 4);
    *(int *)(param_1 + 0xa4) = *(int *)(param_1 + 8) + iVar10;
    *(int *)(param_1 + 0xa8) = *(int *)(param_1 + 0xc) + iVar13;
    iVar10 = FUN_005ec250();
    *(int *)(param_1 + 0xa8) = (int)(iVar10 * 0x200 + (iVar10 * 0x200 >> 0x1f & 0x7fU)) >> 7;
    *(undefined1 *)(param_1 + 0x5e) = 0;
    iVar10 = *(int *)(param_1 + 8);
    iVar13 = *(int *)(param_1 + 0xc);
    iVar8 = *(int *)(param_1 + 4);
    iVar1 = *(int *)(param_1 + 400);
    iVar2 = *(int *)(iVar1 + 4);
    iVar3 = *(int *)(iVar1 + 8);
    iVar1 = *(int *)(iVar1 + 0xc);
    FUN_005a5430((-(*(int *)(param_1 + 700) == 0) & 0x1fU) + 5);
    *(undefined4 *)(param_1 + 0x80) = 1;
    *(undefined4 *)(param_1 + 0x84) = 8;
    *(int *)(param_1 + 0x94) = local_54 + iVar8;
    *(int *)(param_1 + 0x98) = local_50 + iVar10;
    *(short *)(param_1 + 0x66) = sVar14 + *(short *)(param_1 + 0x34);
    *(int *)(param_1 + 0x9c) = local_4c + iVar13;
    if (param_2 == '\0') {
      iVar10 = *(int *)(param_1 + 400);
      *(undefined4 *)(iVar10 + 0x68) = 1;
      *(undefined4 *)(iVar10 + 0x6c) = 8;
      *(int *)(iVar10 + 0x9c) = local_48 + iVar2;
      *(int *)(iVar10 + 0xa0) = local_44 + iVar3;
      *(int *)(iVar10 + 0xa4) = local_40 + iVar1;
    }
  }
  return;
}


