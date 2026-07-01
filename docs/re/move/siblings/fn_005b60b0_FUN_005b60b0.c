// FUN_005b60b0  entry=005b60b0  size=507 bytes

void __fastcall FUN_005b60b0(int param_1)

{
  byte bVar1;
  undefined2 uVar2;
  short sVar3;
  int iVar4;
  int *piVar5;
  int iVar6;
  int iVar7;
  undefined4 uVar8;
  
  iVar6 = *(int *)(*(int *)(param_1 + 0x18c) + 0x43c);
  iVar7 = *(int *)(iVar6 + 4) - *(int *)(param_1 + 4);
  iVar6 = *(int *)(iVar6 + 8) - *(int *)(param_1 + 8);
  uVar2 = FUN_005ee080(iVar7,iVar6);
  *(undefined2 *)(param_1 + 0x34) = uVar2;
  if (*(int *)(param_1 + 0x3cc) < 0x33) {
    FUN_005a5430(0x41);
    *(int *)(param_1 + 0x3cc) = *(int *)(param_1 + 0x3cc) + 1;
  }
  iVar4 = *(int *)(param_1 + 0x18c);
  if ((*(byte *)(iVar4 + 0x461) & 6) != 0) {
    switch(*(undefined4 *)(param_1 + 0x3cc)) {
    case 1:
      *(undefined1 *)(param_1 + 0x3d0) = 1;
      break;
    case 0x33:
      FUN_005a5430(0x3b);
      *(int *)(param_1 + 0x3cc) = *(int *)(param_1 + 0x3cc) + 1;
      break;
    case 0x34:
      sVar3 = FUN_005ee080(iVar7,iVar6);
      iVar4 = FUN_005edfb0(iVar7,*(undefined4 *)(&DAT_006d31c8 + (sVar3 + 8 >> 4 & 0xfffU) * 4),
                           iVar6,*(undefined4 *)(&DAT_006d31c8 + (0x3ff8 - sVar3 >> 4 & 0xfffU) * 4)
                          );
      if (0x50000 < iVar4) {
        *(int *)(param_1 + 0x3bc) = *(int *)(param_1 + 0x3bc) + 0x147;
      }
      iVar4 = *(int *)(param_1 + 0x3bc);
      if (0x1bba < iVar4) {
        iVar4 = 0x1bbb;
      }
      *(int *)(param_1 + 0x3bc) = iVar4 + -0xa3;
      if (iVar4 + -0xa3 < 0) {
        *(undefined4 *)(param_1 + 0x3bc) = 0;
        if ((*(byte *)(*(int *)(param_1 + 0x18c) + 0x461) & 2) == 0) {
          uVar8 = 0x3d;
        }
        else {
          uVar8 = 0x3c;
        }
        FUN_005a5430(uVar8);
        *(int *)(param_1 + 0x3cc) = *(int *)(param_1 + 0x3cc) + 1;
      }
      uVar8 = FUN_005ee080(iVar7,iVar6);
      piVar5 = (int *)FUN_005ee0f0(*(undefined4 *)(param_1 + 0x3bc),uVar8);
      *(int *)(param_1 + 4) = *(int *)(param_1 + 4) + *piVar5;
      *(int *)(param_1 + 8) = *(int *)(param_1 + 8) + piVar5[1];
      *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + piVar5[2];
      FUN_005a50c0();
      break;
    case 0x99:
      if (*(int *)(param_1 + 0x40) == 0x3c) {
        bVar1 = *(byte *)(iVar4 + 0x461) & 0xfd;
      }
      else {
        bVar1 = *(byte *)(iVar4 + 0x461) & 0xfb;
      }
      *(byte *)(iVar4 + 0x461) = bVar1;
      FUN_005a5430(0x38);
      *(bool *)(param_1 + 0x3d0) = (*(byte *)(*(int *)(param_1 + 0x18c) + 0x461) & 7) != 0;
      *(undefined4 *)(param_1 + 0x3cc) = 0;
    }
    if (0x34 < *(int *)(param_1 + 0x3cc)) {
      *(int *)(param_1 + 0x3cc) = *(int *)(param_1 + 0x3cc) + 1;
      FUN_005a50c0();
      if (*(int *)(param_1 + 0x2c) == 5) {
        *(undefined4 *)(param_1 + 0x30) = 0;
      }
    }
  }
  return;
}


