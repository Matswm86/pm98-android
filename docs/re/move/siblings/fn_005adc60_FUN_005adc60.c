// FUN_005adc60  entry=005adc60  size=854 bytes

void __fastcall FUN_005adc60(int param_1)

{
  bool bVar1;
  int iVar2;
  char cVar3;
  int iVar4;
  int *piVar5;
  int iVar6;
  undefined2 extraout_var;
  undefined2 uVar7;
  uint uVar8;
  int iVar9;
  int iVar10;
  int local_18;
  int local_14;
  int local_10;
  
  if ((*(int *)(param_1 + 0x2c) == 6) && (*(int *)(param_1 + 0x30) == 0)) {
    bVar1 = true;
  }
  else {
    bVar1 = false;
  }
  if (bVar1) {
    *(undefined1 *)(*(int *)(param_1 + 400) + 99) = 0;
    *(undefined1 *)(param_1 + 0x5e) = 0;
    if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
       (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
      bVar1 = false;
    }
    else {
      bVar1 = true;
    }
    if ((bVar1) && (*(char *)(param_1 + 0x5c) != '\0')) {
      bVar1 = true;
    }
    else {
      bVar1 = false;
    }
    if (!bVar1) {
      iVar4 = FUN_005ec250();
      *(int *)(param_1 + 0x58) = ((int)(iVar4 * 2 + (iVar4 * 2 >> 0x1f & 0x7fffU)) >> 0xf) + 6;
      iVar4 = FUN_005ec250();
      iVar9 = 0;
      iVar10 = 0x3e80000;
      *(int *)(param_1 + 0x54) = ((int)(iVar4 * 3 + (iVar4 * 3 >> 0x1f & 0x7fffU)) >> 0xf) + 0xd;
      iVar4 = FUN_005ec250();
      *(int *)(param_1 + 0x58) = ((int)(iVar4 * 4 + (iVar4 * 4 >> 0x1f & 0x7fffU)) >> 0xf) + 0xc;
      iVar4 = FUN_005ec250();
      *(int *)(param_1 + 0x54) = ((int)(iVar4 * 3 + (iVar4 * 3 >> 0x1f & 0x7fffU)) >> 0xf) + 0xd;
      iVar4 = **(int **)(param_1 + 0x188);
      iVar2 = (*(int **)(param_1 + 0x188))[1];
      while (iVar2 != 0) {
        if (iVar4 == 0) {
          iVar6 = 0xc80000;
        }
        else {
          iVar6 = *(int *)(param_1 + 0xe4 +
                          (*(int *)(iVar4 + 0x2b8) * 0xb + *(int *)(iVar4 + 0x2c4)) * 4);
        }
        if (iVar6 < iVar10) {
          iVar9 = iVar4;
          if (iVar4 == 0) {
            iVar10 = 0xc80000;
          }
          else {
            iVar10 = *(int *)(param_1 + 0xe4 +
                             (*(int *)(iVar4 + 0x2b8) * 0xb + *(int *)(iVar4 + 0x2c4)) * 4);
          }
        }
        iVar4 = iVar4 + 0x3bc;
        iVar2 = iVar2 + -1;
      }
      if (iVar9 != 0) {
        if (*(short *)(param_1 + 0xb8 +
                      (*(int *)(iVar9 + 0x2b8) * 0xb + *(int *)(iVar9 + 0x2c4)) * 2) < 1) {
          iVar4 = FUN_005ec250();
          *(short *)(param_1 + 0x34) =
               *(short *)(param_1 + 0x34) +
               (short)((int)(iVar4 * 0x222 + (iVar4 * 0x222 >> 0x1f & 0x7fffU)) >> 0xf) + 0x222;
        }
        else {
          iVar4 = FUN_005ec250();
          *(short *)(param_1 + 0x34) =
               *(short *)(param_1 + 0x34) +
               (-0x222 - (short)((int)(iVar4 * 0x222 + (iVar4 * 0x222 >> 0x1f & 0x7fffU)) >> 0xf));
        }
      }
    }
    iVar4 = *(int *)(param_1 + 0x54) * 0xe0000;
    FUN_005ee0f0(((int)(iVar4 + (iVar4 >> 0x1f & 0xfU)) >> 4) + 0xe0000,
                 *(undefined2 *)(param_1 + 0x34));
    *(int *)(param_1 + 4) = *(int *)(param_1 + 4) + local_18;
    *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + local_14;
    *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + local_10;
    uVar7 = (undefined2)((uint)local_14 >> 0x10);
    if ((*(char *)(*(int *)(param_1 + 0x184) + 0x2ee) == '\0') ||
       (cVar3 = FUN_005943b0(), uVar7 = extraout_var, cVar3 == '\0')) {
      bVar1 = false;
    }
    else {
      bVar1 = true;
    }
    if ((bVar1) && (*(char *)(param_1 + 0x5c) != '\0')) {
      bVar1 = true;
    }
    else {
      bVar1 = false;
    }
    if (bVar1) {
      iVar4 = FUN_005b1100(*(undefined4 *)(param_1 + 0x184),
                           CONCAT22(uVar7,*(undefined2 *)(param_1 + 0x34)),0x1e0000,0xa0000);
    }
    else {
      iVar4 = FUN_005b31a0(0,1);
    }
    *(int *)(param_1 + 4) = *(int *)(param_1 + 4) - local_18;
    *(int *)(param_1 + 8) = *(int *)(param_1 + 8) - local_14;
    *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) - local_10;
    if (iVar4 != 0) {
      *(undefined4 *)(param_1 + 0xa0) = *(undefined4 *)(iVar4 + 4);
      *(undefined4 *)(param_1 + 0xa4) = *(undefined4 *)(iVar4 + 8);
      *(undefined4 *)(param_1 + 0xa8) = *(undefined4 *)(iVar4 + 0xc);
      *(int *)(*(int *)(param_1 + 400) + 0x4c) = iVar4;
      FUN_005ac1a0();
      return;
    }
    iVar4 = *(int *)(param_1 + 0x54) * 0x70000;
    uVar8 = (uint)*(ushort *)(param_1 + 0x34);
    iVar10 = FUN_005ec250(uVar8);
    piVar5 = (int *)FUN_005ee0f0(((int)(iVar10 * 0xa00 + (iVar10 * 0xa00 >> 0x1f & 0x7fU)) >> 7) +
                                 ((int)(iVar4 + (iVar4 >> 0x1f & 0xfU)) >> 4) + 0xa0000,uVar8);
    iVar4 = piVar5[1];
    iVar10 = piVar5[2];
    *(int *)(param_1 + 0xa0) = *piVar5 + *(int *)(param_1 + 4);
    *(int *)(param_1 + 0xa4) = *(int *)(param_1 + 8) + iVar4;
    *(int *)(param_1 + 0xa8) = iVar10 + *(int *)(param_1 + 0xc);
    FUN_005ac1a0();
  }
  return;
}


