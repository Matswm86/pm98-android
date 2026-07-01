// FUN_005b5dd0  entry=005b5dd0  size=470 bytes

void __fastcall FUN_005b5dd0(int param_1)

{
  int iVar1;
  int iVar2;
  bool bVar3;
  undefined2 uVar4;
  short sVar5;
  int iVar6;
  int *piVar7;
  int iVar8;
  int iVar9;
  
  if (*(int *)(param_1 + 0x3cc) < 0x33) {
    FUN_005a5430(0x41);
    *(int *)(param_1 + 0x3cc) = *(int *)(param_1 + 0x3cc) + 1;
  }
  switch(*(undefined4 *)(param_1 + 0x3cc)) {
  case 1:
    *(undefined1 *)(param_1 + 0x3d0) = 1;
    break;
  case 0x33:
    FUN_005a5430(0x3b);
    *(int *)(param_1 + 0x3cc) = *(int *)(param_1 + 0x3cc) + 1;
    break;
  case 0x34:
    iVar1 = *(int *)(param_1 + 0x18c);
    iVar2 = *(int *)(param_1 + 0xc);
    iVar8 = *(int *)(iVar1 + 0x16a4) - *(int *)(param_1 + 8);
    iVar9 = *(int *)(iVar1 + 0x16a0) - *(int *)(param_1 + 4);
    iVar1 = *(int *)(iVar1 + 0x16a8);
    uVar4 = FUN_005ee080(iVar9,iVar8);
    *(undefined2 *)(param_1 + 0x34) = uVar4;
    sVar5 = FUN_005ee080(iVar9,iVar8);
    iVar6 = FUN_005edfb0(iVar9,*(undefined4 *)(&DAT_006d31c8 + (sVar5 + 8 >> 4 & 0xfffU) * 4),iVar8,
                         *(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar5 >> 4 & 0xfffU) * 4));
    if (0x30000 < iVar6) {
      *(int *)(param_1 + 0x3bc) = *(int *)(param_1 + 0x3bc) + 0x147;
    }
    iVar6 = *(int *)(param_1 + 0x3bc);
    if (0x1bba < iVar6) {
      iVar6 = 0x1bbb;
    }
    *(int *)(param_1 + 0x3bc) = iVar6 + -0xa3;
    if (iVar6 + -0xa3 < 0) {
      *(undefined4 *)(param_1 + 0x3bc) = 0;
      FUN_005a5430(0x3e);
      *(int *)(param_1 + 0x3cc) = *(int *)(param_1 + 0x3cc) + 1;
    }
    if (((iVar9 == 0) && (iVar8 == 0)) && (iVar1 == iVar2)) {
      bVar3 = true;
    }
    else {
      bVar3 = false;
    }
    if (!bVar3) {
      piVar7 = (int *)FUN_005ee0f0(*(undefined4 *)(param_1 + 0x3bc),*(undefined2 *)(param_1 + 0x34))
      ;
      *(int *)(param_1 + 4) = *(int *)(param_1 + 4) + *piVar7;
      *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + piVar7[1];
      *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + piVar7[2];
    }
    FUN_005a50c0();
    break;
  case 0x99:
    FUN_005a5430(0x38);
    *(undefined1 *)(param_1 + 0x3d0) = 0;
  }
  if (0x34 < *(int *)(param_1 + 0x3cc)) {
    *(ushort *)(param_1 + 0x34) =
         (-(ushort)((*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1) !=
                   *(uint *)(*(int *)(*(int *)(param_1 + 0x18c) + 0x43c) + 0x2b8)) & 0x8000) +
         0x8000;
    *(int *)(param_1 + 0x3cc) = *(int *)(param_1 + 0x3cc) + 1;
    FUN_005a50c0();
  }
  return;
}


