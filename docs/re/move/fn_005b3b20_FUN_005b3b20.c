// FUN_005b3b20  entry=005b3b20  size=235 bytes

void __thiscall FUN_005b3b20(int param_1,undefined4 *param_2)

{
  bool bVar1;
  uint uVar2;
  int *piVar3;
  uint uVar4;
  int iVar5;
  int iVar6;
  int local_c;
  undefined4 local_8;
  undefined4 local_4;
  
  piVar3 = &local_c;
  bVar1 = false;
  iVar5 = *(int *)(*(int *)(param_1 + 0x184) + 0x318);
  if (iVar5 == 0) {
    uVar2 = *(int *)(*(int *)(param_1 + 400) + 4) - *(int *)(param_1 + 0x3a4);
    uVar4 = (int)uVar2 >> 0x1f;
    iVar6 = (uVar2 ^ uVar4) - uVar4;
    iVar5 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820) << 1;
  }
  else {
    if (iVar5 != 1) {
      if (iVar5 == 2) {
        bVar1 = true;
      }
      goto LAB_005b3ba5;
    }
    uVar2 = *(int *)(*(int *)(param_1 + 400) + 4) - *(int *)(param_1 + 0x3a4);
    uVar4 = (int)uVar2 >> 0x1f;
    iVar6 = (uVar2 ^ uVar4) - uVar4;
    iVar5 = *(int *)(*(int *)(param_1 + 0x18c) + 0x1820) << 2;
  }
  bVar1 = iVar6 < iVar5 / 3;
LAB_005b3ba5:
  if (bVar1) {
    local_c = *(int *)(param_1 + 0x1e0) -
              (*(int *)(param_1 + 0x3a4) + *(int *)(param_1 + 0x1e0)) / 0x21;
    local_8 = *(undefined4 *)(param_1 + 0x1e4);
    local_4 = *(undefined4 *)(param_1 + 0x1e8);
  }
  else {
    piVar3 = (int *)(param_1 + 0x1e0);
  }
  *param_2 = *piVar3;
  param_2[1] = piVar3[1];
  param_2[2] = piVar3[2];
  return;
}


