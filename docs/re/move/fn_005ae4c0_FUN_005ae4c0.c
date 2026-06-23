// FUN_005ae4c0  entry=005ae4c0  size=1103 bytes

void __fastcall FUN_005ae4c0(int param_1)

{
  int *piVar1;
  short sVar2;
  bool bVar3;
  char cVar4;
  short sVar5;
  short sVar6;
  short sVar7;
  short sVar8;
  int iVar9;
  int iVar10;
  undefined4 *puVar11;
  undefined4 uVar12;
  undefined4 uVar13;
  int iVar14;
  int iVar15;
  int iVar16;
  undefined1 local_c [12];
  
  if ((*(int *)(param_1 + 0x2c) == 8) && (*(int *)(param_1 + 0x30) == 0)) {
    bVar3 = true;
  }
  else {
    bVar3 = false;
  }
  if ((bVar3) && (*(int *)(param_1 + 0x7c) == *(int *)(*(int *)(param_1 + 400) + 0x80))) {
    cVar4 = FUN_0058f100();
    if (cVar4 == '\0') {
      iVar16 = *(int *)(param_1 + 0x54);
      if (iVar16 < 5) {
        iVar16 = 4;
      }
      iVar9 = ftol();
      iVar10 = (iVar16 + 0x10) * 0x5999;
      iVar16 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
      if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1)) {
        iVar16 = -iVar16;
      }
      FUN_00590aa0(iVar16,0,0);
      piVar1 = (int *)(param_1 + 4);
      puVar11 = (undefined4 *)FUN_00590ae0(local_c,piVar1);
      uVar12 = FUN_005ee080(*puVar11,puVar11[1]);
      sVar5 = (short)uVar12 - *(short *)(param_1 + 0x34);
      sVar2 = *(short *)(param_1 + 0xb8 +
                        (*(int *)(**(int **)(param_1 + 0x188) + 0x2c4) +
                        *(int *)(**(int **)(param_1 + 0x188) + 0x2b8) * 0xb) * 2);
      puVar11 = (undefined4 *)FUN_00590ae0(local_c,piVar1);
      sVar6 = FUN_005ee080(*puVar11,puVar11[1]);
      sVar6 = sVar6 - *(short *)(param_1 + 0x34);
      puVar11 = (undefined4 *)FUN_00590ae0(local_c,piVar1);
      sVar7 = FUN_005ee080(*puVar11,puVar11[1]);
      sVar7 = sVar7 - *(short *)(param_1 + 0x34);
      *(int *)(*(int *)(param_1 + 400) + 0x80) = *(int *)(*(int *)(param_1 + 400) + 0x80) + 1;
      if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180a) != '\0') {
        FUN_00590f00();
      }
      cVar4 = FUN_0058fb50(piVar1);
      if ((cVar4 == '\0') ||
         (((-1 < *piVar1) - 1 & 0xfffffffe) + 1 ==
          ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
        bVar3 = false;
      }
      else {
        bVar3 = true;
      }
      if (bVar3) {
        cVar4 = FUN_005ae430(piVar1);
        if ((cVar4 == '\0') ||
           (((-1 < *piVar1) - 1 & 0xfffffffe) + 1 ==
            ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
          bVar3 = false;
        }
        else {
          bVar3 = true;
        }
        if (!bVar3) {
          uVar13 = FUN_005ec240();
          if (*(char *)(*(int *)(param_1 + 0x18c) + 0x180b) != '\0') {
            FUN_004e9940(*(undefined4 *)(param_1 + 0x2c0));
          }
          FUN_005ec230(uVar13);
        }
      }
      sVar8 = sVar7;
      if (sVar7 < sVar6) {
        sVar8 = sVar6;
        sVar6 = sVar7;
      }
      if (sVar2 < sVar5) {
        sVar8 = sVar8 - sVar5;
      }
      else {
        sVar8 = sVar6 - sVar5;
      }
      iVar15 = ((100 - *(int *)(param_1 + 0x39c)) * 0x1555) / 100;
      iVar16 = iVar15 * 2 + 1;
      if (iVar16 < 0x8000) {
        iVar14 = FUN_005ec250();
        iVar16 = (int)(iVar14 * iVar16 + (iVar14 * iVar16 >> 0x1f & 0x7fffU)) >> 0xf;
      }
      else {
        iVar14 = FUN_005ec250();
        iVar14 = ((int)(iVar16 + (iVar16 >> 0x1f & 0xffU)) >> 8) * iVar14;
        iVar16 = (int)(iVar14 + (iVar14 >> 0x1f & 0x7fU)) >> 7;
      }
      iVar15 = CONCAT22((short)((uint)uVar12 >> 0x10),sVar5) + ((int)sVar8 << 1) / 3 +
               (iVar16 - iVar15);
      iVar16 = ((100 - *(int *)(param_1 + 0x388)) * 0x666) / 100;
      if (iVar16 < 0x8000) {
        iVar14 = FUN_005ec250();
        iVar16 = (int)(iVar14 * iVar16 + (iVar14 * iVar16 >> 0x1f & 0x7fffU)) >> 0xf;
      }
      else {
        iVar14 = FUN_005ec250();
        iVar14 = ((int)(iVar16 + (iVar16 >> 0x1f & 0xffU)) >> 8) * iVar14;
        iVar16 = (int)(iVar14 + (iVar14 >> 0x1f & 0x7fU)) >> 7;
      }
      FUN_005ee6e0(iVar16 + -0x222);
      FUN_005ee670(CONCAT22((short)((uint)iVar15 >> 0x10),(short)iVar15 + *(short *)(param_1 + 0x34)
                           ));
      iVar16 = *(int *)(param_1 + 400);
      *(int *)(iVar16 + 0x20) =
           ((int)(iVar9 + (iVar9 >> 0x1f & 0x1fU)) >> 5) +
           ((int)(iVar10 + (iVar10 >> 0x1f & 0x1fU)) >> 5);
      *(undefined4 *)(iVar16 + 0x24) = 0;
      *(undefined4 *)(iVar16 + 0x28) = 0;
      iVar16 = *(int *)(*(int *)(param_1 + 400) + 0x70);
      if (iVar16 < 5) {
        iVar16 = 4;
      }
      *(int *)(*(int *)(param_1 + 400) + 0x70) = iVar16;
      *(byte *)(*(int *)(param_1 + 0x18c) + 0x462) =
           *(byte *)(*(int *)(param_1 + 0x18c) + 0x462) | 0x40;
      *(undefined4 *)(param_1 + 0x54) = 0;
      *(undefined4 *)(param_1 + 0x58) = 0;
      *(undefined4 *)(*(int *)(param_1 + 400) + 0x4c) = 0;
      FUN_005ab5a0();
      *(undefined1 *)(*(int *)(param_1 + 400) + 100) = 1;
    }
  }
  return;
}


