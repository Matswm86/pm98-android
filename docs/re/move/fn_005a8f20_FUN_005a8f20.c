// FUN_005a8f20  entry=005a8f20  size=1378 bytes

void __thiscall FUN_005a8f20(int param_1,int param_2)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  bool bVar5;
  char cVar6;
  int iVar7;
  uint uVar8;
  int *piVar9;
  int iVar10;
  int *piVar11;
  undefined4 *puVar12;
  undefined4 extraout_ECX;
  int extraout_ECX_00;
  int iVar13;
  uint uVar14;
  int iVar15;
  short sVar16;
  int iVar17;
  undefined4 uVar18;
  int local_30;
  int local_c;
  int local_8;
  int local_4;
  
  cVar6 = *(char *)(param_1 + 0x2d7);
  *(undefined1 *)(param_1 + 0x2d7) = 1;
  if (cVar6 != '\0') {
    return;
  }
  iVar7 = FUN_005ee080(*(int *)(*(int *)(param_1 + 400) + 4) - *(int *)(param_1 + 4),
                       *(int *)(*(int *)(param_1 + 400) + 8) - *(int *)(param_1 + 8));
  cVar6 = *(char *)(*(int *)(param_1 + 0x184) + 0x2ee);
  iVar13 = CONCAT31((int3)((uint)extraout_ECX >> 8),cVar6);
  if ((cVar6 == '\0') || (cVar6 = FUN_005943b0(), iVar13 = extraout_ECX_00, cVar6 == '\0')) {
    bVar5 = false;
  }
  else {
    bVar5 = true;
  }
  if ((bVar5) && (*(char *)(param_1 + 0x5c) != '\0')) {
    bVar5 = true;
  }
  else {
    bVar5 = false;
  }
  if (((bVar5) && (iVar13 = *(int *)(param_1 + 400), param_1 != *(int *)(iVar13 + 0x40))) &&
     (uVar8 = (uint)(short)((short)param_2 - (short)iVar7), uVar14 = (int)uVar8 >> 0x1f,
     iVar15 = *(int *)(param_1 + 0x388) * 0x1555, iVar13 = -(iVar15 >> 0x1f),
     (int)((uVar8 ^ uVar14) - uVar14) < iVar15 / 100)) {
    param_2 = iVar7;
  }
  iVar7 = CONCAT22((short)((uint)iVar13 >> 0x10),*(undefined2 *)(param_1 + 0x34));
  local_30 = param_2 - iVar7;
  sVar16 = (short)local_30;
  uVar8 = (int)sVar16 >> 0x1f;
  iVar15 = ((int)sVar16 ^ uVar8) - uVar8;
  iVar13 = iVar15 + -0x100;
  iVar13 = (int)(iVar13 + (iVar13 >> 0x1f & 0x3ffU)) >> 10;
  iVar17 = iVar13 + 1;
  piVar9 = (int *)FUN_005ee0f0(0x4ccc,iVar7);
  FUN_00590aa0(*(int *)(param_1 + 4) + *piVar9,piVar9[1] + *(int *)(param_1 + 8),
               piVar9[2] + *(int *)(param_1 + 0xc));
  if (iVar17 < 2) {
    *(undefined2 *)(param_1 + 0x34) = (undefined2)param_2;
  }
  else {
    local_30 = ((sVar16 < 1) - 1 & 0x800) - 0x400;
    *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + (short)local_30;
  }
  if (((sVar16 != 0) && (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40))) &&
     ((iVar7 = ftol(), iVar7 < (*(int *)(param_1 + 0x388) << 0x10) / 100 &&
      ((*(byte *)(*(int *)(param_1 + 0x18c) + 0x461) & 0x40) == 0)))) {
    iVar10 = (*(int *)(*(int *)(param_1 + 400) + 0xc) * iVar13) / iVar17;
    piVar9 = (int *)FUN_005ee0f0((iVar7 * iVar13) / iVar17 + 0x4ccc,
                                 CONCAT22((short)((uint)iVar10 >> 0x10),
                                          *(undefined2 *)(param_1 + 0x34)));
    iVar7 = *(int *)(param_1 + 8);
    iVar1 = piVar9[1];
    iVar2 = piVar9[2];
    iVar3 = *(int *)(param_1 + 0xc);
    iVar4 = *(int *)(param_1 + 400);
    *(int *)(iVar4 + 4) = *(int *)(param_1 + 4) + *piVar9;
    *(int *)(iVar4 + 8) = iVar1 + iVar7;
    *(int *)(iVar4 + 0xc) = iVar2 + iVar3;
    FUN_005ee670(local_30);
    FUN_005ee290(iVar13,iVar17);
    *(int *)(*(int *)(param_1 + 400) + 0xc) = iVar10;
  }
  if (iVar15 < 0x1555) {
    uVar8 = *(uint *)(param_1 + 0x6c);
    *(undefined2 *)(param_1 + 100) = (undefined2)param_2;
    iVar13 = *(int *)(param_1 + 0x68);
    if (iVar13 < (int)uVar8) {
      if ((int)(iVar13 + 0x106U) < (int)uVar8) {
        uVar8 = iVar13 + 0x106U;
      }
    }
    else {
      if (iVar13 <= (int)uVar8) goto LAB_005a9205;
      if ((int)uVar8 < (int)(iVar13 - 0x106U)) {
        uVar8 = iVar13 - 0x106U;
      }
    }
  }
  else {
    uVar8 = *(int *)(param_1 + 0x68) - 0x1ca;
    uVar8 = uVar8 & ((int)uVar8 < 1) - 1;
  }
  *(uint *)(param_1 + 0x68) = uVar8;
