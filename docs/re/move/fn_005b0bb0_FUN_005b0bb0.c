// FUN_005b0bb0  entry=005b0bb0  size=723 bytes

bool __thiscall FUN_005b0bb0(int param_1,int *param_2,undefined4 param_3,int param_4,int param_5)

{
  bool bVar1;
  short sVar2;
  int iVar3;
  uint uVar4;
  undefined4 *puVar5;
  int *piVar6;
  uint uVar7;
  int iVar8;
  uint uVar9;
  bool bVar10;
  int local_24;
  int local_20;
  int local_1c;
  undefined1 local_c [12];
  
  bVar10 = false;
  iVar3 = FUN_005b0b40(0);
  if (iVar3 < 2) {
    if (param_1 == 0) {
      iVar3 = 0xc80000;
    }
    else {
      uVar4 = *(int *)(param_1 + 4) + *(int *)(param_1 + 0x3a4);
      uVar7 = (int)uVar4 >> 0x1f;
      iVar3 = (uVar4 ^ uVar7) - uVar7;
    }
    if (iVar3 < param_5) {
      bVar10 = *(int *)(*(int *)(param_1 + 400) + 0x4c) == param_1;
      if (!bVar10) {
        if (0x776 < *(int *)(param_1 + 0x68)) {
          iVar3 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820);
          if (1U - *(int *)(param_1 + 0x2b8) == (*(uint *)(*(int *)(param_1 + 0x18c) + 0x19a0) & 1))
          {
            iVar3 = -iVar3;
          }
          FUN_00590aa0(iVar3,0,0);
          puVar5 = (undefined4 *)FUN_00590ae0(&local_24,param_1 + 4);
          sVar2 = FUN_005ee080(*puVar5,puVar5[1]);
          uVar4 = (uint)(short)(sVar2 - *(short *)(param_1 + 0x34));
          uVar7 = (int)uVar4 >> 0x1f;
          if (0x4e39 < (int)((uVar4 ^ uVar7) - uVar7)) goto LAB_005b0de8;
        }
        FUN_005ee0f0(0x10000,param_3);
        piVar6 = (int *)FUN_005ee0f0(param_4 / 2,param_3);
        uVar4 = (*(int *)(param_1 + 4) - *piVar6) - *param_2;
        uVar9 = (-(uint)(*(int *)(*(int *)(param_1 + 400) + 0x4c) != 0) & 0x20000) + 0x30000;
        uVar7 = (int)uVar4 >> 0x1f;
        iVar3 = param_4 / 2 + uVar9;
        if ((((int)((uVar4 ^ uVar7) - uVar7) < iVar3) &&
            (uVar4 = *(int *)(param_1 + 8) - (piVar6[1] + param_2[1]), uVar7 = (int)uVar4 >> 0x1f,
            (int)((uVar4 ^ uVar7) - uVar7) < iVar3)) &&
           (uVar4 = *(int *)(param_1 + 0xc) - (piVar6[2] + param_2[2]), uVar7 = (int)uVar4 >> 0x1f,
           (int)((uVar4 ^ uVar7) - uVar7) < iVar3)) {
          bVar1 = true;
        }
        else {
          bVar1 = false;
        }
        if (bVar1) {
          local_24 = *(int *)(param_1 + 4) - *param_2;
          local_1c = *(int *)(param_1 + 0xc) - param_2[2];
          local_20 = *(int *)(param_1 + 8) - param_2[1];
          iVar3 = FUN_005ee500(&local_24);
          iVar8 = (int)((ulonglong)((longlong)(int)uVar9 * 0x55555555) >> 0x20) - uVar9;
          if (((iVar8 >> 1) - (iVar8 >> 0x1f) <= iVar3) && (iVar3 <= (int)(uVar9 / 3 + param_4))) {
            FUN_005ee540(local_c,&local_24);
            iVar3 = ftol();
            bVar10 = iVar3 <= (int)uVar9;
          }
        }
      }
    }
  }
LAB_005b0de8:
  if (bVar10 != false) {
    *(int *)(*(int *)(param_1 + 0x18c) + 0x43c) = param_1;
    uVar4 = *(int *)(param_1 + 4) - *param_2;
    uVar7 = (int)uVar4 >> 0x1f;
    iVar3 = (uVar4 ^ uVar7) - uVar7;
    if (0x1e0000 < iVar3) {
      *(undefined1 *)(*(int *)(param_1 + 0x18c) + 0x460) = 0x5a;
      return bVar10;
    }
    if (0x140000 < iVar3) {
      *(undefined1 *)(*(int *)(param_1 + 0x18c) + 0x460) = 0x3c;
      return bVar10;
    }
    if (0xa0000 < iVar3) {
      *(undefined1 *)(*(int *)(param_1 + 0x18c) + 0x460) = 0x1e;
      return bVar10;
    }
    *(undefined1 *)(*(int *)(param_1 + 0x18c) + 0x460) = 0xf;
  }
  return bVar10;
}


