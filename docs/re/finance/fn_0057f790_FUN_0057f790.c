// FUN_0057f790  entry=0057f790  size=1356 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

float10 __fastcall FUN_0057f790(int param_1)

{
  undefined4 uVar1;
  int *piVar2;
  int *piVar3;
  int *piVar4;
  int *piVar5;
  int iVar6;
  uint uVar7;
  uint uVar8;
  int iVar9;
  uint uVar10;
  float10 fVar11;
  float fVar12;
  
  piVar5 = DAT_0066b19c;
  piVar4 = DAT_0066b198;
  piVar3 = DAT_0066b194;
  piVar2 = DAT_0066b190;
  iVar9 = *(int *)(param_1 + 0x50);
  if (iVar9 == 0) {
    uVar1 = *(undefined4 *)(param_1 + 0x10);
    iVar9 = *DAT_0066b190;
    iVar6 = (**(code **)(iVar9 + 0x148))();
    (**(code **)(iVar9 + 0x188))(uVar1,iVar6 + -1);
    uVar10 = *(uint *)(param_1 + 0x10);
    uVar7 = (**(code **)(*piVar2 + 0xa8))();
    if ((uVar7 & 0xffff) != uVar10) {
      uVar10 = 0;
      do {
        uVar7 = *(uint *)(param_1 + 0x10);
        uVar8 = FUN_0041c260(uVar10);
        if ((uVar8 & 0xffff) == uVar7) break;
        uVar10 = uVar10 + 1;
      } while (uVar10 < 4);
    }
  }
  else if (iVar9 == 1) {
    uVar1 = *(undefined4 *)(param_1 + 0x10);
    iVar9 = *DAT_0066b194;
    iVar6 = (**(code **)(iVar9 + 0x148))();
    (**(code **)(iVar9 + 0x188))(uVar1,iVar6 + -1);
    (**(code **)(*piVar3 + 0xa8))();
  }
  else if (iVar9 == 2) {
    uVar1 = *(undefined4 *)(param_1 + 0x10);
    iVar9 = *DAT_0066b198;
    iVar6 = (**(code **)(iVar9 + 0x148))();
    (**(code **)(iVar9 + 0x188))(uVar1,iVar6 + -1);
    (**(code **)(*piVar4 + 0xa8))();
  }
  else if (iVar9 == 3) {
    uVar1 = *(undefined4 *)(param_1 + 0x10);
    iVar9 = *DAT_0066b19c;
    iVar6 = (**(code **)(iVar9 + 0x148))();
    (**(code **)(iVar9 + 0x188))(uVar1,iVar6 + -1);
    (**(code **)(*piVar5 + 0xa8))();
  }
  fVar12 = *(float *)(param_1 + 0x10);
  iVar9 = (**(code **)(*DAT_0066b1a0 + 0x48))();
  piVar2 = DAT_0066b1a0;
  if (iVar9 != 0) {
    uVar10 = *(uint *)(param_1 + 0x10);
    uVar7 = (**(code **)(*DAT_0066b1a0 + 0xa8))();
    if ((uVar7 & 0xffff) != uVar10) {
      (**(code **)(*piVar2 + 0xac))();
    }
    FUN_004070c0(*(undefined4 *)(param_1 + 0x10));
  }
  iVar9 = (**(code **)(*DAT_0066b1a4 + 0x48))(*(undefined4 *)(param_1 + 0x10));
  piVar2 = DAT_0066b1a4;
  if (iVar9 != 0) {
    uVar10 = *(uint *)(param_1 + 0x10);
    uVar7 = (**(code **)(*DAT_0066b1a4 + 0xa8))();
    if ((uVar7 & 0xffff) != uVar10) {
      (**(code **)(*piVar2 + 0xac))();
    }
    FUN_00401f40(*(undefined4 *)(param_1 + 0x10));
  }
  iVar9 = (**(code **)(*DAT_0066b1ac + 0x48))(*(undefined4 *)(param_1 + 0x10));
  if (iVar9 != 0) {
    (**(code **)(*DAT_0066b1ac + 0xa8))();
    FUN_00457540(*(undefined4 *)(param_1 + 0x10));
  }
  iVar9 = (**(code **)(*DAT_0066b1b0 + 0x48))(*(undefined4 *)(param_1 + 0x10));
  if (iVar9 != 0) {
    (**(code **)(*DAT_0066b1b0 + 0xa8))();
    FUN_0045d9f0(*(undefined4 *)(param_1 + 0x10));
  }
  iVar9 = (**(code **)(*DAT_0066b1b4 + 0x48))(*(undefined4 *)(param_1 + 0x10));
  if (iVar9 != 0) {
    uVar10 = *(uint *)(param_1 + 0x10);
    uVar7 = (**(code **)(*DAT_0066b1b4 + 0xa8))();
    if ((uVar7 & 0xffff) == uVar10) {
      fVar12 = fVar12 - _DAT_00638e18;
    }
    iVar9 = FUN_00451500(*(undefined4 *)(param_1 + 0x10));
    fVar12 = (float)(iVar9 * 4000000) + fVar12;
  }
  uVar10 = *(uint *)(param_1 + 0x10);
  uVar7 = (**(code **)(*DAT_0066b1b8 + 0xa8))();
  if ((uVar7 & 0xffff) == uVar10) {
    fVar12 = fVar12 - _DAT_00638e18;
  }
  uVar10 = *(uint *)(param_1 + 0x10);
  uVar7 = (**(code **)(*DAT_0066b1bc + 0xa8))();
  fVar11 = (float10)fVar12;
  if ((uVar7 & 0xffff) == uVar10) {
    fVar11 = fVar11 - (float10)_DAT_00638e18;
  }
  return fVar11;
}