LAB_005a9205:
  if (*(int *)(param_1 + 0x68) != 0) {
    piVar9 = (int *)(param_1 + 0x20);
    piVar11 = (int *)FUN_005ee0f0(*(int *)(param_1 + 0x68),*(undefined2 *)(param_1 + 100));
    *piVar9 = *piVar11;
    *(int *)(param_1 + 0x24) = piVar11[1];
    *(int *)(param_1 + 0x28) = piVar11[2];
    uVar8 = *(int *)(param_1 + 4) + *piVar9;
    uVar14 = (int)uVar8 >> 0x1f;
    if (((int)((uVar8 ^ uVar14) - uVar14) < *(int *)(*(int *)(param_1 + 0x18c) + 0x1970) + -0x4ccc)
       && (uVar8 = *(int *)(param_1 + 0x24) + *(int *)(param_1 + 8), uVar14 = (int)uVar8 >> 0x1f,
          (int)((uVar8 ^ uVar14) - uVar14) < *(int *)(*(int *)(param_1 + 0x18c) + 0x1978) + -0x4ccc)
       ) {
      iVar13 = *(int *)(param_1 + 400);
      if (param_1 == *(int *)(iVar13 + 0x40)) {
        local_4 = *(int *)(iVar13 + 0xc) - *(int *)(param_1 + 0xc);
        local_8 = *(int *)(iVar13 + 8) - *(int *)(param_1 + 8);
        local_c = *(int *)(iVar13 + 4) - *(int *)(param_1 + 4);
        piVar11 = (int *)FUN_005ee670(CONCAT22((short)((uint)local_4 >> 0x10),
                                               -*(short *)(param_1 + 0x34)));
        iVar13 = *piVar11;
        uVar8 = piVar11[1];
        iVar7 = *(int *)(*(int *)(param_1 + 400) + 0x20);
        FUN_005ee670(CONCAT22((short)((uint)iVar7 >> 0x10),-*(short *)(param_1 + 0x34)));
        if (*(int *)(param_1 + 0x6c) == 0) {
          iVar13 = *(int *)(param_1 + 400);
          *(int *)(iVar13 + 0x20) = *piVar9;
          *(undefined4 *)(iVar13 + 0x24) = *(undefined4 *)(param_1 + 0x24);
          *(undefined4 *)(iVar13 + 0x28) = *(undefined4 *)(param_1 + 0x28);
        }
        else {
          uVar14 = (int)uVar8 >> 0x1f;
          if ((((int)((uVar8 ^ uVar14) - uVar14) < 0x8001) && (iVar13 < 0x4ccc)) &&
             (iVar13 = FUN_005edfa0(*(undefined4 *)(param_1 + 0x68),0x11999), iVar7 <= iVar13)) {
            uVar18 = 0x38e;
            FUN_005ee170(&local_c,0x14ccc);
            puVar12 = (undefined4 *)FUN_005ee7c0(uVar18);
            iVar13 = *(int *)(param_1 + 400);
            *(undefined4 *)(iVar13 + 0x20) = *puVar12;
            *(undefined4 *)(iVar13 + 0x24) = puVar12[1];
            *(undefined4 *)(iVar13 + 0x28) = puVar12[2];
            iVar13 = *(int *)(param_1 + 400);
            *(undefined4 *)(iVar13 + 0x6c) = 0;
            *(undefined4 *)(iVar13 + 0x68) = 0;
          }
        }
      }
      *(int *)(param_1 + 4) = *(int *)(param_1 + 4) + *piVar9;
      *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + *(int *)(param_1 + 0x24);
      *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + *(int *)(param_1 + 0x28);
    }
    else {
      *(undefined4 *)(param_1 + 0x68) = 0;
    }
  }
  iVar13 = *(int *)(param_1 + 0x40);
  if ((iVar13 < 0) || (3 < iVar13)) {
    bVar5 = false;
  }
  else {
    bVar5 = true;
  }
  if (!bVar5) {
    if (((iVar13 == 0x1e) || (iVar13 == 0x22)) ||
       ((iVar13 == 0x23 || ((iVar13 == 0x20 && (*(int *)(param_1 + 0x68) != 0)))))) {
      if (0x777 < *(int *)(param_1 + 0x68)) {
        FUN_005a5430(0x23);
        return;
      }
      FUN_005a5430((-(*(int *)(param_1 + 0x68) != 0) & 4U) + 0x1e);
    }
    return;
  }
  iVar13 = *(int *)(param_1 + 0x68);
  if (0x1333 < iVar13) {
    FUN_005a5430(3);
    return;
  }
  if (iVar13 < 0x778) {
    FUN_005a5430(iVar13 != 0);
    return;
  }
  FUN_005a5430(2);
  return;
}


