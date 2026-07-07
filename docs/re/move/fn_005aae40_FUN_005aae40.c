// FUN_005aae40  entry=005aae40  size=389 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_005aae40(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int *piVar5;
  int iVar6;
  uint uVar7;
  int iVar8;
  uint uVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  int local_1c;
  
  local_1c = 0;
  *(undefined4 *)(param_1 + 0x48) = 0;
  piVar5 = (int *)FUN_005ee0f0(0x8000,*(undefined2 *)(param_1 + 0x34));
  iVar1 = *(int *)(param_1 + 4);
  iVar2 = *piVar5;
  iVar3 = piVar5[1];
  iVar4 = *(int *)(param_1 + 8);
  iVar10 = 0x1f40000;
  iVar11 = (*(int **)(param_1 + 0x184))[1];
  iVar8 = **(int **)(param_1 + 0x184);
  while (iVar11 != 0) {
    iVar11 = iVar11 + -1;
    if ((iVar8 != param_1) && (*(int *)(iVar8 + 700) != 0)) {
      iVar6 = *(int *)(iVar8 + 0x2b8) * 0xb + *(int *)(iVar8 + 0x2c4);
      if (iVar8 == 0) {
        iVar12 = 0xc80000;
      }
      else {
        iVar12 = *(int *)(param_1 + 0xe4 + iVar6 * 4);
      }
      uVar7 = (uint)*(short *)(param_1 + 0xb8 + iVar6 * 2);
      uVar9 = (int)uVar7 >> 0x1f;
      if (((int)((uVar7 ^ uVar9) - uVar9) < 0x1555) && (iVar12 < iVar10)) {
        iVar10 = iVar12;
        local_1c = iVar8;
      }
    }
    iVar8 = iVar8 + 0x3bc;
  }
  if ((local_1c == 0) || (0x45ffff < iVar10)) {
    piVar5 = (int *)FUN_005ee0f0(0x120000,CONCAT22((short)((uint)iVar8 >> 0x10),
                                                   *(undefined2 *)(param_1 + 0x34)));
    iVar11 = piVar5[1];
    iVar8 = piVar5[2];
    *(int *)(param_1 + 0xa0) = *(int *)(param_1 + 4) + *piVar5;
    *(int *)(param_1 + 0xa4) = iVar11 + *(int *)(param_1 + 8);
    *(int *)(param_1 + 0xa8) = iVar8 + *(int *)(param_1 + 0xc);
  }
  else {
    *(int *)(*(int *)(param_1 + 400) + 0x4c) = local_1c;
    *(undefined4 *)(param_1 + 0xa0) = *(undefined4 *)(local_1c + 4);
    *(undefined4 *)(param_1 + 0xa4) = *(undefined4 *)(local_1c + 8);
    *(undefined4 *)(param_1 + 0xa8) = *(undefined4 *)(local_1c + 0xc);
  }
  *(undefined4 *)(param_1 + 0xb4) = 0;
  FUN_005a5430(0x37);
  iVar11 = *(int *)(param_1 + 400);
  *(undefined4 *)(iVar11 + 0x68) = 1;
  *(undefined4 *)(iVar11 + 0x6c) = 0x14;
  *(int *)(iVar11 + 0x9c) = iVar1 + iVar2;
  *(int *)(iVar11 + 0xa0) = iVar3 + iVar4;
  *(undefined4 *)(iVar11 + 0xa4) = 0x9999;
  *(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x19dc) = 10000;
  return;
}


