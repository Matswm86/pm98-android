// thunk_FUN_005b41c0  entry=005b3e40  size=5 bytes

undefined4 __fastcall thunk_FUN_005b41c0(int param_1)

{
  bool bVar1;
  char cVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  int iStack_c;
  int iStack_8;
  uint uStack_4;
  
  iVar4 = *(int *)(param_1 + 0x140);
  if (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40)) {
    if (iVar4 == 1) {
      uVar3 = *(int *)(param_1 + 4) - *(int *)(param_1 + 0x170);
      uVar6 = (int)uVar3 >> 0x1f;
      if ((((int)((uVar3 ^ uVar6) - uVar6) < 0x40000) &&
          (uVar3 = *(int *)(param_1 + 8) - *(int *)(param_1 + 0x174), uVar6 = (int)uVar3 >> 0x1f,
          (int)((uVar3 ^ uVar6) - uVar6) < 0x40000)) &&
         (uVar3 = *(int *)(param_1 + 0xc) - *(int *)(param_1 + 0x178), uVar6 = (int)uVar3 >> 0x1f,
         (int)((uVar3 ^ uVar6) - uVar6) < 0x40000)) {
        bVar1 = true;
      }
      else {
        bVar1 = false;
      }
      if (bVar1) {
        iVar4 = FUN_005b35c0();
        if ((iVar4 == 0) && (iVar4 = FUN_005b31a0(2,0), iVar4 == 0)) {
          *(undefined4 *)(param_1 + 0x140) = 2;
          return 1;
        }
        uVar3 = *(int *)(iVar4 + 0x3a4) + *(int *)(iVar4 + 4);
        uVar6 = (int)uVar3 >> 0x1f;
        iVar5 = FUN_005ec250();
        if (iVar4 == 0) {
          iVar8 = 0xc80000;
        }
        else {
          iVar8 = *(int *)(param_1 + 0xe4 +
                          (*(int *)(iVar4 + 0x2b8) * 0xb + *(int *)(iVar4 + 0x2c4)) * 4);
        }
        FUN_005b3a10(iVar4,0xa0000 < iVar8,
                     (int)(iVar5 * 1000 + (iVar5 * 1000 >> 0x1f & 0x7fffU)) >> 0xf <
                     (int)((uVar3 ^ uVar6) - uVar6) / 0x28f);
        return 1;
      }
      FUN_005a89c0(param_1 + 0x170,0x5a);
      if (*(int *)(param_1 + 0x14c) == 0x168) {
        FUN_00594470(0x11,param_1,0);
        return 1;
      }
    }
    else {
      if (iVar4 != 2) {
        iVar4 = *(int *)(*(int *)(param_1 + 400) + 0x50);
        if (((iVar4 == 0) || (*(int *)(param_1 + 0x2b8) != *(int *)(iVar4 + 0x2b8))) &&
           (iVar4 = *(int *)(*(int *)(param_1 + 0x184) + 0x308), iVar5 = FUN_005ec250(),
           (int)(iVar5 * 1000 + (iVar5 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar4 * 10)) {
          *(undefined4 *)(param_1 + 0x140) = 2;
          iVar4 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
          if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1))
          {
            iVar4 = -iVar4;
          }
          FUN_00590aa0(iVar4,0,0);
          FUN_005a89c0(&iStack_c,0x5a);
          return 1;
        }
        cVar2 = FUN_005b3c10(900,600,300);
        if (cVar2 != '\0') {
          FUN_005b4820();
          return 1;
        }
        cVar2 = FUN_005b3c10(0x14,0x118,700);
        if (((cVar2 != '\0') && (iVar4 = FUN_005b31a0(0,1), iVar4 != 0)) &&
           (((100 - *(int *)(*(int *)(param_1 + 0x184) + 0x304)) * 0xc0000) / 100 <
            *(int *)(param_1 + 0xe4 + (*(int *)(iVar4 + 0x2b8) * 0xb + *(int *)(iVar4 + 0x2c4)) * 4)
           )) {
          FUN_005b3a10(iVar4,0,0);
          return 1;
        }
        iVar4 = *(int *)(*(int *)(param_1 + 0x184) + 0x304);
        iVar5 = FUN_005ec250();
        if ((((int)(iVar5 * 1000 + (iVar5 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar4 * 10) &&
            (iVar4 = FUN_005b31a0(2,1), iVar4 != 0)) &&
           (0x60000 < *(int *)(param_1 + 0xe4 +
                              (*(int *)(iVar4 + 0x2b8) * 0xb + *(int *)(iVar4 + 0x2c4)) * 4))) {
          FUN_005b3a10(iVar4,0,1);
          return 1;
        }
        iVar4 = FUN_005b31a0(1,1);
        if (iVar4 == 0) {
          FUN_005b4820();
          return 1;
        }
        FUN_005b3a10(iVar4,0,1);
        return 1;
      }
      iVar4 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
      if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1)) {
        iVar4 = -iVar4;
      }
      FUN_00590aa0(iVar4,0,0);
      FUN_005a89c0(&iStack_c,0x5a);
      iVar4 = FUN_005b35c0();
      if ((iVar4 != 0) || (iVar4 = FUN_005b31a0(2,0), iVar4 != 0)) {
        FUN_005b3a10(iVar4,0xa0000 < *(int *)(param_1 + 0xe4 +
                                             (*(int *)(iVar4 + 0x2b8) * 0xb +
                                             *(int *)(iVar4 + 0x2c4)) * 4),1);
        return 1;
      }
      if ((*(int *)(param_1 + 4) < *(int *)(param_1 + 0x210)) ||
         ((((*(int *)(param_1 + 0x21c) < *(int *)(param_1 + 4) ||
            (*(int *)(param_1 + 8) < *(int *)(param_1 + 0x214))) ||
           (*(int *)(param_1 + 0x220) < *(int *)(param_1 + 8))) ||
          ((*(int *)(param_1 + 0xc) < *(int *)(param_1 + 0x218) ||
           (*(int *)(param_1 + 0x224) < *(int *)(param_1 + 0xc))))))) {
        bVar1 = false;
      }
      else {
        bVar1 = true;
      }
      if (!bVar1) {
        iVar4 = FUN_005ec250();
        if ((int)(iVar4 * 1000 + (iVar4 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < 500) {
          FUN_005aa4d0();
          return 1;
        }
      }
    }
  }
  else {
    if (iVar4 == 3) {
      if (*(int *)(*(int *)(param_1 + 0x184) + 0x30c) != 1) {
        FUN_005a89c0(param_1 + 0x1ec,0x5a);
        return 1;
      }
      FUN_005a89c0(param_1 + 0x1ec,0x28);
      return 1;
    }
    if (iVar4 == 4) {
      iVar4 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
      if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1)) {
        iVar4 = -iVar4;
      }
      uVar3 = *(uint *)(param_1 + 0x218);
      uStack_4 = *(uint *)(param_1 + 0x224);
      iVar5 = *(int *)(param_1 + 0x1f0);
      if ((int)(((int)uVar3 < 1) - 1 & uVar3) <= (int)uStack_4) {
        uStack_4 = ((int)uVar3 < 1) - 1 & uVar3;
      }
      iVar8 = *(int *)(param_1 + 0x214);
      iVar7 = iVar8;
      if (iVar8 <= iVar5) {
        iVar7 = iVar5;
      }
      iStack_8 = *(int *)(param_1 + 0x220);
      if ((iVar7 <= iStack_8) && (iStack_8 = iVar5, iVar5 < iVar8)) {
        iStack_8 = iVar8;
      }
      iVar5 = *(int *)(param_1 + 0x210);
      iVar8 = iVar5;
      if (iVar5 <= iVar4) {
        iVar8 = iVar4;
      }
      iStack_c = *(int *)(param_1 + 0x21c);
      if ((iVar8 <= iStack_c) && (iStack_c = iVar5, iVar5 <= iVar4)) {
        iStack_c = iVar4;
      }
      FUN_005a89c0(&iStack_c,0x5a);
      return 1;
    }
    cVar2 = FUN_005b3c60();
    if (cVar2 != '\0') {
      iVar4 = *(int *)(*(int *)(param_1 + 0x184) + 0x30c);
      iVar5 = FUN_005ec250();
      *(uint *)(param_1 + 0x140) =
           4 - (uint)((int)(iVar5 * 1000 + (iVar5 * 1000 >> 0x1f & 0x7fffU)) >> 0xf <
                     (int)((-(uint)(iVar4 != 1) & 0xfffffed4) + 800));
      return 1;
    }
    FUN_005a89c0(param_1 + 0x1ec,0x28);
  }
  return 1;
}


