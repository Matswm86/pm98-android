// thunk_FUN_005b5520  entry=005b5780  size=5 bytes

undefined4 __fastcall thunk_FUN_005b5520(int param_1)

{
  char cVar1;
  short sVar2;
  int iVar3;
  undefined4 *puVar4;
  uint uVar5;
  int iVar6;
  int *piVar7;
  undefined4 uVar8;
  uint uVar9;
  int iStack_24;
  int iStack_20;
  int iStack_1c;
  undefined1 auStack_18 [12];
  undefined1 auStack_c [12];
  
  iVar3 = *(int *)(param_1 + 400);
  if (param_1 == *(int *)(iVar3 + 0x40)) {
    iVar3 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
    if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
      iVar3 = -iVar3;
    }
    FUN_00590aa0(iVar3,0,0);
    FUN_005a89c0(&iStack_24,0x5a);
    iVar3 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
    if ((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) == 1U - *(int *)(param_1 + 0x2b8)) {
      iVar3 = -iVar3;
    }
    FUN_00590aa0(iVar3,0,0);
    puVar4 = (undefined4 *)FUN_00590ae0(auStack_18,param_1 + 4);
    sVar2 = FUN_005ee080(*puVar4,puVar4[1]);
    uVar5 = (uint)(short)(sVar2 - *(short *)(param_1 + 0x34));
    uVar9 = (int)uVar5 >> 0x1f;
    if ((int)((uVar5 ^ uVar9) - uVar9) < 0x1c72) {
      cVar1 = FUN_005b3c10(0x14,0x118,700);
      if (cVar1 != '\0') {
        iVar3 = FUN_005b31a0(0,1);
        if (iVar3 != 0) {
          FUN_005b3a10(iVar3,0,0);
          return 1;
        }
      }
      iVar3 = *(int *)(*(int *)(param_1 + 0x184) + 0x304);
      iVar6 = FUN_005ec250();
      if ((int)(iVar6 * 1000 + (iVar6 * 1000 >> 0x1f & 0x7fffU)) >> 0xf < iVar3 * 10) {
        iVar3 = FUN_005b31a0(2,1);
        if ((iVar3 != 0) &&
           (0x60000 < *(int *)(param_1 + 0xe4 +
                              (*(int *)(iVar3 + 0x2b8) * 0xb + *(int *)(iVar3 + 0x2c4)) * 4))) {
          FUN_005b3a10(iVar3,0,1);
          return 1;
        }
      }
      iVar3 = FUN_005b31a0(1,0);
      if (iVar3 != 0) {
        FUN_005b3a10(iVar3,0,1);
        return 1;
      }
    }
  }
  else {
    piVar7 = (int *)FUN_005b3b20(auStack_18);
    iStack_24 = ((*(int *)(param_1 + 0x1ec) + *piVar7) / 2 + *(int *)(iVar3 + 4)) / 2;
    iStack_1c = ((piVar7[2] + *(int *)(param_1 + 500)) / 2 + *(int *)(iVar3 + 0xc)) / 2;
    iStack_20 = ((piVar7[1] + *(int *)(param_1 + 0x1f0)) / 2 + *(int *)(iVar3 + 8)) / 2;
    uVar8 = FUN_005b1330(auStack_c,param_1 + 0x210);
    FUN_005a89c0(uVar8,0x28);
  }
  return 1;
}


